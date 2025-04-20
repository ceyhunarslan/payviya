from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field

from app.schemas.campaign import CampaignWithRelations, CreditCardInDB


class RecommendationRequest(BaseModel):
    user_id: Optional[int] = None
    session_id: Optional[str] = None
    cart_amount: float = Field(..., gt=0)
    cart_category: str
    merchant_name: Optional[str] = None
    user_cards: Optional[List[int]] = []  # List of credit card IDs the user has


class CardRecommendation(BaseModel):
    campaign_id: int
    card_id: int
    card_name: str
    bank_name: str
    discount_type: str
    discount_value: float
    final_amount: float
    savings_amount: float
    is_existing_card: bool
    requires_enrollment: bool
    enrollment_url: Optional[str] = None
    application_url: Optional[str] = None
    affiliate_code: Optional[str] = None
    logo_url: Optional[str] = None
    

class RecommendationResponse(BaseModel):
    request_id: str
    timestamp: datetime
    cart_amount: float
    cart_category: str
    merchant_name: Optional[str] = None
    existing_card_recommendations: List[CardRecommendation] = []
    new_card_recommendations: List[CardRecommendation] = []


class RecommendationClickRequest(BaseModel):
    recommendation_id: int
    user_id: Optional[int] = None
    session_id: Optional[str] = None
    action_type: str = Field(..., pattern='^(card_apply|enroll|select)$')


class RecommendationClickResponse(BaseModel):
    success: bool
    redirect_url: Optional[str] = None
    message: str 