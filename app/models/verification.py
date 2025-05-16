from sqlalchemy import Column, Integer, String, DateTime, Boolean, text
from sqlalchemy.sql import func
from app.db.base import Base


class VerificationCode(Base):
    __tablename__ = "verification_codes"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), nullable=False)
    code = Column(String(6), nullable=False)
    purpose = Column(String(50), nullable=False)
    is_used = Column(Boolean, nullable=False, server_default='false')
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    used_at = Column(DateTime(timezone=True), nullable=True)

    @property
    def is_expired(self):
        """Check if the verification code has expired"""
        return func.now() > self.expires_at

    @property
    def is_valid(self):
        """Check if the verification code is still valid"""
        return not self.is_used and not self.is_expired 