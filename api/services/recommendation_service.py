import uuid
from datetime import datetime
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session

from app.models.campaign import Campaign, CreditCard, Bank, CategoryEnum
from app.models.user import Recommendation, RecommendationClick, User
from app.schemas.recommendation import RecommendationRequest, CardRecommendation, RecommendationResponse


class RecommendationService:
    """Service for generating card recommendations based on cart data"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def find_matching_campaigns(
        self, 
        cart_amount: float, 
        cart_category: str,
        merchant_name: Optional[str] = None
    ) -> List[Campaign]:
        """Find all active campaigns that match the transaction criteria"""
        
        now = datetime.now()
        
        # Start with all active campaigns within date range
        query = self.db.query(Campaign).filter(
            Campaign.is_active == True,
            Campaign.start_date <= now,
            Campaign.end_date >= now,
            Campaign.min_amount <= cart_amount
        )
        
        # Filter by category if provided
        if cart_category:
            try:
                category_enum = CategoryEnum(cart_category.lower())
                query = query.filter(Campaign.category == category_enum)
            except ValueError:
                # If not a valid enum, try to match string
                pass
        
        # Filter by merchant if provided
        if merchant_name:
            from app.models.campaign import Merchant
            query = query.join(Merchant).filter(Merchant.name.ilike(f"%{merchant_name}%"))
        
        return query.all()
    
    def calculate_savings(self, campaign: Campaign, cart_amount: float) -> Dict[str, float]:
        """Calculate the final amount and savings for a given campaign and cart amount"""
        
        final_amount = cart_amount
        savings = 0.0
        
        if campaign.discount_type == "percentage":
            savings = cart_amount * (campaign.discount_value / 100)
            if campaign.max_discount and savings > campaign.max_discount:
                savings = campaign.max_discount
            final_amount = cart_amount - savings
            
        elif campaign.discount_type == "cashback":
            savings = campaign.discount_value
            if cart_amount * 0.3 < savings:  # Cap cashback at 30% of purchase
                savings = cart_amount * 0.3
            # Final amount stays the same for cashback
            
        elif campaign.discount_type == "points":
            # Points don't affect final amount, but represent value
            # Assuming 1 point = 0.01 currency units
            savings = campaign.discount_value * 0.01
            # Final amount stays the same for points
            
        # For installment type, simply pass through (no direct savings)
        
        return {
            "final_amount": final_amount,
            "savings_amount": savings
        }
    
    def create_card_recommendation(
        self, 
        campaign: Campaign,
        cart_amount: float,
        is_existing_card: bool
    ) -> CardRecommendation:
        """Create a card recommendation object from a campaign"""
        
        card = campaign.credit_card
        bank = campaign.bank
        
        calculation = self.calculate_savings(campaign, cart_amount)
        
        return CardRecommendation(
            campaign_id=campaign.id,
            card_id=card.id,
            card_name=card.name,
            bank_name=bank.name,
            discount_type=campaign.discount_type,
            discount_value=campaign.discount_value,
            final_amount=calculation["final_amount"],
            savings_amount=calculation["savings_amount"],
            is_existing_card=is_existing_card,
            requires_enrollment=campaign.requires_enrollment,
            enrollment_url=str(campaign.enrollment_url) if campaign.enrollment_url else None,
            application_url=str(card.application_url) if not is_existing_card else None,
            affiliate_code=card.affiliate_code if not is_existing_card else None,
            logo_url=str(card.logo_url) if card.logo_url else None
        )
    
    def get_recommendations(self, request: RecommendationRequest) -> RecommendationResponse:
        """Generate card recommendations based on the request"""
        
        # Find matching campaigns
        matching_campaigns = self.find_matching_campaigns(
            request.cart_amount,
            request.cart_category,
            request.merchant_name
        )
        
        # Get user's cards if user_id is provided
        user_card_ids = set(request.user_cards or [])
        if request.user_id:
            user = self.db.query(User).filter(User.id == request.user_id).first()
            if user:
                for card in user.credit_cards:
                    user_card_ids.add(card.id)
        
        # Create recommendations
        existing_card_recommendations = []
        new_card_recommendations = []
        
        # Process matching campaigns
        for campaign in matching_campaigns:
            card_id = campaign.card_id
            
            # Check if user has this card
            if card_id in user_card_ids:
                recommendation = self.create_card_recommendation(
                    campaign, request.cart_amount, True
                )
                existing_card_recommendations.append(recommendation)
            else:
                recommendation = self.create_card_recommendation(
                    campaign, request.cart_amount, False
                )
                new_card_recommendations.append(recommendation)
        
        # Sort recommendations by savings amount (highest first)
        existing_card_recommendations.sort(
            key=lambda x: x.savings_amount, reverse=True
        )
        new_card_recommendations.sort(
            key=lambda x: x.savings_amount, reverse=True
        )
        
        # Create response
        response = RecommendationResponse(
            request_id=str(uuid.uuid4()),
            timestamp=datetime.now(),
            cart_amount=request.cart_amount,
            cart_category=request.cart_category,
            merchant_name=request.merchant_name,
            existing_card_recommendations=existing_card_recommendations[:3],  # Top 3
            new_card_recommendations=new_card_recommendations[:3]  # Top 3
        )
        
        # Store recommendation in database
        self._store_recommendations(request, response)
        
        return response
    
    def _store_recommendations(
        self, 
        request: RecommendationRequest, 
        response: RecommendationResponse
    ) -> None:
        """Store generated recommendations in the database for analytics"""
        
        # Store each recommendation
        all_recommendations = (
            [(rec, True) for rec in response.existing_card_recommendations] +
            [(rec, False) for rec in response.new_card_recommendations]
        )
        
        for rec, is_existing in all_recommendations:
            db_recommendation = Recommendation(
                user_id=request.user_id,
                session_id=request.session_id or response.request_id,
                campaign_id=rec.campaign_id,
                merchant_name=request.merchant_name,
                cart_amount=request.cart_amount,
                cart_category=request.cart_category,
                discount_amount=rec.savings_amount,
                original_amount=request.cart_amount,
                is_existing_card=is_existing,
                needs_enrollment=rec.requires_enrollment
            )
            self.db.add(db_recommendation)
        
        self.db.commit()
    
    def track_recommendation_click(
        self,
        recommendation_id: int,
        user_id: Optional[int],
        session_id: Optional[str],
        action_type: str
    ) -> Dict[str, Any]:
        """Track when a user clicks on a recommendation"""
        
        # Find the recommendation
        recommendation = self.db.query(Recommendation).filter(
            Recommendation.id == recommendation_id
        ).first()
        
        if not recommendation:
            return {
                "success": False,
                "message": "Recommendation not found"
            }
        
        # Create click record
        click = RecommendationClick(
            user_id=user_id,
            session_id=session_id or recommendation.session_id,
            recommendation_id=recommendation_id,
            action_type=action_type
        )
        self.db.add(click)
        self.db.commit()
        
        # Determine redirect URL based on action type
        redirect_url = None
        if action_type == "card_apply":
            card = self.db.query(CreditCard).join(Campaign).filter(
                Campaign.id == recommendation.campaign_id
            ).first()
            if card:
                redirect_url = str(card.application_url)
                
        elif action_type == "enroll":
            campaign = self.db.query(Campaign).filter(
                Campaign.id == recommendation.campaign_id
            ).first()
            if campaign and campaign.enrollment_url:
                redirect_url = str(campaign.enrollment_url)
        
        return {
            "success": True,
            "redirect_url": redirect_url,
            "message": f"Successfully tracked {action_type} action"
        } 