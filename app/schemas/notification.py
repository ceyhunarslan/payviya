from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import Optional

from app.schemas.campaign import CampaignResponse
from app.schemas.merchant import MerchantResponse

class NotificationBase(BaseModel):
    user_id: int
    merchant_id: Optional[int] = None
    campaign_id: Optional[int] = None
    latitude: float
    longitude: float
    location_hash: str
    category_id: Optional[int] = None
    title: str
    body: str

class NotificationCreate(NotificationBase):
    pass

class NotificationResponse(NotificationBase):
    id: int
    sent_at: datetime = Field(..., description="ISO 8601 formatted datetime string with timezone")
    sent_date: date
    is_read: bool = False
    read_at: Optional[datetime] = Field(None, description="ISO 8601 formatted datetime string with timezone")
    campaign: Optional[CampaignResponse] = None
    merchant: Optional[MerchantResponse] = None

    class Config:
        from_attributes = True
        json_encoders = {
            datetime: lambda dt: dt.isoformat(),
            date: lambda d: d.isoformat()
        } 