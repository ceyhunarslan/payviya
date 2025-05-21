from typing import Dict, Any, List, Optional
from fastapi import APIRouter, Body, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from datetime import datetime
from pydantic import BaseModel
from app.services.notification_service import NotificationService
from app.db.base import get_db
from app.api.deps import get_current_user
from app.models.notification import NotificationHistory
from app.models.user import User

router = APIRouter()

class NotificationResponse(BaseModel):
    id: int
    title: str
    body: str
    sent_at: datetime
    is_read: bool
    read_at: Optional[datetime]
    campaign: Optional[dict]
    merchant: Optional[dict]

class PaginatedNotificationResponse(BaseModel):
    notifications: List[NotificationResponse]
    has_more: bool
    total_count: int

@router.post("/send")
async def send_notification(
    notification: Dict[str, Any] = Body(...),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """
    Send a push notification.
    
    The notification body should contain:
    - title: Notification title
    - body: Notification message
    - businessId: Business ID (optional)
    - campaignId: Campaign ID (optional)
    - fcm_token: Firebase Cloud Messaging token
    - type: Notification type (e.g., NEARBY_CAMPAIGN)
    """
    notification_service = NotificationService()
    result = await notification_service.send_notification(notification, db)
    return result

@router.get("/history", response_model=PaginatedNotificationResponse)
async def get_notification_history(
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=10, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get paginated notification history for the current user
    
    Parameters:
    - skip: Number of records to skip (offset)
    - limit: Maximum number of records to return
    """
    try:
        # Get total count
        total_count = (
            db.query(NotificationHistory)
            .filter(NotificationHistory.user_id == current_user.id)
            .count()
        )

        # Get paginated notifications
        notifications = (
            db.query(NotificationHistory)
            .filter(NotificationHistory.user_id == current_user.id)
            .order_by(
                NotificationHistory.is_read.asc(),  # Okunmamışlar önce
                desc(NotificationHistory.sent_at)   # Sonra tarih sırası
            )
            .offset(skip)
            .limit(limit + 1)  # Get one extra to check if there are more
            .all()
        )

        # Check if there are more items
        has_more = len(notifications) > limit
        if has_more:
            notifications = notifications[:-1]  # Remove the extra item

        return {
            "notifications": [
                {
                    "id": n.id,
                    "title": n.title,
                    "body": n.body,
                    "sent_at": n.sent_at,
                    "is_read": n.is_read,
                    "read_at": n.read_at,
                    "campaign": n.campaign.to_json() if n.campaign else None,
                    "merchant": n.merchant.to_json() if n.merchant else None,
                }
                for n in notifications
            ],
            "has_more": has_more,
            "total_count": total_count
        }
    except Exception as e:
        print(f"Error getting notification history: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{notification_id}/read")
async def mark_notification_as_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Mark a notification as read"""
    try:
        notification = (
            db.query(NotificationHistory)
            .filter(
                NotificationHistory.id == notification_id,
                NotificationHistory.user_id == current_user.id
            )
            .first()
        )

        if not notification:
            raise HTTPException(status_code=404, detail="Notification not found")

        if not notification.is_read:
            notification.is_read = True
            notification.read_at = datetime.now()
            db.commit()

        return {"success": True, "message": "Notification marked as read"}
    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"Error marking notification as read: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 