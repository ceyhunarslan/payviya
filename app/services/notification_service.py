from typing import Dict, Any
import firebase_admin
from firebase_admin import credentials, messaging
import os
import json

class NotificationService:
    def __init__(self):
        if not firebase_admin._apps:
            cred = credentials.Certificate('firebase-service-account.json')
            firebase_admin.initialize_app(cred)
    
    async def send_notification(self, notification: Dict[str, Any]) -> Dict[str, Any]:
        try:
            # Get FCM token from the notification data
            fcm_token = notification.get('fcm_token')
            if not fcm_token:
                return {
                    "success": False,
                    "message": "FCM token is required"
                }
            
            # Extract data and convert all values to strings
            data = {}
            raw_data = notification.get('data', {})
            
            # Convert all values in data to strings
            for key, value in raw_data.items():
                data[str(key)] = str(value)
            
            # If type exists in root level, add it to data
            if 'type' in notification:
                data['type'] = str(notification['type'])
            
            # If businessId exists in root level, add it to data
            if 'businessId' in notification:
                data['businessId'] = str(notification['businessId'])
            
            # If campaignId exists in root level, add it to data
            if 'campaignId' in notification:
                data['campaignId'] = str(notification['campaignId'])
            
            print(f"Sending FCM message with data: {data}")
            
            # Create message
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
            
            return {
                "success": True,
                "message": "Notification sent successfully",
                "messageId": response
            }
            
        except Exception as e:
            print(f"Error sending notification: {str(e)}")  # Add detailed error logging
            return {
                "success": False,
                "message": f"Failed to send notification: {str(e)}"
            } 