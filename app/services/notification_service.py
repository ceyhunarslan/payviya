from typing import Dict, Any
import firebase_admin
from firebase_admin import credentials, messaging
from sqlalchemy.orm import Session
from app.models.notification import NotificationHistory
from app.db.base import get_db
import os
import json
import hashlib
from datetime import datetime
import pytz
from app.models.campaign_reminder import CampaignReminder
from app.models.auth import UserAuth
import logging

# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

# Create console handler and set level to debug
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)

# Create formatter
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

# Add formatter to ch
ch.setFormatter(formatter)

# Add ch to logger
logger.addHandler(ch)

class NotificationService:
    def __init__(self):
        if not firebase_admin._apps:
            cred = credentials.Certificate('firebase-service-account.json')
            firebase_admin.initialize_app(cred)
    
    def _generate_location_hash(self, latitude: float, longitude: float) -> str:
        """Konum bilgisinden hash oluştur"""
        location_str = f"{latitude},{longitude}"
        return hashlib.md5(location_str.encode()).hexdigest()[:50]
    
    async def send_notification(self, notification: Dict[str, Any], db: Session = None) -> Dict[str, Any]:
        """Send a notification via FCM"""
        try:
            # Get FCM token from notification data
            fcm_token = notification.get('fcm_token')
            if not fcm_token:
                raise ValueError("FCM token not found")

            # Convert all data values to strings for FCM
            data = {}
            for key, value in notification.get('data', {}).items():
                data[str(key)] = str(value)

            # Prepare notification message
            message = messaging.Message(
                notification=messaging.Notification(
                    title=notification.get('title'),
                    body=notification.get('body'),
                ),
                data=data,
                token=fcm_token
            )

            # Send message
            response = messaging.send(message)
            logger.info(f"✅ FCM message sent successfully: {response}")

            # Create notification history record
            notification_history = NotificationHistory(
                user_id=notification['user_id'],
                merchant_id=notification.get('merchant_id'),
                campaign_id=notification['campaign_id'],
                latitude=notification.get('latitude'),
                longitude=notification.get('longitude'),
                location_hash=self._generate_location_hash(notification['latitude'], notification['longitude']) if notification.get('latitude') and notification.get('longitude') else None,
                category_id=notification.get('category_id'),
                title=notification['title'],
                body=notification['body'],
                is_read=False,
                data=notification.get('data')
            )

            if db:
                db.add(notification_history)
                db.commit()

            return {
                "success": True,
                "message": "Notification sent successfully",
                "messageId": response
            }

        except Exception as e:
            logger.error(f"Error sending notification: {str(e)}")
            raise e 