from typing import Dict, Any
from fastapi import APIRouter, Body, Depends
from sqlalchemy.orm import Session
from app.services.notification_service import NotificationService
from app.db.base import get_db

router = APIRouter()

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