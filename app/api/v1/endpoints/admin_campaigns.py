from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Path, Body
from sqlalchemy.orm import Session

from app.db.base import get_db
from app.models.campaign import Campaign, CampaignStatus, CampaignSource
from app.services.campaign_sync_service import CampaignSyncService
from app.schemas.campaign import (
    CampaignCreate, 
    CampaignUpdate, 
    CampaignImportResponse,
    PendingCampaignRead,
    CampaignApproval
)
from app.api.v1.deps import get_current_admin_user

router = APIRouter()

@router.get("/pending", response_model=List[PendingCampaignRead])
async def get_pending_campaigns(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_admin_user)
):
    """
    Get campaigns that are pending approval
    """
    campaign_sync_service = CampaignSyncService(db)
    pending_campaigns = campaign_sync_service.get_pending_campaigns(skip=skip, limit=limit)
    return pending_campaigns

@router.post("/approve/{campaign_id}", response_model=CampaignApproval)
async def approve_campaign(
    campaign_id: int = Path(..., description="The ID of the campaign to approve"),
    notes: Optional[str] = Body(None, description="Review notes"),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_admin_user)
):
    """
    Approve a campaign that is pending approval
    """
    campaign_sync_service = CampaignSyncService(db)
    result = campaign_sync_service.approve_campaign(
        campaign_id=campaign_id,
        admin_id=current_user.id,
        review_notes=notes
    )
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result

@router.post("/reject/{campaign_id}", response_model=CampaignApproval)
async def reject_campaign(
    campaign_id: int = Path(..., description="The ID of the campaign to reject"),
    notes: str = Body(..., description="Reason for rejection"),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_admin_user)
):
    """
    Reject a campaign that is pending approval
    """
    campaign_sync_service = CampaignSyncService(db)
    result = campaign_sync_service.reject_campaign(
        campaign_id=campaign_id,
        admin_id=current_user.id,
        review_notes=notes
    )
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result

@router.post("/sync-banks", response_model=CampaignImportResponse)
async def sync_campaigns_now(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_admin_user)
):
    """
    Manually trigger the campaign sync process for all banks
    """
    campaign_sync_service = CampaignSyncService(db)
    result = await campaign_sync_service.sync_all_banks()
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result

@router.post("/sync-bank/{bank_id}", response_model=CampaignImportResponse)
async def sync_bank_campaigns(
    bank_id: int = Path(..., description="The ID of the bank to sync campaigns from"),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_admin_user)
):
    """
    Manually trigger the campaign sync process for a specific bank
    """
    campaign_sync_service = CampaignSyncService(db)
    result = await campaign_sync_service.sync_bank_campaigns(bank_id)
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result 