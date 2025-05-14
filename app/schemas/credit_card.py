from typing import Optional, List
from pydantic import BaseModel, Field


class CreditCardBase(BaseModel):
    """Base schema for credit card data"""
    name: str
    card_type: str
    card_tier: str
    logo_url: Optional[str] = None


class CreditCardOut(CreditCardBase):
    """Schema for credit card response data"""
    id: int
    bank_id: int
    bank_name: Optional[str] = None
    bank_logo_url: Optional[str] = None
    
    class Config:
        from_attributes = True  # This replaces the old orm_mode = True 


class CreditCardListItem(BaseModel):
    """Schema for user's credit cards response"""
    id: Optional[int] = None  # user_credit_cards.id
    credit_card_id: int
    credit_card_name: str
    credit_card_logo_url: str
    bank_name: str
    bank_logo_url: str

    class Config:
        json_schema_extra = {
            "example": {
                "id": 1,  # user_credit_cards.id for /users/me/cards endpoint
                "credit_card_id": 2,
                "credit_card_name": "Axess",
                "credit_card_logo_url": "https://example.com/axess-logo.png",
                "bank_name": "Akbank",
                "bank_logo_url": "https://example.com/akbank-logo.png"
            }
        }


class CreditCardResponse(BaseModel):
    """Schema for credit cards list response"""
    credit_card_id: int
    credit_card_name: str
    credit_card_logo_url: str
    bank_name: str
    bank_logo_url: str

    class Config:
        json_schema_extra = {
            "example": {
                "credit_card_id": 2,
                "credit_card_name": "Axess",
                "credit_card_logo_url": "https://example.com/axess-logo.png",
                "bank_name": "Akbank",
                "bank_logo_url": "https://example.com/akbank-logo.png"
            }
        }


class AddUserCardsRequest(BaseModel):
    """Request schema for adding multiple credit cards to user"""
    card_ids: List[int]

    class Config:
        json_schema_extra = {
            "example": {
                "card_ids": [1, 2, 3]
            }
        } 