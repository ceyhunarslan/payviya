from typing import Any, List, Dict, Optional
from fastapi import APIRouter, Depends, HTTPException, Path, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc, and_, extract, cast, Date
from datetime import datetime, timedelta

from app.db.base import get_db
from app.models.campaign import Campaign, Bank, CreditCard, Merchant
from app.models.user import Recommendation, RecommendationClick
from app.schemas.campaign import BankCreate, BankInDB, CreditCardCreate, CreditCardInDB, MerchantCreate, MerchantInDB

from app.api.v1.endpoints import admin_campaigns
from app.api.v1.endpoints.admin_analytics import router as analytics_router

router = APIRouter()

# Include the admin campaigns router
router.include_router(
    admin_campaigns.router, 
    prefix="/campaigns", 
    tags=["admin-campaigns"]
)

# Include the analytics router
router.include_router(
    analytics_router, 
    prefix="/analytics", 
    tags=["admin-analytics"]
)

# Bank endpoints
@router.get("/banks", response_model=List[BankInDB])
def get_banks(
    skip: int = 0, 
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """
    Get all banks.
    """
    banks = db.query(Bank).offset(skip).limit(limit).all()
    return banks

@router.post("/banks", response_model=BankInDB)
def create_bank(
    bank: BankCreate,
    db: Session = Depends(get_db)
):
    """
    Create a new bank.
    """
    db_bank = Bank(**bank.dict())
    db.add(db_bank)
    db.commit()
    db.refresh(db_bank)
    return db_bank

# Credit Card endpoints
@router.get("/credit-cards", response_model=List[CreditCardInDB])
def get_credit_cards(
    skip: int = 0, 
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """
    Get all credit cards.
    """
    credit_cards = db.query(CreditCard).offset(skip).limit(limit).all()
    return credit_cards

@router.post("/credit-cards", response_model=CreditCardInDB)
def create_credit_card(
    credit_card: CreditCardCreate,
    db: Session = Depends(get_db)
):
    """
    Create a new credit card.
    """
    db_credit_card = CreditCard(**credit_card.dict())
    db.add(db_credit_card)
    db.commit()
    db.refresh(db_credit_card)
    return db_credit_card

# Merchant endpoints
@router.get("/merchants", response_model=List[MerchantInDB])
def get_merchants(
    skip: int = 0, 
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """
    Get all merchants.
    """
    merchants = db.query(Merchant).offset(skip).limit(limit).all()
    return merchants

@router.post("/merchants", response_model=MerchantInDB)
def create_merchant(
    merchant: MerchantCreate,
    db: Session = Depends(get_db)
):
    """
    Create a new merchant.
    """
    db_merchant = Merchant(**merchant.dict())
    db.add(db_merchant)
    db.commit()
    db.refresh(db_merchant)
    return db_merchant

# Analytics endpoints
@router.get("/analytics/recommendations")
def get_recommendation_stats(
    *,
    db: Session = Depends(get_db),
    days: int = 30,
) -> Dict[str, Any]:
    """
    Get recommendation statistics for the dashboard.
    """
    # Calculate date range
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    # Total recommendations in period
    total_recommendations = db.query(func.count(Recommendation.id)).filter(
        Recommendation.created_at >= start_date,
        Recommendation.created_at <= end_date
    ).scalar()
    
    # Total clicks in period
    total_clicks = db.query(func.count(RecommendationClick.id)).filter(
        RecommendationClick.created_at >= start_date,
        RecommendationClick.created_at <= end_date
    ).scalar()
    
    # Clicks by action type
    clicks_by_type = db.query(
        RecommendationClick.action_type,
        func.count(RecommendationClick.id).label('count')
    ).filter(
        RecommendationClick.created_at >= start_date,
        RecommendationClick.created_at <= end_date
    ).group_by(RecommendationClick.action_type).all()
    
    clicks_by_type_dict = {action_type: count for action_type, count in clicks_by_type}
    
    # Calculate conversion rate
    conversion_rate = 0
    if total_recommendations > 0:
        conversion_rate = (total_clicks / total_recommendations) * 100
    
    return {
        "period_days": days,
        "total_recommendations": total_recommendations,
        "total_clicks": total_clicks,
        "conversion_rate": round(conversion_rate, 2),
        "clicks_by_type": clicks_by_type_dict
    }

@router.get("/analytics/campaigns")
def get_campaign_stats(
    *,
    db: Session = Depends(get_db),
    days: int = 30,
) -> Dict[str, Any]:
    """
    Get campaign performance statistics.
    """
    # Calculate date range
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    # Get recommendations by campaign
    campaign_stats = db.query(
        Recommendation.campaign_id,
        func.count(Recommendation.id).label('impression_count'),
        func.count(RecommendationClick.id).label('click_count')
    ).outerjoin(
        RecommendationClick,
        Recommendation.id == RecommendationClick.recommendation_id
    ).filter(
        Recommendation.created_at >= start_date,
        Recommendation.created_at <= end_date
    ).group_by(Recommendation.campaign_id).all()
    
    # Enrich with campaign details
    campaign_details = []
    for campaign_id, impression_count, click_count in campaign_stats:
        campaign = db.query(Campaign).filter(Campaign.id == campaign_id).first()
        if campaign:
            ctr = 0
            if impression_count > 0:
                ctr = (click_count / impression_count) * 100
                
            campaign_details.append({
                "campaign_id": campaign_id,
                "campaign_name": campaign.name,
                "bank_name": campaign.bank.name if campaign.bank else "Unknown",
                "card_name": campaign.credit_card.name if campaign.credit_card else "Unknown",
                "impression_count": impression_count,
                "click_count": click_count,
                "ctr": round(ctr, 2)
            })
    
    # Sort by impression count descending
    campaign_details.sort(key=lambda x: x["impression_count"], reverse=True)
    
    return {
        "period_days": days,
        "campaign_count": len(campaign_details),
        "campaigns": campaign_details
    } 