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
from app.utils.password import get_password_hash, verify_password, validate_password
from app.utils.email import send_reset_password_email
from pydantic import BaseModel, EmailStr
import secrets
from datetime import datetime
from app.models.verification import VerificationCode
import random
import string

router = APIRouter()

# Password reset token storage (In production, use Redis or similar)
password_reset_tokens = {}

class PasswordResetRequest(BaseModel):
    email: EmailStr

class VerifyCodeRequest(BaseModel):
    email: EmailStr
    code: str

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    new_password: str
    temp_token: str

def generate_verification_code() -> str:
    """Generate a 6-digit numeric verification code"""
    return ''.join(random.choices(string.digits, k=6))

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
    
    # Validate password
    is_valid, error_message = validate_password(user_in.password)
    if not is_valid:
        raise HTTPException(
            status_code=400,
            detail=error_message
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
    The password should be pre-hashed by the client using SHA-256 with salt.
    """
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user:
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password",
        )
    
    # Verify the password using client-side hashing
    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password",
        )
    
    if not user.is_active:
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

@router.post("/forgot-password/request")
async def request_password_reset(
    request: PasswordResetRequest,
    db: Session = Depends(deps.get_db)
) -> dict:
    """
    Request a password reset by sending a verification code to the user's email
    """
    # Check if user exists
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        raise HTTPException(
            status_code=404,
            detail="User with this email does not exist"
        )

    # Generate verification code
    code = generate_verification_code()
    expires_at = datetime.now() + timedelta(minutes=15)  # Code expires in 15 minutes

    # Save verification code to database
    verification = VerificationCode(
        email=request.email,
        code=code,
        purpose="password_reset",
        expires_at=expires_at
    )
    db.add(verification)
    db.commit()

    # Send verification code via email
    try:
        await send_reset_password_email(
            email_to=request.email,
            verification_code=code,
            user_name=user.name
        )
    except Exception as e:
        print(f"Error sending verification code email: {e}")
        raise HTTPException(
            status_code=500,
            detail="Failed to send verification code. Please try again later."
        )

    return {
        "message": "Verification code sent to email",
        "expires_in": "15 minutes"
    }

@router.post("/forgot-password/verify")
async def verify_reset_code(
    request: VerifyCodeRequest,
    db: Session = Depends(deps.get_db)
) -> dict:
    """
    Verify the password reset code
    """
    # Get the latest unused verification code for this email
    verification = db.query(VerificationCode).filter(
        VerificationCode.email == request.email,
        VerificationCode.code == request.code,
        VerificationCode.purpose == "password_reset",
        VerificationCode.is_used == False,
        VerificationCode.expires_at > datetime.now()
    ).order_by(VerificationCode.created_at.desc()).first()

    if not verification:
        raise HTTPException(
            status_code=400,
            detail="Invalid or expired verification code"
        )

    # Mark code as used
    verification.is_used = True
    verification.used_at = datetime.now()
    db.commit()

    # Generate a temporary token for password reset
    temp_token = security.create_access_token(
        subject=str(verification.email),
        expires_delta=timedelta(minutes=15)
    )

    return {
        "message": "Verification successful",
        "temp_token": temp_token
    }

@router.post("/reset-password")
async def reset_password(
    request: ResetPasswordRequest,
    db: Session = Depends(deps.get_db)
) -> dict:
    """
    Reset the password using the temporary token.
    The new_password should be pre-hashed by the client.
    """
    # Verify temp token
    try:
        payload = security.verify_token(request.temp_token)
        token_email = payload.get("sub")
        if token_email != request.email:
            raise HTTPException(
                status_code=400,
                detail="Invalid token for this email"
            )
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Invalid or expired token"
        )

    # Update user's password with the pre-hashed password
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    # Hash the pre-hashed password from client with bcrypt
    user.hashed_password = get_password_hash(request.new_password)
    db.commit()

    return {"message": "Password reset successful"} 