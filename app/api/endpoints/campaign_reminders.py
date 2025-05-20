from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

from app.api import deps
from app.models.campaign_reminder import CampaignReminder
from app.schemas.campaign_reminder import CampaignReminderCreate, CampaignReminderResponse

router = APIRouter()

@router.post("/", response_model=CampaignReminderResponse)
def create_reminder(
    reminder: CampaignReminderCreate,
    db: Session = Depends(deps.get_db)
):
    """Create a new campaign reminder"""
    db_reminder = CampaignReminder(
        user_id=reminder.user_id,
        campaign_id=reminder.campaign_id,
        remind_at=reminder.remind_at
    )
    db.add(db_reminder)
    db.commit()
    db.refresh(db_reminder)
    return db_reminder

@router.get("/user/{user_id}", response_model=List[CampaignReminderResponse])
def get_user_reminders(
    user_id: str,
    db: Session = Depends(deps.get_db)
):
    """Get all reminders for a specific user"""
    reminders = db.query(CampaignReminder).filter(CampaignReminder.user_id == user_id).all()
    return reminders

@router.delete("/{reminder_id}")
def delete_reminder(
    reminder_id: int,
    db: Session = Depends(deps.get_db)
):
    """Delete a specific reminder"""
    reminder = db.query(CampaignReminder).filter(CampaignReminder.id == reminder_id).first()
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")
    
    db.delete(reminder)
    db.commit()
    return {"message": "Reminder deleted successfully"} 