from typing import Optional, List
from pydantic import BaseModel, EmailStr
from app.schemas.credit_card import CreditCardOut


class UserBase(BaseModel):
    email: Optional[EmailStr] = None
    is_active: Optional[bool] = True
    is_superuser: Optional[bool] = False
    name: Optional[str] = None
    surname: Optional[str] = None
    country_code: Optional[str] = None
    phone_number: Optional[str] = None


class UserCreate(UserBase):
    email: EmailStr
    password: str


class UserUpdate(UserBase):
    password: Optional[str] = None


class UserInDBBase(UserBase):
    id: Optional[int] = None

    class Config:
        from_attributes = True


class User(UserInDBBase):
    pass


class UserWithCards(UserInDBBase):
    credit_cards: List[CreditCardOut] = []


class UserInDB(UserInDBBase):
    hashed_password: str 