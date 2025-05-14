from typing import Any, List, Dict
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime

from app.db.base import get_db
from app.schemas.recommendation import (
    RecommendationRequest, 
    RecommendationResponse,
    RecommendationClickRequest,
    RecommendationClickResponse
)
from app.services.recommendation_service import RecommendationService
from app.models.campaign import Campaign, CampaignSource
from app.schemas.campaign import CampaignOut
from app.api.deps import get_current_active_user
from app.models.user import User
from app.api.v1.endpoints.campaigns import campaign_to_campaign_out
import random

router = APIRouter()


@router.post("/", response_model=RecommendationResponse)
def get_card_recommendations(
    *,
    request: RecommendationRequest,
    db: Session = Depends(get_db)
) -> Any:
    """
    Get card recommendations based on cart amount, category, and user cards.
    
    This endpoint will analyze the transaction details and return:
    - Recommendations for cards the user already has
    - Recommendations for new cards they could apply for
    """
    recommendation_service = RecommendationService(db)
    return recommendation_service.get_recommendations(request)


@router.post("/click", response_model=RecommendationClickResponse)
def track_recommendation_click(
    *,
    request: RecommendationClickRequest,
    db: Session = Depends(get_db)
) -> Any:
    """
    Track when a user clicks on a recommendation (apply, enroll or select).
    
    This is used for analytics and to provide redirect URLs for card applications 
    or enrollment in bank promotions.
    """
    recommendation_service = RecommendationService(db)
    result = recommendation_service.track_recommendation_click(
        recommendation_id=request.recommendation_id,
        user_id=request.user_id,
        session_id=request.session_id,
        action_type=request.action_type
    )
    
    return RecommendationClickResponse(
        success=result["success"],
        redirect_url=result.get("redirect_url"),
        message=result["message"]
    )


@router.get("/campaigns", response_model=List[CampaignOut])
def get_recommended_campaigns(
    limit: int = 5,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Get recommended campaigns for the current user.
    In a real implementation, you would use a recommendation algorithm.
    For now, we'll just return random active campaigns.
    """
    try:
        # Get current time
        now = datetime.now()
        
        # Query active campaigns using SQLAlchemy with date validations
        query = db.query(Campaign).filter(
            Campaign.is_active == True,
            Campaign.start_date <= now,
            Campaign.end_date > now
        )
        
        # Get all valid campaigns
        campaigns = query.all()
        
        if not campaigns:
            return []
            
        # Convert campaigns to output format using campaign_to_campaign_out
        campaign_outs = []
        for campaign in campaigns:
            campaign_out = campaign_to_campaign_out(campaign, db)
            campaign_outs.append(campaign_out)
            
        # Apply random sampling if needed
        if len(campaign_outs) > limit:
            campaign_outs = random.sample(campaign_outs, limit)
            
        print(f"Returning {len(campaign_outs)} recommended campaigns")
        return campaign_outs
        
    except Exception as e:
        import traceback
        print(f"Error in get_recommended_campaigns: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 