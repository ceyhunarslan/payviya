from datetime import datetime
from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.campaign_reminder import CampaignReminder
from app.models.campaign import Campaign
from app.models.user import User
from app.models.auth import UserAuth
from app.services.notification_service import NotificationService
import asyncio
import logging
from sqlalchemy.orm import joinedload
from sqlalchemy import func, text
import pytz

# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

async def send_single_reminder(reminder: CampaignReminder, notification_service: NotificationService, db: Session):
    """Send a single reminder notification"""
    try:
        campaign = reminder.campaign
        if not campaign:
            logger.warning(f"Campaign not found for reminder {reminder.id}")
            return

        # Get user's active FCM tokens
        user_auth_tokens = db.query(UserAuth).filter(
            UserAuth.user_id == int(reminder.user_id),
            UserAuth.is_active == True,
            UserAuth.fcm_token.isnot(None)
        ).all()

        if not user_auth_tokens:
            logger.warning(f"User {reminder.user_id} has no active FCM tokens")
            return

        logger.info(f"Sending reminder notification for campaign {campaign.name} (ID: {campaign.id}) to user {reminder.user_id}")

        success_count = 0
        # Send notification to all user's devices
        for auth_token in user_auth_tokens:
            # Send notification
            result = await notification_service.send_notification({
                "user_id": int(reminder.user_id),  # Convert user_id to integer
                "title": f"Kampanya Hatırlatması: {campaign.name}",
                "body": campaign.description[:100] + "...",
                "campaign_id": campaign.id,
                "category_id": campaign.category_id,
                "merchant_id": campaign.merchant_id if campaign.merchant_id else None,
                "latitude": campaign.merchant.latitude if campaign.merchant else 0.0,
                "longitude": campaign.merchant.longitude if campaign.merchant else 0.0,
                "data": {
                    "type": "REMINDER_CAMPAIGN",
                    "campaignId": str(campaign.id)
                },
                "fcm_token": auth_token.fcm_token
            }, db)

            if result.get("success", False):
                success_count += 1
                logger.info(f"Successfully sent reminder notification for campaign {campaign.id} to device {auth_token.device_id}")
            else:
                logger.error(f"Failed to send notification for reminder {reminder.id} to device {auth_token.device_id}: {result.get('message')}")

        if success_count > 0:
            # Mark as sent if at least one notification was successful
            reminder.is_sent = True
            db.commit()
            logger.info(f"Successfully sent reminder notifications for campaign {campaign.id} to {success_count} devices")

    except Exception as e:
        logger.error(f"Error sending notification for reminder {reminder.id}: {str(e)}")
        db.rollback()

async def send_reminder_notifications():
    """
    Check for due reminders and send notifications
    This function should be scheduled to run every 5 minutes
    """
    logger.info("Starting reminder notification check...")
    
    db = SessionLocal()
    notification_service = NotificationService()
    try:
        # Get current time in UTC
        current_time = datetime.now(pytz.UTC)
        logger.info(f"Current UTC time: {current_time}")

        # Get all unsent reminders that are due
        # First, convert remind_at to UTC for comparison
        due_reminders = (
            db.query(CampaignReminder)
            .options(
                joinedload(CampaignReminder.campaign).joinedload(Campaign.merchant)
            )
            .filter(
                CampaignReminder.is_sent == False,
                func.timezone('UTC', CampaignReminder.remind_at) <= current_time
            )
            .all()
        )

        if not due_reminders:
            logger.info("No due reminders found")
            return

        logger.info(f"Found {len(due_reminders)} due reminders")
        
        # Log reminder details for debugging
        for reminder in due_reminders:
            logger.info(f"Processing reminder ID: {reminder.id}, remind_at (UTC): {reminder.remind_at}, current_time (UTC): {current_time}")

        # Send notifications for all due reminders
        for reminder in due_reminders:
            await send_single_reminder(reminder, notification_service, db)

        logger.info("Reminder notification check completed")

    except Exception as e:
        logger.error(f"Error in send_reminder_notifications: {str(e)}")
    finally:
        db.close()
        logger.info("Database connection closed") 