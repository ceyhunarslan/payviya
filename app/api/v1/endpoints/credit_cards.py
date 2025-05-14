from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.api.deps import get_current_active_user, get_db
from app.models.user import User
from app.models.campaign import CreditCard, Bank
from app.schemas.credit_card import CreditCardOut, CreditCardResponse

router = APIRouter()

@router.get("/", response_model=List[CreditCardResponse])
def list_credit_cards(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> List[CreditCardResponse]:
    """
    Get all active credit cards with their bank information.
    This endpoint is used to get a list of available credit cards that users can add to their collection.
    """
    try:
        # Query all active credit cards and join with banks table
        cards = (
            db.query(CreditCard)
            .join(Bank)
            .filter(CreditCard.is_active == True)
            .all()
        )
        
        # Convert the result to list of dictionaries
        result = []
        for card in cards:
            card_dict = {
                "credit_card_id": card.id,
                "credit_card_name": card.name,
                "credit_card_logo_url": card.logo_url,
                "bank_name": card.bank.name if card.bank else None,
                "bank_logo_url": card.bank.logo_url if card.bank else None
            }
            result.append(card_dict)
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"An error occurred while fetching credit cards: {str(e)}"
        ) 