from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Path
from sqlalchemy.orm import Session
from datetime import datetime

from app.db.base import get_db
from app.models.campaign import Campaign, Bank, CreditCard, Merchant, CategoryEnum
from app.schemas.campaign import (
    CampaignCreate,
    CampaignUpdate,
    CampaignInDB,
    CampaignWithRelations
)

router = APIRouter()


@router.get("/", response_model=List[CampaignInDB])
def list_campaigns(
    *,
    db: Session = Depends(get_db),
    bank_id: Optional[int] = None,
    card_id: Optional[int] = None,
    category: Optional[CategoryEnum] = None,
    is_active: Optional[bool] = True,
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Retrieve campaigns with optional filtering.
    """
    query = db.query(Campaign)
    
    if bank_id is not None:
        query = query.filter(Campaign.bank_id == bank_id)
    if card_id is not None:
        query = query.filter(Campaign.card_id == card_id)
    if category is not None:
        query = query.filter(Campaign.category == category)
    if is_active is not None:
        query = query.filter(Campaign.is_active == is_active)
    
    # Only get current or future campaigns
    now = datetime.now()
    query = query.filter(Campaign.end_date >= now)
    
    # Order by newest first
    query = query.order_by(Campaign.created_at.desc())
    
    campaigns = query.offset(skip).limit(limit).all()
    return campaigns


@router.get("/{campaign_id}", response_model=CampaignWithRelations)
def get_campaign(
    *,
    db: Session = Depends(get_db),
    campaign_id: int = Path(..., gt=0),
) -> Any:
    """
    Get detailed information about a specific campaign.
    """
    campaign = db.query(Campaign).filter(Campaign.id == campaign_id).first()
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    return campaign


@router.post("/", response_model=CampaignInDB)
def create_campaign(
    *,
    db: Session = Depends(get_db),
    campaign_in: CampaignCreate,
) -> Any:
    """
    Create a new campaign.
    """
    # Verify bank exists
    bank = db.query(Bank).filter(Bank.id == campaign_in.bank_id).first()
    if not bank:
        raise HTTPException(status_code=404, detail="Bank not found")
    
    # Verify card exists
    card = db.query(CreditCard).filter(CreditCard.id == campaign_in.card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Credit card not found")
    
    # Verify merchant exists if provided
    if campaign_in.merchant_id:
        merchant = db.query(Merchant).filter(Merchant.id == campaign_in.merchant_id).first()
        if not merchant:
            raise HTTPException(status_code=404, detail="Merchant not found")
    
    # Create campaign
    campaign = Campaign(**campaign_in.dict())
    db.add(campaign)
    db.commit()
    db.refresh(campaign)
    return campaign


@router.put("/{campaign_id}", response_model=CampaignInDB)
def update_campaign(
    *,
    db: Session = Depends(get_db),
    campaign_id: int = Path(..., gt=0),
    campaign_in: CampaignUpdate,
) -> Any:
    """
    Update a campaign.
    """
    campaign = db.query(Campaign).filter(Campaign.id == campaign_id).first()
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    
    # Update campaign with non-null fields from input
    update_data = campaign_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(campaign, field, value)
    
    db.commit()
    db.refresh(campaign)
    return campaign


@router.delete("/{campaign_id}")
def delete_campaign(
    *,
    db: Session = Depends(get_db),
    campaign_id: int = Path(..., gt=0),
) -> Any:
    """
    Delete a campaign.
    
    Note: This only soft-deletes by setting is_active to False.
    """
    campaign = db.query(Campaign).filter(Campaign.id == campaign_id).first()
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    
    # Soft delete
    campaign.is_active = False
    db.commit()
    
    return {"success": True, "message": "Campaign deactivated successfully"} 