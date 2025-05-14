from typing import Any, List, Dict
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.base import get_db
from app.schemas.recommendation import (
    RecommendationRequest, 
    RecommendationResponse,
    RecommendationClickRequest,
    RecommendationClickResponse
)
from app.services.recommendation_service import RecommendationService

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