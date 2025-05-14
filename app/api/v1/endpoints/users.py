from typing import Any, List

from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
from sqlalchemy import and_, func

from app.api.deps import get_current_active_user, get_db
from app.models.user import User, user_credit_cards
from app.models.campaign import CreditCard, Bank
from app.schemas.user import User as UserSchema, UserUpdate, UserWithCards
from app.schemas.credit_card import CreditCardOut, CreditCardListItem, AddUserCardsRequest
from app.db.base import get_db

router = APIRouter()

@router.get("/me", response_model=UserWithCards)
def read_user_me(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> Any:
    """
    Get current user information including their active credit cards.
    """
    # Query active credit cards for the user
    active_cards = (
        db.query(CreditCard)
        .join(user_credit_cards)
        .filter(
            and_(
                user_credit_cards.c.user_id == current_user.id,
                user_credit_cards.c.status == True
            )
        )
        .all()
    )
    
    # Prepare the list of credit cards
    user_cards = []
    for card in active_cards:
        # Fetch the bank information for each card
        bank = db.query(Bank).filter(Bank.id == card.bank_id).first()
        
        card_dict = {
            "id": card.id,
            "name": card.name,
            "card_type": card.card_type,
            "card_tier": card.card_tier,
            "logo_url": card.logo_url,
            "bank_id": card.bank_id,
            "bank_name": bank.name if bank else None,
            "bank_logo_url": bank.logo_url if bank else None
        }
        user_cards.append(card_dict)
    
    # Return user data with cards
    return {
        "id": current_user.id,
        "email": current_user.email,
        "is_active": current_user.is_active,
        "is_superuser": current_user.is_superuser,
        "name": getattr(current_user, "name", ""),
        "surname": getattr(current_user, "surname", ""),
        "country_code": getattr(current_user, "country_code", ""),
        "phone_number": getattr(current_user, "phone_number", ""),
        "credit_cards": user_cards
    }

@router.get("/{user_id}", response_model=dict)
def read_user_by_id(
    user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> Any:
    """
    Get a specific user by id.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=404,
            detail="The user with this ID does not exist in the system",
        )
    return {
        "id": user.id,
        "email": user.email,
        "is_active": user.is_active,
        "is_superuser": user.is_superuser,
        "name": getattr(user, "name", ""),
        "surname": getattr(user, "surname", "")
    }

@router.post("/update", response_model=UserSchema)
def update_user(
    user_in: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Update current user information.
    """
    # Get a fresh instance of the user from the current session
    user = db.query(User).filter(User.id == current_user.id).first()
    
    # Update user fields
    for field, value in user_in.dict(exclude_unset=True).items():
        if hasattr(user, field) and value is not None:
            setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    return user

@router.post("/me/cards", response_model=List[CreditCardOut])
def add_user_cards(
    request: AddUserCardsRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> Any:
    """
    Add multiple credit cards to the current user's collection.
    """
    try:
        result = []
        for card_id in request.card_ids:
            # Check if the card exists
            card = db.query(CreditCard).filter(CreditCard.id == card_id).first()
            if not card:
                raise HTTPException(
                    status_code=404,
                    detail=f"Credit card with id {card_id} not found"
                )
            
            # Check if the user already has this card active
            user_card = (
                db.query(user_credit_cards)
                .filter(
                    and_(
                        user_credit_cards.c.user_id == current_user.id,
                        user_credit_cards.c.credit_card_id == card_id,
                        user_credit_cards.c.status == True
                    )
                )
                .first()
            )
            
            if user_card:
                raise HTTPException(
                    status_code=400,
                    detail=f"Credit card with id {card_id} is already associated with user"
                )
        
            # Add the card to the user's collection
            db.execute(
                user_credit_cards.insert().values(
                    user_id=current_user.id,
                    credit_card_id=card_id,
                    status=True,
                    created_at=func.now()
                )
            )
        
            # Fetch the bank for the response
            bank = db.query(Bank).filter(Bank.id == card.bank_id).first()
        
            # Prepare the response
            card_result = {
                "id": card.id,
                "name": card.name,
                "card_type": card.card_type,
                "card_tier": card.card_tier,
                "logo_url": card.logo_url,
                "bank_id": card.bank_id,
                "bank_name": bank.name if bank else None,
                "bank_logo_url": bank.logo_url if bank else None
            }
            result.append(card_result)
        
        db.commit()
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        # Log the error
        print(f"Error adding user cards: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"An error occurred while adding user cards: {str(e)}"
        )

@router.delete("/me/cards/{user_credit_card_id}", response_model=None, status_code=204)
def remove_user_card(
    user_credit_card_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> None:
    """
    Deactivate a credit card from the current user's collection using the user_credit_cards.id.
    """
    try:
        # Update the status in user_credit_cards table
        result = db.execute(
            user_credit_cards.update()
            .where(
                and_(
                    user_credit_cards.c.id == user_credit_card_id,
                    user_credit_cards.c.user_id == current_user.id,
                    user_credit_cards.c.status == True
                )
            )
            .values(status=False, updated_at=func.now())
        )
        
        if result.rowcount == 0:
            raise HTTPException(
                status_code=404, 
                detail="Credit card not found or already deactivated"
            )
        
        db.commit()
        return None
    except HTTPException:
        raise
    except Exception as e:
        # Log the error
        print(f"Error deactivating user card: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"An error occurred while deactivating user card: {str(e)}"
        )

@router.get("/cards", response_model=List[CreditCardOut])
def list_all_credit_cards(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> Any:
    """
    List all available credit cards that users can add to their collection.
    """
    try:
        # Get all credit cards with pagination
        cards = db.query(CreditCard).filter(CreditCard.is_active == True).offset(skip).limit(limit).all()
        
        # Prepare the response
        result = []
        for card in cards:
            # Fetch the bank for each card
            bank = db.query(Bank).filter(Bank.id == card.bank_id).first()
            
            card_dict = {
                "id": card.id,
                "name": card.name,
                "card_type": card.card_type,
                "card_tier": card.card_tier,
                "logo_url": card.logo_url,
                "bank_id": card.bank_id,
                "bank_name": bank.name if bank else None,
                "bank_logo_url": bank.logo_url if bank else None
            }
            result.append(card_dict)
            
        return result
    except Exception as e:
        # Log the error
        print(f"Error listing credit cards: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"An error occurred while listing credit cards: {str(e)}"
        )

@router.get("/me/cards", response_model=List[CreditCardListItem])
def list_user_cards(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> Any:
    """
    Get all active credit cards for the current user.
    """
    try:
        # Query active credit cards for the user
        user_cards = (
            db.query(CreditCard, Bank)
            .join(user_credit_cards, user_credit_cards.c.credit_card_id == CreditCard.id)
            .join(Bank, CreditCard.bank_id == Bank.id)
            .filter(
                and_(
                    user_credit_cards.c.user_id == current_user.id,
                    user_credit_cards.c.status == True
                )
            )
            .all()
        )
        
        # Convert the result to list of dictionaries
        result = []
        for card_row in user_cards:
            card, bank = card_row
            # Get the user_credit_cards.id
            user_card = db.execute(
                user_credit_cards.select()
                .where(
                    and_(
                        user_credit_cards.c.user_id == current_user.id,
                        user_credit_cards.c.credit_card_id == card.id,
                        user_credit_cards.c.status == True
                    )
                )
            ).first()
            
            card_dict = {
                "id": user_card.id if user_card else None,  # This is the user_credit_cards.id
                "credit_card_id": card.id,
                "credit_card_name": card.name,
                "credit_card_logo_url": card.logo_url,
                "bank_name": bank.name if bank else None,
                "bank_logo_url": bank.logo_url if bank else None
            }
            result.append(card_dict)
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"An error occurred while fetching user cards: {str(e)}"
        ) 