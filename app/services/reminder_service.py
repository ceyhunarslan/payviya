from datetime import datetime
import pytz
from sqlalchemy.orm import Session
from app.models.campaign_reminder import CampaignReminder
from app.db.base import get_db

class ReminderService:
    @staticmethod
    async def create_reminder(campaign_id: int, user_id: str, remind_at: datetime, db: Session = None) -> CampaignReminder:
        """Create a new campaign reminder"""
        try:
            if db is None:
                db = next(get_db())

            # Flutter artık doğru UTC zamanı gönderiyor
            # Timezone bilgisi yoksa UTC olarak kabul et
            if remind_at.tzinfo is None:
                remind_at = pytz.UTC.localize(remind_at)
            else:
                # Eğer timezone bilgisi varsa, UTC'ye çevir
                remind_at = remind_at.astimezone(pytz.UTC)

            reminder = CampaignReminder(
                campaign_id=campaign_id,
                user_id=str(user_id),
                remind_at=remind_at,
                is_active=True
            )

            db.add(reminder)
            db.commit()
            db.refresh(reminder)

            return reminder
        except Exception as e:
            if 'db' in locals() and db is not None:
                db.rollback()
            raise e

    @staticmethod
    async def get_reminder(reminder_id: int, db: Session = None) -> CampaignReminder:
        """Get a reminder by ID"""
        if db is None:
            db = next(get_db())
        return db.query(CampaignReminder).filter(CampaignReminder.id == reminder_id).first()

    @staticmethod
    async def delete_reminder(reminder_id: int, db: Session = None) -> bool:
        """Delete a reminder"""
        try:
            if db is None:
                db = next(get_db())

            reminder = await ReminderService.get_reminder(reminder_id, db)
            if reminder:
                db.delete(reminder)
                db.commit()
                return True
            return False
        except Exception as e:
            if 'db' in locals() and db is not None:
                db.rollback()
            raise e 