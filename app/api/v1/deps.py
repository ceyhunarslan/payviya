from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.base import get_db
from app.models.user import User


def get_current_admin_user(db: Session = Depends(get_db)):
    """
    Simple dependency to get an admin user for testing purposes.
    In a real application, this would verify JWT tokens, etc.
    """
    # For demo purposes, just return a mock admin user
    # In a real app, this would verify authentication
    return {
        "id": 1,
        "email": "admin@payviya.com",
        "is_admin": True,
        "full_name": "Admin User"
    } 