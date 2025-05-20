from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base_class import Base
from app.models.campaign import CampaignReminder

# Moving this model to campaign.py
# class CampaignReminder(Base):
#     __tablename__ = "campaign_reminders"
#     __table_args__ = {'extend_existing': True}

#     id = Column(Integer, primary_key=True, index=True)
#     user_id = Column(String, index=True)
#     campaign_id = Column(Integer, ForeignKey("campaigns.id", ondelete="CASCADE"))
#     remind_at = Column(DateTime, nullable=False)
#     created_at = Column(DateTime(timezone=True), server_default=func.now())
#     updated_at = Column(DateTime(timezone=True), onupdate=func.now())
#     is_sent = Column(Boolean, default=False)

#     # Relationship with cascade delete
#     campaign = relationship("Campaign", back_populates="reminders", passive_deletes=True) 

# Re-export CampaignReminder for backward compatibility
__all__ = ['CampaignReminder'] 