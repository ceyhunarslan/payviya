from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, HttpUrl, validator
from enum import Enum

from app.models.campaign import DiscountType, CampaignSource, CampaignStatus
from app.models.campaign_category import CategoryEnum
from app.core.enum_helpers import safely_get_enum, get_all_enum_values


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
        from_attributes = True


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
        from_attributes = True


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
        from_attributes = True


# Base schema for campaign categories
class CampaignCategoryBase(BaseModel):
    name: str
    slug: str
    icon_url: Optional[str] = None
    color: Optional[str] = None


class CampaignCategoryCreate(CampaignCategoryBase):
    pass


class CampaignCategoryUpdate(CampaignCategoryBase):
    name: Optional[str] = None
    slug: Optional[str] = None
    icon_url: Optional[str] = None
    color: Optional[str] = None


class CampaignCategory(CampaignCategoryBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# Add validators for case-insensitive enum processing
class CaseInsensitiveEnumMixin:
    """Mixin to add case-insensitive enum validation to a schema"""
    
    @validator('discount_type', pre=True)
    def validate_discount_type(cls, v):
        if v is None:
            return None
        if isinstance(v, DiscountType):
            return v.value
        result = safely_get_enum(v, DiscountType)
        if result is None:
            raise ValueError(f"Invalid discount_type value: {v}. Valid values: {get_all_enum_values(DiscountType)}")
        return result.value
        
    @validator('source', pre=True)
    def validate_source(cls, v):
        if v is None:
            return None
        if isinstance(v, CampaignSource):
            return v.value
        result = safely_get_enum(v, CampaignSource)
        if result is None:
            raise ValueError(f"Invalid source value: {v}. Valid values: {get_all_enum_values(CampaignSource)}")
        return result.value
        
    @validator('status', pre=True)
    def validate_status(cls, v):
        if v is None:
            return None
        if isinstance(v, CampaignStatus):
            return v.value
        result = safely_get_enum(v, CampaignStatus)
        if result is None:
            raise ValueError(f"Invalid status value: {v}. Valid values: {get_all_enum_values(CampaignStatus)}")
        return result.value


class CampaignBase(BaseModel, CaseInsensitiveEnumMixin):
    name: str
    description: Optional[str] = None
    bank_id: int
    card_id: int
    category_id: int
    discount_type: DiscountType
    discount_value: float
    min_amount: float = 0.0
    max_discount: Optional[float] = None
    start_date: datetime
    end_date: datetime
    merchant_id: Optional[int] = None
    is_active: bool = True
    requires_enrollment: bool = False
    enrollment_url: Optional[str] = None
    source: CampaignSource = CampaignSource.MANUAL
    status: CampaignStatus = CampaignStatus.APPROVED
    external_id: Optional[str] = None
    priority: int = 0


class CampaignCreate(CampaignBase):
    pass


class CampaignUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    bank_id: Optional[int] = None
    card_id: Optional[int] = None
    category_id: Optional[int] = None
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
    source: Optional[CampaignSource] = None
    status: Optional[CampaignStatus] = None
    external_id: Optional[str] = None
    priority: Optional[int] = None


class Campaign(CampaignBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    last_sync_at: Optional[datetime] = None
    review_notes: Optional[str] = None
    reviewed_by: Optional[int] = None

    # Related entity data
    bank_name: Optional[str] = None
    card_name: Optional[str] = None
    merchant_name: Optional[str] = None
    category: Optional[CampaignCategory] = None

    @validator('discount_type', pre=True)
    def validate_discount_type(cls, v):
        if isinstance(v, str):
            if v.startswith('DISCOUNTTYPE.'):
                v = v.split('.')[1].lower()
            return DiscountType(v.lower())
        return v

    @validator('source', pre=True)
    def validate_source(cls, v):
        if isinstance(v, str):
            if v.startswith('CAMPAIGNSOURCE.'):
                v = v.split('.')[1].lower()
            return CampaignSource(v.lower())
        return v

    @validator('status', pre=True)
    def validate_status(cls, v):
        if isinstance(v, str):
            if v.startswith('CAMPAIGNSTATUS.'):
                v = v.split('.')[1].lower()
            return CampaignStatus(v.lower())
        return v

    @validator('category', pre=True)
    def validate_category(cls, v, values):
        if v is None and 'category_id' in values:
            return {
                'id': values.get('category_id'),
                'name': values.get('category_name', ''),
                'slug': values.get('category_enum', '').value if values.get('category_enum') else '',
                'icon_url': None,
                'color': None,
                'created_at': values.get('created_at'),
                'updated_at': values.get('updated_at')
            }
        return v

    class Config:
        from_attributes = True


class CampaignWithRelations(CampaignBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    bank: BankInDB
    credit_card: CreditCardInDB
    merchant: Optional[MerchantInDB] = None
    category: CampaignCategory

    class Config:
        from_attributes = True


class CampaignList(BaseModel):
    items: List[Campaign]
    total: int
    skip: int
    limit: int


# Schema for reading a campaign
class CampaignRead(CampaignBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


# Schema for database models (compatible with existing code)
class CampaignInDB(CampaignRead):
    # Add any additional fields needed for database models
    source: CampaignSource = CampaignSource.MANUAL
    status: CampaignStatus = CampaignStatus.APPROVED
    
    class Config:
        from_attributes = True


# Schema for campaign output in API responses
class CampaignOut(CampaignRead):
    # Include any fields needed for API responses
    bank_name: Optional[str] = None
    card_name: Optional[str] = None
    merchant_name: Optional[str] = None
    campaign_category_name: Optional[str] = None
    category: CategoryEnum
    source: CampaignSource = CampaignSource.MANUAL
    status: CampaignStatus = CampaignStatus.APPROVED
    credit_card_application_url: Optional[str] = None
    min_amount: float = 0.0
    
    class Config:
        from_attributes = True


# Schema specifically for pending campaigns
class PendingCampaignRead(CampaignRead):
    source: CampaignSource
    status: CampaignStatus
    external_id: Optional[str] = None
    priority: int
    last_sync_at: Optional[datetime] = None
    review_notes: Optional[str] = None
    
    class Config:
        from_attributes = True


# Schema for campaign with bank and card details
class CampaignWithDetailsRead(CampaignRead):
    bank: Optional[Dict[str, Any]] = None
    credit_card: Optional[Dict[str, Any]] = None
    merchant: Optional[Dict[str, Any]] = None
    
    class Config:
        from_attributes = True


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