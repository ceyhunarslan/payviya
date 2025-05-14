from typing import Any, Dict
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session

from app.db.base import get_db
from app.services.bank_service import BankService

router = APIRouter()


@router.post("/campaigns/{campaign_id}/enroll")
async def enroll_in_campaign(
    campaign_id: int,
    user_identifiers: Dict[str, Any] = Body(...),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """
    Enroll a user in a specific bank campaign.
    
    This endpoint calls the corresponding bank's API to enroll the user in the
    campaign, which may be required to activate certain card benefits or promotions.
    
    The user_identifiers field should contain the data required by the bank for
    identification, which may include:
    - masked_card_number: The last 4 digits of a card
    - customer_id: Bank's customer ID
    - phone_number: User's registered phone number
    - other bank-specific identifiers
    """
    bank_service = BankService(db)
    result = await bank_service.enroll_in_campaign(
        campaign_id=campaign_id,
        user_identifiers=user_identifiers
    )
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result


@router.get("/campaigns/{campaign_id}/enrollments/{enrollment_id}")
async def check_enrollment_status(
    campaign_id: int,
    enrollment_id: str,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """
    Check the status of a previous campaign enrollment.
    
    This endpoint allows checking whether a previous enrollment request
    was successful or is still being processed.
    """
    bank_service = BankService(db)
    result = await bank_service.check_enrollment_status(
        campaign_id=campaign_id,
        enrollment_id=enrollment_id
    )
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result 