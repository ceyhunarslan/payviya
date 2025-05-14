from typing import List, Optional
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.crud.campaign import campaign
from app.schemas.campaign import CampaignCreate, CampaignUpdate
from app.models.campaign import Campaign


def get_campaigns(
    db: Session,
    skip: int = 0,
    limit: int = 100,
    category: Optional[str] = None
) -> List[Campaign]:
    """Get all campaigns with optional category filter."""
    return campaign.get_multi(
        db,
        skip=skip,
        limit=limit,
        category=category
    )


def get_campaign(db: Session, campaign_id: int) -> Campaign:
    """Get a campaign by ID."""
    db_campaign = campaign.get(db, id=campaign_id)
    if not db_campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    return db_campaign


def create_campaign(db: Session, campaign_in: CampaignCreate) -> Campaign:
    """Create a new campaign."""
    return campaign.create(db, obj_in=campaign_in)


def update_campaign(
    db: Session,
    campaign_id: int,
    campaign_in: CampaignUpdate
) -> Campaign:
    """Update a campaign."""
    db_campaign = campaign.get(db, id=campaign_id)
    if not db_campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    
    return campaign.update(db, db_obj=db_campaign, obj_in=campaign_in)


def delete_campaign(db: Session, campaign_id: int) -> Campaign:
    """Delete a campaign."""
    db_campaign = campaign.get(db, id=campaign_id)
    if not db_campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    return campaign.remove(db, id=campaign_id) 