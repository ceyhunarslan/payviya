# Models module initialization

# Import Base
from app.db.base import Base

# Import all models to make them available when importing from app.models
from app.models.campaign import Campaign, Bank, CreditCard, Merchant, CategoryEnum, DiscountType
from app.models.user import User, Recommendation, RecommendationClick 