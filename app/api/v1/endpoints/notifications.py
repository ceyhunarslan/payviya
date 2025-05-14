from typing import Dict, Any
from fastapi import APIRouter, Body
from app.services.notification_service import NotificationService

router = APIRouter()

@router.post("/send")
async def send_notification(
    notification: Dict[str, Any] = Body(...),
) -> Dict[str, Any]:
    """
    Send a push notification.
    
    The notification body should contain:
    - title: Notification title
    - body: Notification message
    - businessId: Business ID (optional)
    - campaignId: Campaign ID (optional)
    """
    notification_service = NotificationService()
    result = await notification_service.send_notification(notification)
    return result 