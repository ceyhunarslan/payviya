from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from datetime import datetime
from pydantic import BaseModel
from app.db.base import get_db
from app.api.deps import oauth2_scheme
from app.models.campaign import Campaign, Merchant, Bank, CreditCard, CampaignCategory
from app.services.osm_service import OSMService

router = APIRouter()

class LocationRequest(BaseModel):
    latitude: float
    longitude: float
    radius: float = 100.0  # meters

class Business(BaseModel):
    id: str
    name: str
    type: str
    latitude: float
    longitude: float
    active_campaigns: List[dict] = []

    class Config:
        from_attributes = True

@router.post("/nearby-campaigns", response_model=List[Business])
async def get_nearby_businesses_with_campaigns(
    location: LocationRequest,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme)
):
    """
    Get businesses with active campaigns near the specified location.
    Uses both OpenStreetMap data and database merchants.
    """
    try:
        # Get current time for campaign validity check
        now = datetime.now()

        # Get businesses from OpenStreetMap
        osm_businesses = await OSMService.get_nearby_businesses(
            latitude=location.latitude,
            longitude=location.longitude,
            radius=int(location.radius)
        )

        # Get active campaigns with category information
        active_campaigns = (
            db.query(Campaign, CampaignCategory)
            .join(CampaignCategory, Campaign.category_id == CampaignCategory.id)
            .filter(
                and_(
                    Campaign.is_active == True,
                    Campaign.start_date <= now,
                    Campaign.end_date >= now
                )
            )
            .all()
        )

        # Format response
        result = []
        processed_merchants = set()

        # First, add merchants from database
        for campaign, category in active_campaigns:
            if campaign.merchant_id and campaign.merchant_id not in processed_merchants:
                merchant = campaign.merchant
                if merchant:
                    processed_merchants.add(merchant.id)
                    merchant_campaigns = [c for c, cat in active_campaigns if c.merchant_id == merchant.id]
                    
                    # Format campaigns
                    campaign_list = []
                    for camp in merchant_campaigns:
                        campaign_dict = {
                            "id": camp.id,
                            "name": camp.name,
                            "description": camp.description,
                            "discount_type": camp.discount_type.value,
                            "discount_value": float(camp.discount_value),
                            "min_amount": float(camp.min_amount) if camp.min_amount else None,
                            "max_discount": float(camp.max_discount) if camp.max_discount else None,
                            "bank": camp.bank.name if camp.bank else None,
                            "card": camp.credit_card.name if camp.credit_card else None,
                            "requires_enrollment": camp.requires_enrollment,
                            "enrollment_url": camp.enrollment_url
                        }
                        campaign_list.append(campaign_dict)

                    business = {
                        "id": str(merchant.id),
                        "name": merchant.name,
                        "type": merchant.categories.split(',')[0] if merchant.categories else "OTHER",
                        "latitude": float(merchant.latitude),
                        "longitude": float(merchant.longitude),
                        "active_campaigns": campaign_list
                    }
                    result.append(business)

        # Create a map of non-merchant campaigns by category
        category_campaigns = {}
        for campaign, category in active_campaigns:
            if not campaign.merchant_id:  # Only consider non-merchant-specific campaigns
                if category.enum not in category_campaigns:
                    category_campaigns[category.enum] = []
                category_campaigns[category.enum].append(campaign)

        # Then, add businesses from OSM that match campaign categories
        for osm_business in osm_businesses:
            business_type = osm_business.get("type")
            if not business_type or business_type not in category_campaigns:
                continue

            # Get matching campaigns for this business type
            matching_campaigns = category_campaigns[business_type]
            if not matching_campaigns:
                continue

            # Format campaigns
            campaign_list = []
            for campaign in matching_campaigns:
                campaign_dict = {
                    "id": campaign.id,
                    "name": campaign.name,
                    "description": campaign.description,
                    "discount_type": campaign.discount_type.value,
                    "discount_value": float(campaign.discount_value),
                    "min_amount": float(campaign.min_amount) if campaign.min_amount else None,
                    "max_discount": float(campaign.max_discount) if campaign.max_discount else None,
                    "bank": campaign.bank.name if campaign.bank else None,
                    "card": campaign.credit_card.name if campaign.credit_card else None,
                    "requires_enrollment": campaign.requires_enrollment,
                    "enrollment_url": campaign.enrollment_url
                }
                campaign_list.append(campaign_dict)

            business = {
                "id": osm_business["id"],
                "name": osm_business["name"],
                "type": business_type,
                "latitude": float(osm_business["latitude"]),
                "longitude": float(osm_business["longitude"]),
                "active_campaigns": campaign_list
            }
            result.append(business)

        return result

    except Exception as e:
        print(f"Error in get_nearby_businesses_with_campaigns: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 