from datetime import datetime
from pydantic import BaseModel, Field
from typing import Optional

class CampaignReminderBase(BaseModel):
    user_id: str
    campaign_id: int
    remind_at: datetime = Field(..., description="ISO 8601 formatted datetime string")

class CampaignReminderCreate(CampaignReminderBase):
    pass

class CampaignReminderResponse(CampaignReminderBase):
    id: int
    created_at: datetime
    is_sent: bool = False

    class Config:
        from_attributes = True 