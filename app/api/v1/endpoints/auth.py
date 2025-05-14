from datetime import timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app import schemas
from app.api.v1 import deps
from app.core import security
from app.core.config import settings
from app.models.user import User
from app.utils.password import get_password_hash, verify_password
from app.utils.email import send_reset_password_email
from pydantic import BaseModel, EmailStr
import secrets

router = APIRouter()

# Password reset token storage (In production, use Redis or similar)
password_reset_tokens = {}

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    token: str
    new_password: str

@router.post("/register", response_model=schemas.User)
def register_user(
    user_in: schemas.UserCreate,
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Register a new user.
    """
    # Check if user with this email exists
    user = db.query(User).filter(User.email == user_in.email).first()
    if user:
        raise HTTPException(
            status_code=400,
            detail="User with this email already exists.",
        )
    
    # Create new user
    user_data = user_in.dict(exclude={"password"})
    user_data["hashed_password"] = get_password_hash(user_in.password)
    
    db_user = User(**user_data)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return db_user


@router.post("/login/access-token", response_model=schemas.Token)
def login_access_token(
    db: Session = Depends(deps.get_db),
    form_data: OAuth2PasswordRequestForm = Depends(),
) -> Any:
    """
    OAuth2 compatible token login, get an access token for future requests.
    """
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password",
        )
    elif not user.is_active:
        raise HTTPException(
            status_code=400,
            detail="Inactive user",
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return {
        "access_token": security.create_access_token(
            user.id, expires_delta=access_token_expires
        ),
        "token_type": "bearer",
    }

@router.post("/password-reset/request")
async def request_password_reset(
    reset_request: PasswordResetRequest,
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Password reset step 1: Request a password reset
    """
    user = db.query(User).filter(User.email == reset_request.email).first()
    if not user:
        raise HTTPException(
            status_code=404,
            detail="Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı",
        )
    
    # Generate a secure token
    reset_token = secrets.token_urlsafe(32)
    
    # Store the token with the user ID (In production, use Redis with expiration)
    password_reset_tokens[reset_token] = {
        "user_id": user.id,
        "email": user.email,
    }
    
    # Generate the reset link with custom URL scheme for development
    reset_link = f"payviya://reset-password?token={reset_token}"
    
    # Send the reset email
    try:
        await send_reset_password_email(
            email_to=user.email,
            reset_link=reset_link,
            user_name=user.name,
        )
    except Exception as e:
        print(f"Error sending reset email: {e}")
        raise HTTPException(
            status_code=500,
            detail="E-posta gönderilemedi. Lütfen daha sonra tekrar deneyin.",
        )
    
    return {"message": "Şifre yenileme bağlantısı e-posta adresinize gönderildi"}

@router.post("/password-reset/confirm")
async def confirm_password_reset(
    reset_confirm: PasswordResetConfirm,
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Password reset step 2: Confirm and set new password
    """
    # Check if token exists
    token_data = password_reset_tokens.get(reset_confirm.token)
    if not token_data:
        raise HTTPException(
            status_code=400,
            detail="Geçersiz veya süresi dolmuş token",
        )
    
    # Get user
    user = db.query(User).filter(User.id == token_data["user_id"]).first()
    if not user:
        raise HTTPException(
            status_code=404,
            detail="Kullanıcı bulunamadı",
        )
    
    # Update password
    user.hashed_password = get_password_hash(reset_confirm.new_password)
    db.commit()
    
    # Remove used token
    password_reset_tokens.pop(reset_confirm.token)
    
    return {"message": "Şifreniz başarıyla güncellendi"} 