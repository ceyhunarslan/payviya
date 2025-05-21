from datetime import datetime, date
from sqlalchemy import Column, Integer, String, DateTime, Date, ForeignKey, Float, Boolean, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.base import Base

class NotificationHistory(Base):
    __tablename__ = "notification_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    merchant_id = Column(Integer, ForeignKey("merchants.id"), nullable=True)
    campaign_id = Column(Integer, ForeignKey("campaigns.id"), nullable=False)
    latitude = Column(Float, nullable=True)  # Optional for reminder notifications
    longitude = Column(Float, nullable=True)  # Optional for reminder notifications
    sent_at = Column(DateTime(timezone=True), server_default=func.now())
    sent_date = Column(Date, nullable=False, server_default=func.current_date())
    location_hash = Column(String(50), nullable=True)  # Optional for reminder notifications
    category_id = Column(Integer, ForeignKey("campaign_categories.id"), nullable=True)  # Optional for reminder notifications
    
    # New columns for notification details
    title = Column(String(255), nullable=False)
    body = Column(Text, nullable=False)
    is_read = Column(Boolean, nullable=False, server_default='false')
    read_at = Column(DateTime(timezone=True), nullable=True)
    data = Column(JSONB, nullable=True)  # For additional notification data
    
    # Relationships
    user = relationship("User", back_populates="notifications")
    merchant = relationship("Merchant", back_populates="notifications")
    campaign = relationship("Campaign", back_populates="notifications")
    category = relationship("CampaignCategory", back_populates="notifications") 