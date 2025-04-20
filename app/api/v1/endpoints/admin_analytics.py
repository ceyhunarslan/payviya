from typing import Any, List, Dict
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.base import get_db
from app.api.deps import get_current_admin_user

router = APIRouter()

@router.get("/dashboard")
def get_dashboard_analytics(
    *,
    current_admin = Depends(get_current_admin_user),
) -> Any:
    """
    Get dashboard analytics for admin.
    """
    # In a real app, this would fetch data from a database
    return {
        "campaigns_active": 32,
        "campaigns_pending": 5,
        "users_total": 1250,
        "cards_registered": 3210,
        "recent_activity": [
            {"type": "campaign_created", "timestamp": "2023-04-15T10:30:00Z"},
            {"type": "user_registered", "timestamp": "2023-04-15T09:45:00Z"},
            {"type": "card_added", "timestamp": "2023-04-15T08:30:00Z"}
        ]
    }

@router.get("/campaign-stats")
def get_campaign_stats(
    *,
    current_admin = Depends(get_current_admin_user),
) -> Any:
    """
    Get campaign statistics for admin.
    """
    # In a real app, this would fetch and aggregate data from a database
    return {
        "by_category": {
            "dining": 15,
            "shopping": 22,
            "travel": 8,
            "entertainment": 12
        },
        "by_bank": {
            "Garanti BBVA": 18,
            "Yapı Kredi": 14,
            "İş Bankası": 12,
            "Akbank": 10,
            "Others": 5
        },
        "by_status": {
            "active": 32,
            "pending": 5,
            "expired": 24
        }
    } 