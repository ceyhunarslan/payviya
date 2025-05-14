# Models module initialization

# Import Base
from app.db.base import Base

# Import all models to make them available when importing from app.models
from app.models.campaign import Campaign, Bank, CreditCard, Merchant
from app.models.campaign_category import CategoryEnum
from app.models.enums import DiscountType, CampaignSource, CampaignStatus
from app.models.user import User, Recommendation, RecommendationClick 

__all__ = [
    "Campaign",
    "Bank", 
    "CreditCard",
    "Merchant",
    "User",
    "CategoryEnum",
    "DiscountType",
    "CampaignSource",
    "CampaignStatus"
] 