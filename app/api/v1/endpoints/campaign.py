from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api import deps
from app.schemas.campaign import Campaign, CampaignCreate, CampaignUpdate
from app.services.campaign import (
    get_campaigns,
    get_campaign,
    create_campaign,
    update_campaign,
    delete_campaign
)

router = APIRouter()


@router.get("/", response_model=List[Campaign])
def read_campaigns(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
    category: Optional[str] = Query(None, description="Filter by category enum")
):
    """Retrieve campaigns."""
    return get_campaigns(db, skip=skip, limit=limit, category_enum=category)


@router.post("/", response_model=Campaign)
def create_campaign_endpoint(
    *,
    db: Session = Depends(deps.get_db),
    campaign_in: CampaignCreate
):
    """Create new campaign."""
    return create_campaign(db, campaign_in=campaign_in)


@router.get("/{campaign_id}", response_model=Campaign)
def read_campaign(
    campaign_id: int,
    db: Session = Depends(deps.get_db)
):
    """Get campaign by ID."""
    return get_campaign(db, campaign_id=campaign_id)


@router.put("/{campaign_id}", response_model=Campaign)
def update_campaign_endpoint(
    *,
    db: Session = Depends(deps.get_db),
    campaign_id: int,
    campaign_in: CampaignUpdate
):
    """Update a campaign."""
    return update_campaign(db, campaign_id=campaign_id, campaign_in=campaign_in)


@router.delete("/{campaign_id}", response_model=Campaign)
def delete_campaign_endpoint(
    *,
    db: Session = Depends(deps.get_db),
    campaign_id: int
):
    """Delete a campaign."""
    return delete_campaign(db, campaign_id=campaign_id) 