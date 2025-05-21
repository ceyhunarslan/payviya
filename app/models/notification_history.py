from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, DateTime, Date, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base_class import Base

class NotificationHistory(Base):
    __tablename__ = "notification_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    merchant_id = Column(Integer, ForeignKey("merchants.id"), nullable=True)
    campaign_id = Column(Integer, ForeignKey("campaigns.id"), nullable=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    sent_at = Column(DateTime(timezone=True), nullable=False)
    sent_date = Column(Date, default=datetime.utcnow().date, nullable=False)
    location_hash = Column(String, nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    title = Column(String, nullable=False)
    body = Column(String, nullable=False)
    is_read = Column(Boolean, default=False, nullable=False)
    read_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    user = relationship("User", back_populates="notifications")
    merchant = relationship("Merchant", back_populates="notifications")
    campaign = relationship("Campaign", back_populates="notifications")
    category = relationship("Category", back_populates="notifications")

    def to_dict(self):
        """Convert notification to dictionary with proper timezone handling"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "merchant_id": self.merchant_id,
            "campaign_id": self.campaign_id,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "sent_at": self.sent_at.isoformat() if self.sent_at else None,
            "sent_date": self.sent_date.isoformat() if self.sent_date else None,
            "location_hash": self.location_hash,
            "category_id": self.category_id,
            "title": self.title,
            "body": self.body,
            "is_read": self.is_read,
            "read_at": self.read_at.isoformat() if self.read_at else None,
            "campaign": self.campaign.to_json() if self.campaign else None,
            "merchant": self.merchant.to_json() if self.merchant else None
        } 