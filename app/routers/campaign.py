from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.db.session import get_db
from app.models.campaign import Campaign, CampaignCategory
from app.schemas.campaign import (
    CampaignCreate, CampaignUpdate, Campaign as CampaignSchema,
    CampaignCategory as CampaignCategorySchema,
    CampaignCategoryCreate, CampaignList
)
from app.crud.campaign import campaign_crud
from app.core.auth import get_current_user

router = APIRouter()


@router.get("/categories", response_model=List[CampaignCategorySchema])
def get_campaign_categories(
    db: Session = Depends(get_db)
):
    """Get all campaign categories"""
    return db.query(CampaignCategory).all()


@router.get("/categories/{category_enum}", response_model=CampaignCategorySchema)
def get_campaign_category(
    category_enum: str,
    db: Session = Depends(get_db)
):
    """Get a specific campaign category by enum"""
    category = db.query(CampaignCategory).filter(
        CampaignCategory.enum == category_enum.upper()
    ).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    return category


@router.get("/", response_model=CampaignList)
def get_campaigns(
    skip: int = 0,
    limit: int = 100,
    category_enum: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get all campaigns with optional category filter"""
    query = db.query(Campaign)
    
    if category_enum:
        query = query.join(CampaignCategory).filter(
            CampaignCategory.enum == category_enum.upper()
        )
    
    total = query.count()
    items = query.offset(skip).limit(limit).all()
    
    return CampaignList(
        items=items,
        total=total,
        skip=skip,
        limit=limit
    )


@router.get("/{campaign_id}", response_model=CampaignSchema)
def get_campaign(
    campaign_id: int,
    db: Session = Depends(get_db)
):
    """Get a specific campaign by ID"""
    campaign = campaign_crud.get(db, id=campaign_id)
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    return campaign


@router.post("/", response_model=CampaignSchema)
def create_campaign(
    campaign: CampaignCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new campaign"""
    return campaign_crud.create(db, obj_in=campaign)


@router.put("/{campaign_id}", response_model=CampaignSchema)
def update_campaign(
    campaign_id: int,
    campaign: CampaignUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a campaign"""
    db_campaign = campaign_crud.get(db, id=campaign_id)
    if not db_campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    return campaign_crud.update(db, db_obj=db_campaign, obj_in=campaign)


@router.delete("/{campaign_id}")
def delete_campaign(
    campaign_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Delete a campaign"""
    campaign = campaign_crud.get(db, id=campaign_id)
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    campaign_crud.remove(db, id=campaign_id)
    return {"message": "Campaign deleted successfully"} 