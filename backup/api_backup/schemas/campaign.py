from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, HttpUrl

from app.models.campaign import CategoryEnum, DiscountType, CampaignSource, CampaignStatus


# Bank schemas
class BankBase(BaseModel):
    name: str
    logo_url: Optional[HttpUrl] = None


class BankCreate(BankBase):
    api_base_url: Optional[str] = None
    api_key: Optional[str] = None
    api_secret: Optional[str] = None


class BankUpdate(BankBase):
    name: Optional[str] = None
    api_base_url: Optional[str] = None
    api_key: Optional[str] = None
    api_secret: Optional[str] = None


class BankInDB(BankBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True


# Credit Card schemas
class CreditCardBase(BaseModel):
    name: str
    bank_id: int
    card_type: str
    card_tier: str
    annual_fee: Optional[float] = None
    rewards_rate: Optional[float] = None
    application_url: HttpUrl
    affiliate_code: Optional[str] = None
    logo_url: Optional[HttpUrl] = None
    is_active: bool = True


class CreditCardCreate(CreditCardBase):
    pass


class CreditCardUpdate(CreditCardBase):
    name: Optional[str] = None
    bank_id: Optional[int] = None
    card_type: Optional[str] = None
    card_tier: Optional[str] = None
    application_url: Optional[HttpUrl] = None
    logo_url: Optional[HttpUrl] = None
    is_active: Optional[bool] = None


class CreditCardInDB(CreditCardBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True


# Merchant schemas
class MerchantBase(BaseModel):
    name: str
    categories: str
    logo_url: Optional[HttpUrl] = None


class MerchantCreate(MerchantBase):
    pass


class MerchantUpdate(MerchantBase):
    name: Optional[str] = None
    categories: Optional[str] = None
    logo_url: Optional[HttpUrl] = None


class MerchantInDB(MerchantBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True


# Base schema
class CampaignBase(BaseModel):
    name: str
    description: Optional[str] = None
    bank_id: int
    card_id: int
    category: CategoryEnum
    discount_type: DiscountType
    discount_value: float = Field(..., gt=0)
    min_amount: Optional[float] = 0
    max_discount: Optional[float] = None
    start_date: datetime
    end_date: datetime
    merchant_id: Optional[int] = None
    is_active: bool = True
    requires_enrollment: bool = False
    enrollment_url: Optional[str] = None


# Schema for creating a campaign
class CampaignCreate(CampaignBase):
    # Additional fields for creation
    source: CampaignSource = CampaignSource.MANUAL
    status: CampaignStatus = CampaignStatus.APPROVED
    external_id: Optional[str] = None
    priority: int = 0


# Schema for updating a campaign
class CampaignUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    bank_id: Optional[int] = None
    card_id: Optional[int] = None
    category: Optional[CategoryEnum] = None
    discount_type: Optional[DiscountType] = None
    discount_value: Optional[float] = None
    min_amount: Optional[float] = None
    max_discount: Optional[float] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    merchant_id: Optional[int] = None
    is_active: Optional[bool] = None
    requires_enrollment: Optional[bool] = None
    enrollment_url: Optional[str] = None
    priority: Optional[int] = None
    status: Optional[CampaignStatus] = None


# Schema for reading a campaign
class CampaignRead(CampaignBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        orm_mode = True


# Schema for database models (compatible with existing code)
class CampaignInDB(CampaignRead):
    # Add any additional fields needed for database models
    
    class Config:
        orm_mode = True


# Schema specifically for pending campaigns
class PendingCampaignRead(CampaignRead):
    source: CampaignSource
    status: CampaignStatus
    external_id: Optional[str] = None
    priority: int
    last_sync_at: Optional[datetime] = None
    review_notes: Optional[str] = None
    
    class Config:
        orm_mode = True


# Schema for campaign with bank and card details
class CampaignWithDetailsRead(CampaignRead):
    bank: Optional[Dict[str, Any]] = None
    credit_card: Optional[Dict[str, Any]] = None
    merchant: Optional[Dict[str, Any]] = None
    
    class Config:
        orm_mode = True


# Response schema for sync processes
class CampaignImportResponse(BaseModel):
    success: bool
    message: str
    synced_banks: Optional[int] = None
    failed_banks: Optional[List[Dict[str, Any]]] = None
    total_campaigns: Optional[int] = None
    imported_campaigns: Optional[int] = None
    updated_campaigns: Optional[int] = None
    new_campaigns: Optional[int] = None
    pending_approval: Optional[int] = None
    auto_approved: Optional[int] = None


# Schema for campaign approval/rejection responses
class CampaignApproval(BaseModel):
    success: bool
    message: str
    campaign_id: int


# Campaign with relations
class CampaignWithRelations(CampaignRead):
    bank: BankInDB
    credit_card: CreditCardInDB
    merchant: Optional[MerchantInDB] = None

    class Config:
        orm_mode = True 