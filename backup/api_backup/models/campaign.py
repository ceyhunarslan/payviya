from sqlalchemy import Column, Integer, String, Float, Boolean, Text, ForeignKey, DateTime, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum

from app.db.base import Base


class CategoryEnum(str, enum.Enum):
    ELECTRONICS = "electronics"
    FASHION = "fashion"
    GROCERY = "grocery"
    TRAVEL = "travel"
    RESTAURANT = "restaurant"
    FUEL = "fuel"
    ENTERTAINMENT = "entertainment"
    OTHER = "other"


class DiscountType(str, enum.Enum):
    PERCENTAGE = "percentage"
    CASHBACK = "cashback"
    POINTS = "points"
    INSTALLMENT = "installment"


class CampaignSource(str, enum.Enum):
    MANUAL = "manual"           # Created manually in admin panel
    BANK_API = "bank_api"       # Imported from bank API
    FINTECH_API = "fintech_api" # Imported from fintech partners
    PARTNER_API = "partner_api" # Imported from other partners


class CampaignStatus(str, enum.Enum):
    DRAFT = "draft"             # Newly created, not yet approved
    PENDING = "pending"         # Pending approval (for imported campaigns)
    APPROVED = "approved"       # Approved and active
    REJECTED = "rejected"       # Rejected by admin
    ARCHIVED = "archived"       # No longer active but kept for reference


class Campaign(Base):
    __tablename__ = "campaigns"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    bank_id = Column(Integer, ForeignKey("banks.id"))
    card_id = Column(Integer, ForeignKey("credit_cards.id"))
    category = Column(Enum(CategoryEnum), nullable=False)
    discount_type = Column(Enum(DiscountType), nullable=False)
    discount_value = Column(Float, nullable=False)
    min_amount = Column(Float, default=0)
    max_discount = Column(Float, nullable=True)
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    merchant_id = Column(Integer, ForeignKey("merchants.id"), nullable=True)
    is_active = Column(Boolean, default=True)
    requires_enrollment = Column(Boolean, default=False)
    enrollment_url = Column(String(512), nullable=True)
    
    # New fields for hybrid approach
    source = Column(Enum(CampaignSource), default=CampaignSource.MANUAL, nullable=False)
    status = Column(Enum(CampaignStatus), default=CampaignStatus.APPROVED, nullable=False)
    external_id = Column(String(255), nullable=True)  # ID in the external system
    priority = Column(Integer, default=0)  # Higher number = higher priority
    last_sync_at = Column(DateTime(timezone=True), nullable=True)  # When was it last synced
    review_notes = Column(Text, nullable=True)  # Admin notes on approval/rejection
    reviewed_by = Column(Integer, ForeignKey("users.id"), nullable=True)  # Who reviewed it
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    bank = relationship("Bank", back_populates="campaigns")
    credit_card = relationship("CreditCard", back_populates="campaigns")
    merchant = relationship("Merchant", back_populates="campaigns")
    reviewer = relationship("User", foreign_keys=[reviewed_by])


class Bank(Base):
    __tablename__ = "banks"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    logo_url = Column(String(512))
    api_base_url = Column(String(512), nullable=True)
    api_key = Column(String(255), nullable=True)
    api_secret = Column(String(255), nullable=True)
    
    # New fields for campaign sync
    campaign_sync_enabled = Column(Boolean, default=False)
    campaign_sync_endpoint = Column(String(512), nullable=True)
    last_campaign_sync_at = Column(DateTime(timezone=True), nullable=True)
    auto_approve_campaigns = Column(Boolean, default=False)  # Whether to auto-approve from this bank
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    campaigns = relationship("Campaign", back_populates="bank")
    credit_cards = relationship("CreditCard", back_populates="bank")


class CreditCard(Base):
    __tablename__ = "credit_cards"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    bank_id = Column(Integer, ForeignKey("banks.id"))
    card_type = Column(String(50), nullable=False)  # e.g., Visa, Mastercard
    card_tier = Column(String(50), nullable=False)  # e.g., Gold, Platinum
    annual_fee = Column(Float, nullable=True)
    rewards_rate = Column(Float, nullable=True)
    application_url = Column(String(512))
    affiliate_code = Column(String(100), nullable=True)
    logo_url = Column(String(512))
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    bank = relationship("Bank", back_populates="credit_cards")
    campaigns = relationship("Campaign", back_populates="credit_card")


class Merchant(Base):
    __tablename__ = "merchants"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    categories = Column(String(255), nullable=False)  # Comma-separated categories
    logo_url = Column(String(512))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    campaigns = relationship("Campaign", back_populates="merchant") 