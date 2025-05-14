from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Table, Text, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.base import Base


# Association table for user_credit_cards
user_credit_cards = Table(
    "user_credit_cards",
    Base.metadata,
    Column("user_id", Integer, ForeignKey("users.id"), primary_key=True),
    Column("credit_card_id", Integer, ForeignKey("credit_cards.id"), primary_key=True),
)


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=True)
    hashed_password = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    name = Column(String(100), nullable=True)
    surname = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    credit_cards = relationship("CreditCard", secondary=user_credit_cards)
    recommendations = relationship("Recommendation", back_populates="user")
    recommendation_clicks = relationship("RecommendationClick", back_populates="user")


class Recommendation(Base):
    __tablename__ = "recommendations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    session_id = Column(String(255), nullable=True)  # For anonymous users
    campaign_id = Column(Integer, ForeignKey("campaigns.id"))
    merchant_name = Column(String(255), nullable=True)
    cart_amount = Column(Float, nullable=False)
    cart_category = Column(String(100), nullable=True)
    discount_amount = Column(Float, nullable=False)
    original_amount = Column(Float, nullable=False)
    is_existing_card = Column(Boolean, default=True)
    needs_enrollment = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="recommendations")
    campaign = relationship("Campaign")


class RecommendationClick(Base):
    __tablename__ = "recommendation_clicks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    session_id = Column(String(255), nullable=True)  # For anonymous users
    recommendation_id = Column(Integer, ForeignKey("recommendations.id"))
    action_type = Column(String(50), nullable=False)  # card_apply, enroll, select
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="recommendation_clicks")
    recommendation = relationship("Recommendation") 