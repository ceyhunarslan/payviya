from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.campaign_reminder import CampaignReminder
from app.models.campaign import Campaign
from app.models.user import User
from app.models.auth import UserAuth
from app.services.notification_service import NotificationService
from app.models.notification import NotificationHistory
import asyncio
import logging
from sqlalchemy.orm import joinedload
from sqlalchemy import func, text
import pytz

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

async def send_single_reminder(reminder: CampaignReminder, notification_service: NotificationService, db: Session):
    """Send a single reminder notification"""
    try:
        campaign = reminder.campaign
        if not campaign:
            logger.warning(f"Campaign not found for reminder {reminder.id}")
            return

        logger.info("=== REMINDER DEBUG INFO ===")
        logger.info(f"Reminder ID: {reminder.id}")
        logger.info(f"Reminder Time: {reminder.remind_at}")
        logger.info(f"Current Time (Local): {datetime.now(pytz.timezone('Europe/Istanbul'))}")
        logger.info("========================")

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
        for user_auth in user_auth_tokens:
            try:
                # Prepare notification data
                notification_data = {
                    'title': f"{campaign.name} - Hatırlatma",
                    'body': f"'{campaign.name}' kampanyası için hatırlatma zamanı geldi!",
                    'data': {
                        "type": "REMINDER_CAMPAIGN",
                        "campaignId": campaign.id,
                        "reminderId": reminder.id
                    },
                    'fcm_token': user_auth.fcm_token,
                    'user_id': reminder.user_id,
                    'campaign_id': campaign.id  # Add campaign_id for notification history
                }
                
                # Send FCM notification directly
                await notification_service.send_notification(notification_data, db)
                success_count += 1
                
            except Exception as e:
                logger.error(f"Error sending notification to token {user_auth.fcm_token}: {str(e)}")
                continue

        if success_count > 0:
            # Mark reminder as sent if at least one notification was successful
            reminder.is_sent = True
            db.commit()
            logger.info(f"Successfully sent {success_count} notifications for reminder {reminder.id}")
        else:
            logger.warning(f"Failed to send any notifications for reminder {reminder.id}")

    except Exception as e:
        logger.error(f"Error processing reminder {reminder.id}: {str(e)}")
        raise e

async def send_reminder_notifications():
    """
    Check for due reminders and send notifications
    This function should be scheduled to run every 5 minutes
    """
    logger.info("Starting reminder notification check...")
    
    db = SessionLocal()
    notification_service = NotificationService()
    try:
        # Get current time in local timezone
        local_tz = pytz.timezone('Europe/Istanbul')
        local_now = datetime.now(local_tz)
        logger.info(f"Current local time: {local_now}")

        # Debug için tüm aktif hatırlatmaları kontrol et
        all_reminders = (
            db.query(CampaignReminder)
            .filter(
                CampaignReminder.is_sent == False,
                CampaignReminder.is_active == True
            )
            .all()
        )

        logger.info(f"Total active reminders found: {len(all_reminders)}")
        for reminder in all_reminders:
            logger.info(f"Checking reminder ID: {reminder.id}")
            logger.info(f"Reminder time: {reminder.remind_at} ({type(reminder.remind_at)})")
            logger.info(f"Current time: {local_now} ({type(local_now)})")
            logger.info(f"Is reminder due? {reminder.remind_at <= local_now}")
            logger.info("---")

        # Get all unsent and active reminders that are due
        # Veritabanındaki değerler zaten yerel saat olduğu için direkt karşılaştır
        due_reminders = (
            db.query(CampaignReminder)
            .options(
                joinedload(CampaignReminder.campaign).joinedload(Campaign.merchant)
            )
            .filter(
                CampaignReminder.is_sent == False,
                CampaignReminder.is_active == True,
                CampaignReminder.remind_at <= local_now
            )
            .all()
        )

        if not due_reminders:
            logger.info("No due reminders found")
            return

        logger.info(f"Found {len(due_reminders)} due reminders")
        
        for reminder in due_reminders:
            try:
                await send_single_reminder(reminder, notification_service, db)
            except Exception as e:
                logger.error(f"Failed to process reminder {reminder.id}: {str(e)}")
                continue

    except Exception as e:
        logger.error(f"Error in reminder notification job: {str(e)}")
        raise e
    finally:
        db.close() 