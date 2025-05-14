from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, Enum as SQLAlchemyEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.base_class import Base
from app.core.enums import CategoryEnum


class CampaignCategory(Base):
    __tablename__ = "campaign_categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    enum = Column(SQLAlchemyEnum(CategoryEnum), nullable=False)
    icon_url = Column(String, nullable=True)
    color = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=True)

    # Relationships
    campaigns = relationship("Campaign", back_populates="category") 