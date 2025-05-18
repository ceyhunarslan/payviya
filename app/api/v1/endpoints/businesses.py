from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from datetime import datetime
from pydantic import BaseModel
from app.db.base import get_db
from app.api.deps import oauth2_scheme, get_current_user
from app.models.campaign import Campaign, Merchant, Bank, CreditCard, CampaignCategory
from app.models.notification import NotificationHistory
from app.services.osm_service import OSMService
from app.services.notification_service import NotificationService
import hashlib

router = APIRouter()

class LocationRequest(BaseModel):
    latitude: float
    longitude: float
    radius: float = 100.0  # meters

class LocationRequestWithToken(LocationRequest):
    fcm_token: str  # Add FCM token to request

class Business(BaseModel):
    id: str
    name: str
    type: str
    latitude: float
    longitude: float
    active_campaigns: List[dict] = []

    class Config:
        from_attributes = True

def _generate_location_hash(latitude: float, longitude: float) -> str:
    """Generate a hash for the given location coordinates"""
    location_str = f"{latitude},{longitude}"
    return hashlib.md5(location_str.encode()).hexdigest()[:50]

def check_campaign_notification_eligibility(
    db: Session,
    user_id: int,
    campaign_id: int,
    latitude: float,
    longitude: float,
) -> bool:
    """
    Check if a campaign is eligible for notification based on various rules:
    - Has not been sent to the user at the same location today
    - Any other business rules can be added here
    
    Returns:
        bool: True if the campaign is eligible for notification, False otherwise
    """
    try:
        # Generate location hash
        location_hash = _generate_location_hash(latitude, longitude)
        
        # Check if notification was already sent today
        today = datetime.now().date()
        notification = db.query(NotificationHistory).filter(
            NotificationHistory.user_id == user_id,
            NotificationHistory.campaign_id == campaign_id,
            NotificationHistory.location_hash == location_hash,
            NotificationHistory.sent_date == today
        ).first()
        
        # Campaign is eligible if no notification was sent today
        return notification is None
        
    except Exception as e:
        print(f"Error checking campaign eligibility: {str(e)}")
        return False  # Default to ineligible on error

@router.post("/nearby-campaigns", response_model=List[Business])
async def get_nearby_businesses_with_campaigns(
    location: LocationRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get businesses with active campaigns near the specified location.
    Uses both OpenStreetMap data and database merchants.
    Only returns campaigns that are eligible for notification.
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

        # Create a map of non-merchant campaigns by category
        category_campaigns = {}
        for campaign, category in active_campaigns:
            if not campaign.merchant_id:  # Only consider non-merchant-specific campaigns
                if category.enum not in category_campaigns:
                    category_campaigns[category.enum] = []
                category_campaigns[category.enum].append(campaign)

        # Then, add businesses from OSM that match campaign categories
        for osm_business in osm_businesses:
            business_name = osm_business.get("name", "").strip()
            business_type = osm_business.get("type")
            
            print(f"\nProcessing OSM business: {business_name} (Type: {business_type})")
            
            # First check if this business matches any merchant-specific campaigns
            merchant_matched = False
            merchant_campaigns = []
            matching_category_id = None
            matching_merchant_id = None
            
            # Strict merchant name matching
            for campaign, category in active_campaigns:
                if campaign.merchant and campaign.merchant.name:
                    merchant_name = campaign.merchant.name.strip()
                    
                    # Normalize both names for comparison
                    business_name_norm = business_name.upper().strip()
                    merchant_name_norm = merchant_name.upper().strip()
                    
                    print(f"  Comparing merchant names - OSM: '{business_name_norm}' vs DB: '{merchant_name_norm}'")
                    
                    # Exact match required for merchant-specific campaigns
                    if business_name_norm == merchant_name_norm:
                        print(f"  ✅ Found exact merchant match: {business_name}")
                        merchant_matched = True
                        merchant_campaigns.append(campaign)
                        matching_category_id = category.id
                        matching_merchant_id = campaign.merchant.id
                        print(f"  📝 Using category ID: {matching_category_id} from merchant campaign")
                        print(f"  📝 Using merchant ID: {matching_merchant_id} from merchant campaign")
                        break  # Stop looking once we find an exact match
            
            # If we found merchant-specific campaigns, only use those
            if merchant_matched:
                print(f"  Using {len(merchant_campaigns)} merchant-specific campaigns")
                matching_campaigns = merchant_campaigns
            else:
                # If no merchant match, check category campaigns
                print("  No merchant match found, checking category campaigns")
                if not business_type or business_type not in category_campaigns:
                    print("  ❌ No matching category found")
                    continue
                
                matching_campaigns = category_campaigns[business_type]
                if not matching_campaigns:
                    print("  ❌ No category campaigns found")
                    continue
                
                # Get category ID for category-based campaigns
                for campaign, category in active_campaigns:
                    if category.enum == business_type:
                        matching_category_id = category.id
                        print(f"  📝 Using category ID: {matching_category_id} from category match")
                        break
                
                print(f"  Found {len(matching_campaigns)} category campaigns")

            # Format campaigns and check eligibility
            campaign_list = []
            for campaign in matching_campaigns:
                # Check if this campaign is eligible for notification
                if not check_campaign_notification_eligibility(
                    db=db,
                    user_id=current_user.id,
                    campaign_id=campaign.id,
                    latitude=location.latitude,
                    longitude=location.longitude
                ):
                    print(f"  ❌ Campaign {campaign.id} not eligible for notification")
                    continue  # Skip ineligible campaigns
                
                print(f"  ✅ Campaign {campaign.id} eligible for notification")
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
                    "enrollment_url": campaign.enrollment_url,
                    "category_id": matching_category_id,
                    "merchant_id": campaign.merchant_id,
                    "merchant": campaign.merchant.to_json() if campaign.merchant else None
                }
                campaign_list.append(campaign_dict)

            # Only add business if it has eligible campaigns
            if campaign_list:
                business = {
                    "id": str(osm_business["id"]),
                    "name": business_name,
                    "type": business_type,
                    "latitude": float(osm_business["latitude"]),
                    "longitude": float(osm_business["longitude"]),
                    "active_campaigns": campaign_list,
                }
                result.append(business)
                print(f"  ✅ Added business with {len(campaign_list)} campaigns")

        return result

    except Exception as e:
        print(f"Error in get_nearby_businesses_with_campaigns: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 

@router.post("/nearby-campaigns-notify")
async def notify_nearby_campaigns(
    location: LocationRequestWithToken,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get businesses with active campaigns near the specified location and send notifications.
    Uses both OpenStreetMap data and database merchants.
    Sends notifications for eligible campaigns directly.
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

        # Initialize notification service
        notification_service = NotificationService()
        notification_sent = False

        # Format response
        processed_merchants = set()

        # Create a map of non-merchant campaigns by category
        category_campaigns = {}
        for campaign, category in active_campaigns:
            if not campaign.merchant_id:  # Only consider non-merchant-specific campaigns
                if category.enum not in category_campaigns:
                    category_campaigns[category.enum] = []
                category_campaigns[category.enum].append(campaign)

        # Then, process businesses from OSM
        for osm_business in osm_businesses:
            if notification_sent:
                break

            business_name = osm_business.get("name", "").strip()
            business_type = osm_business.get("type")
            
            print(f"\nProcessing OSM business: {business_name} (Type: {business_type})")
            
            # First check if this business matches any merchant-specific campaigns
            merchant_matched = False
            merchant_campaigns = []
            matching_category_id = None
            matching_merchant_id = None
            
            # Strict merchant name matching
            for campaign, category in active_campaigns:
                if campaign.merchant and campaign.merchant.name:
                    merchant_name = campaign.merchant.name.strip()
                    
                    # Normalize both names for comparison
                    business_name_norm = business_name.upper().strip()
                    merchant_name_norm = merchant_name.upper().strip()
                    
                    print(f"  Comparing merchant names - OSM: '{business_name_norm}' vs DB: '{merchant_name_norm}'")
                    
                    # Exact match required for merchant-specific campaigns
                    if business_name_norm == merchant_name_norm:
                        print(f"  ✅ Found exact merchant match: {business_name}")
                        merchant_matched = True
                        merchant_campaigns.append(campaign)
                        matching_category_id = category.id
                        matching_merchant_id = campaign.merchant.id
                        print(f"  📝 Using category ID: {matching_category_id} from merchant campaign")
                        print(f"  📝 Using merchant ID: {matching_merchant_id} from merchant campaign")
                        break  # Stop looking once we find an exact match
            
            # If we found merchant-specific campaigns, only use those
            if merchant_matched:
                print(f"  Using {len(merchant_campaigns)} merchant-specific campaigns")
                matching_campaigns = merchant_campaigns
            else:
                # If no merchant match, check category campaigns
                print("  No merchant match found, checking category campaigns")
                if not business_type or business_type not in category_campaigns:
                    print("  ❌ No matching category found")
                    continue
                
                matching_campaigns = category_campaigns[business_type]
                if not matching_campaigns:
                    print("  ❌ No category campaigns found")
                    continue
                
                # Get category ID for category-based campaigns
                for campaign, category in active_campaigns:
                    if category.enum == business_type:
                        matching_category_id = category.id
                        print(f"  📝 Using category ID: {matching_category_id} from category match")
                        break

            # Sort campaigns by priority (if implemented)
            matching_campaigns.sort(key=lambda x: getattr(x, 'priority', 0), reverse=True)

            # Try each campaign for this business
            for campaign in matching_campaigns:
                # Check eligibility
                if not check_campaign_notification_eligibility(
                    db=db,
                    user_id=current_user.id,
                    campaign_id=campaign.id,
                    latitude=location.latitude,
                    longitude=location.longitude
                ):
                    print(f"  ❌ Campaign {campaign.id} not eligible for notification")
                    continue

                # Prepare notification payload
                notification_payload = {
                    'title': 'Yakınlarında Fırsat Var! 🎉',
                    'body': f'{business_name}: {campaign.description}',
                    'user_id': current_user.id,
                    'merchant_id': matching_merchant_id,
                    'campaign_id': campaign.id,
                    'category_id': matching_category_id,
                    'latitude': location.latitude,
                    'longitude': location.longitude,
                    'fcm_token': location.fcm_token,
                    'type': 'NEARBY_CAMPAIGN',
                    'data': {
                        'businessId': str(osm_business["id"]),
                        'campaignId': str(campaign.id),
                        'type': 'NEARBY_CAMPAIGN'
                    }
                }

                try:
                    # Send notification
                    result = await notification_service.send_notification(notification_payload, db)
                    if result.get('success'):
                        notification_sent = True
                        print(f"✅ Notification sent successfully for campaign {campaign.id}")
                        break  # Exit campaign loop after successful notification
                    else:
                        print(f"❌ Failed to send notification: {result.get('message')}")
                except Exception as e:
                    print(f"❌ Error sending notification: {str(e)}")
                    continue

            if notification_sent:
                break  # Exit business loop after successful notification

        return {"success": True, "message": "Nearby campaigns processed successfully"}

    except Exception as e:
        print(f"Error in notify_nearby_campaigns: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))