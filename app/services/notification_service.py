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
        try:
            print("\n=== NOTIFICATION SERVICE DEBUG ===")
            print(f"Received notification payload: {notification}")
            
            # Get FCM token from the notification data
            fcm_token = notification.get('fcm_token')
            if not fcm_token:
                print("❌ FCM token is missing")
                return {
                    "success": False,
                    "message": "FCM token is required"
                }
            
            # Zorunlu alanları kontrol et
            required_fields = {
                'user_id': int,
                'campaign_id': int,
                'latitude': float,
                'longitude': float,
                'category_id': int
            }
            
            print("\n📋 Checking required fields...")
            
            # Her bir zorunlu alan için tip kontrolü ve dönüşüm yap
            field_values = {}
            missing_fields = []
            invalid_fields = []
            
            for field, field_type in required_fields.items():
                try:
                    value = notification.get(field)
                    if value is None:
                        missing_fields.append(field)
                        print(f"❌ Missing field: {field}")
                        continue
                        
                    field_values[field] = field_type(value)
                    print(f"✅ Field {field} = {field_values[field]} ({type(field_values[field])})")
                except (ValueError, TypeError) as e:
                    print(f"❌ Invalid field {field}: {str(e)}")
                    invalid_fields.append(field)
            
            if missing_fields or invalid_fields:
                error_msg = []
                if missing_fields:
                    error_msg.append(f"Missing fields: {', '.join(missing_fields)}")
                if invalid_fields:
                    error_msg.append(f"Invalid field types: {', '.join(invalid_fields)}")
                    
                print(f"\n❌ Validation failed: {' | '.join(error_msg)}")
                return {
                    "success": False,
                    "message": " | ".join(error_msg)
                }
            
            # Location hash oluştur
            location_hash = self._generate_location_hash(
                field_values['latitude'],
                field_values['longitude']
            )
            
            # Extract data and convert all values to strings
            data = {}
            raw_data = notification.get('data', {})
            
            # Convert all values in data to strings
            for key, value in raw_data.items():
                data[str(key)] = str(value)
            
            # If type exists in root level, add it to data
            if 'type' in notification:
                data['type'] = str(notification['type'])
            
            print(f"\n📤 Sending FCM message with data: {data}")
            
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
            print(f"✅ FCM message sent successfully: {response}")

            print("\n💾 Saving to database...")
            # Create notification history record
            if db is None:
                print("Getting new database session...")
                db = next(get_db())

            # Get current date and time
            now = datetime.now()

            # Prepare notification history data according to the actual schema
            notification_history = NotificationHistory(
                user_id=field_values['user_id'],
                merchant_id=int(notification['merchant_id']) if notification.get('merchant_id') else None,
                campaign_id=field_values['campaign_id'],
                latitude=field_values['latitude'],
                longitude=field_values['longitude'],
                location_hash=location_hash,
                category_id=field_values['category_id'],
                sent_at=now,
                sent_date=now.date()
            )
            
            print(f"\n📝 Notification history object created:")
            print(f"user_id: {notification_history.user_id}")
            print(f"merchant_id: {notification_history.merchant_id}")
            print(f"campaign_id: {notification_history.campaign_id}")
            print(f"category_id: {notification_history.category_id}")
            print(f"latitude: {notification_history.latitude}")
            print(f"longitude: {notification_history.longitude}")
            print(f"location_hash: {notification_history.location_hash}")
            print(f"sent_at: {notification_history.sent_at}")
            print(f"sent_date: {notification_history.sent_date}")
            
            try:
                print("\n🔄 Adding to database session...")
                db.add(notification_history)
                print("✅ Added to session")
                
                print("\n💾 Committing to database...")
                db.commit()
                print("✅ Committed successfully")
                
                print(f"\n🆔 Generated notification history ID: {notification_history.id}")
            except Exception as db_error:
                print(f"\n❌ Database error: {str(db_error)}")
                if hasattr(db_error, '__cause__'):
                    print(f"Caused by: {str(db_error.__cause__)}")
                raise
            
            return {
                "success": True,
                "message": "Notification sent successfully",
                "messageId": response,
                "notification_history_id": notification_history.id
            }
            
        except Exception as e:
            print(f"\n❌ Error in send_notification: {str(e)}")
            if hasattr(e, '__cause__'):
                print(f"Caused by: {str(e.__cause__)}")
            print(f"Notification payload: {notification}")
            return {
                "success": False,
                "message": f"Failed to send notification: {str(e)}"
            } 