from sqlalchemy import Column, Integer, String, Float, Boolean, Text, ForeignKey, DateTime, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.base import Base
from app.models.enums import DiscountType, CampaignSource, CampaignStatus


class CampaignCategory(Base):
    __tablename__ = "campaign_categories"

    id = Column(Integer, primary_key=True, index=True)
    enum = Column(String(50), nullable=False, unique=True)
    name = Column(String(100), nullable=False)
    icon_url = Column(String(512), nullable=True)
    color = Column(String(20), nullable=True)  # Hex color code
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    campaigns = relationship("Campaign", back_populates="category")
    notifications = relationship("NotificationHistory", back_populates="category")


class Campaign(Base):
    __tablename__ = "campaigns"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    bank_id = Column(Integer, ForeignKey("banks.id"))
    card_id = Column(Integer, ForeignKey("credit_cards.id"))
    category_id = Column(Integer, ForeignKey("campaign_categories.id"), nullable=False)
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
    category = relationship("CampaignCategory", back_populates="campaigns")
    reviewer = relationship("User", foreign_keys=[reviewed_by])
    notifications = relationship("NotificationHistory", back_populates="campaign")

    def to_json(self):
        """Convert campaign object to JSON serializable dictionary"""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "bank": self.bank.name if self.bank else None,
            "card": self.credit_card.name if self.credit_card else None,
            "category_id": self.category_id,
            "discount_type": self.discount_type.value,
            "discount_value": float(self.discount_value),
            "min_amount": float(self.min_amount) if self.min_amount else None,
            "max_discount": float(self.max_discount) if self.max_discount else None,
            "start_date": self.start_date.isoformat() if self.start_date else None,
            "end_date": self.end_date.isoformat() if self.end_date else None,
            "merchant_id": self.merchant_id,
            "merchant": self.merchant.to_json() if self.merchant else None,
            "is_active": self.is_active,
            "requires_enrollment": self.requires_enrollment,
            "enrollment_url": self.enrollment_url,
            "source": self.source.value,
            "status": self.status.value,
            "external_id": self.external_id,
            "priority": self.priority,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }


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
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    address = Column(String(512))
    city = Column(String(100))
    country = Column(String(100))
    phone = Column(String(20))
    website = Column(String(512))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    campaigns = relationship("Campaign", back_populates="merchant")
    notifications = relationship("NotificationHistory", back_populates="merchant")

    def to_json(self):
        """Convert merchant object to JSON serializable dictionary"""
        return {
            "id": self.id,
            "name": self.name,
            "categories": self.categories,
            "logo_url": self.logo_url,
            "latitude": float(self.latitude) if self.latitude is not None else None,
            "longitude": float(self.longitude) if self.longitude is not None else None,
            "address": self.address,
            "city": self.city,
            "country": self.country,
            "phone": self.phone,
            "website": self.website
        }


class ScrapedCampaign(Campaign):
    __tablename__ = "scraped_campaigns"
    
    id = Column(Integer, ForeignKey("campaigns.id"), primary_key=True)
    is_processed = Column(Boolean, default=False)
    scrape_source = Column(Text)
    scrape_attempted_at = Column(DateTime(timezone=True), server_default=func.now())
    scrape_log = Column(Text)

    __mapper_args__ = {
        'polymorphic_identity': 'scraped_campaign',
    } 