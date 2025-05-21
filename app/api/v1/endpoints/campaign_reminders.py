from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

from app.api import deps
from app.models.campaign_reminder import CampaignReminder
from app.schemas.campaign_reminder import CampaignReminderCreate, CampaignReminderResponse
from app.services.reminder_service import ReminderService

router = APIRouter()

@router.post("/", response_model=CampaignReminderResponse)
async def create_reminder(
    reminder: CampaignReminderCreate,
    db: Session = Depends(deps.get_db)
):
    """Create a new campaign reminder"""
    return await ReminderService.create_reminder(
        campaign_id=reminder.campaign_id,
        user_id=reminder.user_id,
        remind_at=reminder.remind_at,
        db=db
    )

@router.get("/user/{user_id}", response_model=List[CampaignReminderResponse])
def get_user_reminders(
    user_id: str,
    db: Session = Depends(deps.get_db)
):
    """Get all active reminders for a specific user"""
    reminders = db.query(CampaignReminder).filter(
        CampaignReminder.user_id == user_id,
        CampaignReminder.is_active == True
    ).all()
    return reminders

@router.delete("/{reminder_id}")
def delete_reminder(
    reminder_id: int,
    db: Session = Depends(deps.get_db)
):
    """Soft delete a specific reminder by setting is_active to False"""
    reminder = db.query(CampaignReminder).filter(CampaignReminder.id == reminder_id).first()
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")
    
    # Soft delete - set is_active to False
    reminder.is_active = False
    db.commit()
    return {"message": "Reminder deactivated successfully"} 