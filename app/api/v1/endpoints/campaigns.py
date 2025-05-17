from typing import Any, List, Optional, Dict
from fastapi import APIRouter, Depends, HTTPException, Query, Path
from sqlalchemy.orm import Session
from datetime import datetime
from sqlalchemy import text
import logging
from sqlalchemy.sql import and_, or_

from app.db.base import get_db
from app.models.campaign import Campaign, Bank, CreditCard, Merchant, CampaignSource, DiscountType, CampaignStatus, CampaignCategory
from app.models.enums import CategoryEnum
from app.schemas.campaign import (
    CampaignCreate,
    CampaignUpdate,
    CampaignInDB,
    CampaignWithRelations,
    CampaignOut,
    CampaignWithDetailsRead
)
from app.api.deps import get_current_active_user, get_current_active_superuser
from app.models.user import User, user_credit_cards
from app.core.enum_helpers import safely_get_enum

# Create the main router
router = APIRouter()

# Create a sub-router for static endpoints
static_endpoints = APIRouter()

# Create a sub-router for dynamic endpoints
dynamic_endpoints = APIRouter()

# Set up logger
logger = logging.getLogger(__name__)

# Helper function to ensure proper encoding of string values
def ensure_utf8(value):
    """
    Ensure proper UTF-8 encoding for a value, handling Turkish characters correctly.
    """
    if value is None:
        return None
    
    # Explicitly convert to string and ensure proper encoding
    return str(value)

# Helper function to convert Campaign object to CampaignOut
def campaign_to_campaign_out(campaign: Campaign, db: Session) -> dict:
    """Convert a Campaign object to a dictionary matching CampaignOut schema"""
    # Create a copy of the campaign data to avoid modifying the original
    campaign_data = {}
    
    # Handle source field explicitly
    if hasattr(campaign, 'source'):
        source_str = str(campaign.source)
        # Remove enum class name if present (e.g., "CampaignSource.MANUAL" -> "MANUAL")
        if '.' in source_str:
            source_str = source_str.split('.')[-1]
        campaign_data['source'] = CampaignSource(source_str.upper() if source_str else "MANUAL")
    else:
        campaign_data['source'] = CampaignSource.MANUAL
    
    # Handle discount_type field
    if hasattr(campaign, 'discount_type'):
        discount_type_str = str(campaign.discount_type)
        if '.' in discount_type_str:
            discount_type_str = discount_type_str.split('.')[-1]
        campaign_data['discount_type'] = DiscountType(discount_type_str.upper() if discount_type_str else "PERCENTAGE")
    else:
        campaign_data['discount_type'] = DiscountType.PERCENTAGE
    
    # Get category from database
    category = None
    if campaign.category_id:
        category = db.query(CampaignCategory).filter(CampaignCategory.id == campaign.category_id).first()
        if category:
            campaign_data['category'] = CategoryEnum(category.enum)
    if not category:
        campaign_data['category'] = CategoryEnum.OTHER
        
    # Handle status field
    if hasattr(campaign, 'status'):
        status_str = str(campaign.status)
        if '.' in status_str:
            status_str = status_str.split('.')[-1]
        campaign_data['status'] = CampaignStatus(status_str.upper() if status_str else "APPROVED")
    else:
        campaign_data['status'] = CampaignStatus.APPROVED
    
    # Get related data
    bank = db.query(Bank).filter(Bank.id == campaign.bank_id).first()
    card = db.query(CreditCard).filter(CreditCard.id == campaign.card_id).first()
    merchant = None
    if campaign.merchant_id:
        merchant = db.query(Merchant).filter(Merchant.id == campaign.merchant_id).first()
    
    # Get category name
    category_name = None
    if campaign.category_id:
        category = db.query(CampaignCategory).filter(CampaignCategory.id == campaign.category_id).first()
        if category:
            category_name = category.name
    
    # Create the output dictionary with all required fields
    result = {
        "id": campaign.id,
        "name": campaign.name,
        "description": campaign.description,
        "bank_id": campaign.bank_id,
        "card_id": campaign.card_id,
        "category": campaign_data['category'],
        "campaign_category_name": category_name,
        "discount_type": campaign_data['discount_type'],
        "source": campaign_data['source'],
        "status": campaign_data['status'],
        "discount_value": float(campaign.discount_value),
        "min_amount": float(campaign.min_amount) if campaign.min_amount is not None else 0.0,
        "max_discount": float(campaign.max_discount) if campaign.max_discount is not None else None,
        "start_date": campaign.start_date,
        "end_date": campaign.end_date,
        "merchant_id": campaign.merchant_id,
        "is_active": campaign.is_active,
        "requires_enrollment": campaign.requires_enrollment,
        "enrollment_url": campaign.enrollment_url,
        "created_at": campaign.created_at,
        "updated_at": campaign.updated_at,
        "bank_name": bank.name if bank else None,
        "card_name": card.name if card else None,
        "merchant_name": merchant.name if merchant else None,
        "credit_card_application_url": card.application_url if card else None
    }
    
    # Copy over any other fields from campaign to result
    # Use getattr to avoid AttributeError if the field doesn't exist
    for key, value in vars(campaign).items():
        if key not in result and not key.startswith('_'):
            result[key] = value
            
    # Add debug logging
    print(f"Processed campaign ID={campaign.id}, Source={result['source']}, Category={result['category']}")
            
    return result

# Static endpoints
@static_endpoints.get("/test", response_model=dict)
def test_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    A simple test endpoint that returns basic data
    """
    return {"message": "This endpoint works", "user_id": current_user.id}

@static_endpoints.get("/stats", response_model=dict)
def get_campaign_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Get campaign statistics.
    """
    total = db.query(Campaign).count()
    active = db.query(Campaign).filter(Campaign.is_active == True).count()
    
    # Get campaigns expiring in the next 7 days
    import datetime
    now = datetime.datetime.now()
    seven_days_later = now + datetime.timedelta(days=7)
    expiring_soon = db.query(Campaign).filter(
        Campaign.end_date >= now,
        Campaign.end_date <= seven_days_later,
        Campaign.is_active == True
    ).count()
    
    return {
        "total": total,
        "active": active, 
        "expiring_soon": expiring_soon
    }

@static_endpoints.get("/categories", response_model=List[Dict[str, Any]])
def get_campaign_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Get list of campaign categories with full details.
    Only returns categories that have active and not expired campaigns.
    """
    try:
        # Get categories that have active and not expired campaigns
        current_time = datetime.utcnow()
        categories = (
            db.query(CampaignCategory)
            .join(Campaign, Campaign.category_id == CampaignCategory.id)
            .filter(Campaign.is_active == True)
            .filter(Campaign.end_date >= current_time)
            .distinct()
            .order_by(CampaignCategory.name)
            .all()
        )
        
        # Convert to response format
        return [{
            'id': category.id,
            'name': category.name,
            'enum': category.enum,
            'icon_url': category.icon_url,
            'color': category.color
        } for category in categories]
    except Exception as e:
        logger.error(f"Error fetching campaign categories: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fetching campaign categories: {str(e)}")

@static_endpoints.get("/last-captured", response_model=Dict[str, Any])
def get_last_captured_campaign(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Get the last captured campaign that is:
    1. Active (is_active = True)
    2. Not expired (end_date > now)
    3. Already started (start_date <= now)
    4. Most recently created
    """
    try:
        # Get current time
        now = datetime.now()
        
        # Get the last captured campaign with date validations
        campaign = db.query(Campaign)\
            .filter(
                Campaign.is_active == True,
                Campaign.start_date <= now,
                Campaign.end_date > now
            )\
            .order_by(Campaign.created_at.desc())\
            .first()
        
        if not campaign:
            raise HTTPException(status_code=404, detail="No active campaigns found")
        
        # Convert to output format using the helper function
        result = campaign_to_campaign_out(campaign, db)
        
        return result
        
    except Exception as e:
        # Log the error
        import traceback
        error_details = traceback.format_exc()
        print(f"Error in get_last_captured_campaign: {str(e)}")
        print(error_details)
        
        # Return an error response
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@static_endpoints.get("/", response_model=List[Dict[str, Any]])
def list_campaigns(
    *,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    bank_id: Optional[int] = None,
    card_id: Optional[int] = None,
    category: Optional[str] = None,
    is_active: Optional[bool] = True,
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    List campaigns with optional filters.
    """
    try:
        # Build the base query
        query = db.query(Campaign).filter(Campaign.is_active == True)
        
        # Add filter conditions
        if bank_id:
            query = query.filter(Campaign.bank_id == bank_id)
            
        if card_id:
            query = query.filter(Campaign.card_id == card_id)
            
        if category:
            query = query.filter(Campaign.category == category)
        
        # Order and paginate
        query = query.order_by(Campaign.created_at.desc())
        total = query.count()
        campaigns = query.offset(skip).limit(limit).all()
        
        # Convert to output format
        results = [campaign_to_campaign_out(campaign, db) for campaign in campaigns]
        
        # Log the number of results
        logger.info(f"Found {len(results)} campaigns matching filter criteria")
        
        return results
    
    except Exception as e:
        logger.error(f"Error fetching campaigns: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch campaigns: {str(e)}")

@static_endpoints.get("/special", response_model=List[CampaignOut])
def get_special_campaigns(
    skip: int = 0,
    limit: int = 20,
    category: Optional[str] = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> Any:
    """
    Get special campaigns matching user's active cards.
    """
    try:
        # Get user's active cards
        user_cards = (
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
        
        if not user_cards:
            return []
        
        # Get card IDs
        user_card_ids = [card.id for card in user_cards]
        
        # Build base query for active campaigns
        query = db.query(Campaign)\
            .filter(Campaign.is_active == True)\
            .filter(Campaign.card_id.in_(user_card_ids))
        
        # Add category filter if specified
        if category:
            # Get category ID from enum value
            category_obj = db.query(CampaignCategory)\
                .filter(CampaignCategory.enum == category.upper())\
                .first()
            if category_obj:
                query = query.filter(Campaign.category_id == category_obj.id)
        
        # Order by created date and paginate
        query = query.order_by(Campaign.created_at.desc())
        campaigns = query.offset(skip).limit(limit).all()
        
        # Convert to output format
        return [campaign_to_campaign_out(campaign, db) for campaign in campaigns]
        
    except Exception as e:
        logger.error(f"Error fetching special campaigns: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch special campaigns: {str(e)}")

@static_endpoints.get("/category/{category_id}", response_model=List[CampaignOut])
def get_campaigns_by_category(
    category_id: int,
    skip: int = 0, 
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Get campaigns by category ID.
    """
    try:
        # Get current time for filtering expired campaigns
        current_time = datetime.utcnow()
        
        # Query campaigns with category ID and not expired
        campaigns = db.query(Campaign)\
            .filter(Campaign.is_active == True)\
            .filter(Campaign.category_id == category_id)\
            .filter(Campaign.end_date >= current_time)\
            .order_by(Campaign.created_at.desc())\
            .offset(skip)\
            .limit(limit)\
            .all()
            
        # Convert to output format using campaign_to_campaign_out
        results = [campaign_to_campaign_out(campaign, db) for campaign in campaigns]
        
        return results
        
    except Exception as e:
        logger.error(f"Error fetching campaigns by category: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@static_endpoints.get("/search", response_model=List[Dict[str, Any]])
def search_campaigns(
    *,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    q: str = Query(..., description="Search query for campaign name or description"),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Search campaigns by name or description with case-insensitive matching.
    """
    try:
        # Get current time
        now = datetime.now()
        
        # Build the search query
        search_query = db.query(Campaign).filter(
            Campaign.is_active == True,
            Campaign.start_date <= now,
            Campaign.end_date > now
        )
        
        # Add case-insensitive search conditions
        search_terms = q.split()  # Split query into words
        for term in search_terms:
            search_term = f"%{term}%"
            search_query = search_query.filter(
                or_(
                    Campaign.name.ilike(search_term),
                    Campaign.description.ilike(search_term)
                )
            )
        
        # Apply pagination
        total = search_query.count()
        campaigns = search_query.offset(skip).limit(limit).all()
        
        # Convert campaigns to dictionary format
        result = []
        for campaign in campaigns:
            campaign_dict = campaign_to_campaign_out(campaign, db)
            result.append(campaign_dict)
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error searching campaigns: {str(e)}"
        )

# Dynamic endpoints
@dynamic_endpoints.get("/category/{category}", response_model=List[CampaignOut])
def get_campaigns_by_category(
    category: str,
    skip: int = 0, 
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Get campaigns by category.
    """
    try:
        # Get category ID from enum value
        category_obj = db.query(CampaignCategory).filter(CampaignCategory.enum == category.upper()).first()
        if not category_obj:
            return []
            
        # Query campaigns with category ID
        campaigns = db.query(Campaign)\
            .filter(Campaign.is_active == True)\
            .filter(Campaign.category_id == category_obj.id)\
            .order_by(Campaign.created_at.desc())\
            .offset(skip)\
            .limit(limit)\
            .all()
            
        # Convert to output format using campaign_to_campaign_out
        results = [campaign_to_campaign_out(campaign, db) for campaign in campaigns]
        
        return results
        
    except Exception as e:
        logger.error(f"Error fetching campaigns by category: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@dynamic_endpoints.get("/{campaign_id}", response_model=Dict[str, Any])
def get_campaign(
    *,
    db: Session = Depends(get_db),
    campaign_id: int = Path(..., gt=0),
) -> Any:
    """
    Get a specific campaign by ID.
    """
    try:
        # Get campaign with basic details
        campaign = db.query(Campaign).filter(Campaign.id == campaign_id).first()
        if not campaign:
            raise HTTPException(status_code=404, detail="Campaign not found")
            
        # Convert to output format using campaign_to_campaign_out helper
        response = campaign_to_campaign_out(campaign, db)
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching campaign {campaign_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch campaign: {str(e)}")

@dynamic_endpoints.post("/", response_model=CampaignInDB)
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

@dynamic_endpoints.put("/{campaign_id}", response_model=CampaignInDB)
def update_campaign(
    *,
    db: Session = Depends(get_db),
    campaign_id: int = Path(..., gt=0),
    campaign_in: CampaignUpdate,
) -> Any:
    """
    Update an existing campaign.
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

@dynamic_endpoints.delete("/{campaign_id}")
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

@static_endpoints.get("/active", response_model=List[Dict[str, Any]])
def get_active_campaigns(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    skip: int = 0,
    limit: int = 100,
):
    """
    Get active campaigns that have not expired.
    """
    try:
        # Get current time
        now = datetime.now()
        
        # Query active campaigns with date validations
        query = db.query(Campaign).filter(
            Campaign.is_active == True,
            Campaign.start_date <= now,
            Campaign.end_date > now
        )
        
        # Order by created date and paginate
        query = query.order_by(Campaign.created_at.desc())
        campaigns = query.offset(skip).limit(limit).all()
        
        # Convert to output format
        results = [campaign_to_campaign_out(campaign, db) for campaign in campaigns]
        
        return results
        
    except Exception as e:
        logger.error(f"Error fetching active campaigns: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch active campaigns: {str(e)}")

# Include the sub-routers in the main router
# Static endpoints must be included first
router.include_router(static_endpoints, prefix="")
router.include_router(dynamic_endpoints, prefix="")