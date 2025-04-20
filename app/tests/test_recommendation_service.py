import unittest
from datetime import datetime, timedelta
from unittest.mock import Mock, patch

from app.models.campaign import Campaign, CreditCard, Bank, CategoryEnum, DiscountType
from app.models.user import User, Recommendation
from app.schemas.recommendation import RecommendationRequest
from app.services.recommendation_service import RecommendationService


class TestRecommendationService(unittest.TestCase):
    def setUp(self):
        # Create a mock DB session
        self.db = Mock()
        
        # Setup test data
        self.bank = Bank(id=1, name="Test Bank", logo_url="http://example.com/logo.png")
        self.card = CreditCard(
            id=1, 
            name="Test Card", 
            bank_id=1, 
            card_type="Visa", 
            card_tier="Gold",
            application_url="http://example.com/apply",
            logo_url="http://example.com/card_logo.png"
        )
        
        # Create a test campaign
        now = datetime.now()
        self.campaign = Campaign(
            id=1,
            name="Test Campaign",
            bank_id=1,
            card_id=1,
            category=CategoryEnum.ELECTRONICS,
            discount_type=DiscountType.PERCENTAGE,
            discount_value=10.0,
            min_amount=100.0,
            max_discount=50.0,
            start_date=now,
            end_date=now + timedelta(days=30),
            is_active=True,
            requires_enrollment=False
        )
        
        # Setup relationships
        self.campaign.bank = self.bank
        self.campaign.credit_card = self.card
        
        # Setup service
        self.service = RecommendationService(self.db)

    def test_calculate_savings_percentage(self):
        # Test percentage discount
        self.campaign.discount_type = DiscountType.PERCENTAGE
        self.campaign.discount_value = 10.0
        self.campaign.max_discount = 50.0
        
        # Test with amount under max discount cap
        result = self.service.calculate_savings(self.campaign, 200.0)
        self.assertEqual(result["savings_amount"], 20.0)
        self.assertEqual(result["final_amount"], 180.0)
        
        # Test with amount that exceeds max discount cap
        result = self.service.calculate_savings(self.campaign, 1000.0)
        self.assertEqual(result["savings_amount"], 50.0)  # Capped at max_discount
        self.assertEqual(result["final_amount"], 950.0)

    def test_calculate_savings_cashback(self):
        # Test cashback
        self.campaign.discount_type = DiscountType.CASHBACK
        self.campaign.discount_value = 30.0
        
        result = self.service.calculate_savings(self.campaign, 200.0)
        self.assertEqual(result["savings_amount"], 30.0)
        self.assertEqual(result["final_amount"], 200.0)  # Cashback doesn't change final amount

    def test_find_matching_campaigns(self):
        # Setup mock query and results
        mock_query = Mock()
        self.db.query.return_value = mock_query
        mock_query.filter.return_value = mock_query
        mock_query.all.return_value = [self.campaign]
        
        # Test finding campaigns
        result = self.service.find_matching_campaigns(200.0, "electronics")
        
        # Verify query was called
        self.db.query.assert_called_once()
        self.assertEqual(result, [self.campaign])

    @patch('app.services.recommendation_service.uuid.uuid4')
    def test_get_recommendations(self, mock_uuid):
        # Mock UUID
        mock_uuid.return_value = "test-uuid"
        
        # Setup mocks for find_matching_campaigns
        self.service.find_matching_campaigns = Mock(return_value=[self.campaign])
        
        # Mock DB operation for storing recommendations
        self.service._store_recommendations = Mock()
        
        # Create test request
        request = RecommendationRequest(
            cart_amount=200.0,
            cart_category="electronics",
            user_cards=[2, 3]  # Not including our test card (id=1)
        )
        
        # Get recommendations
        response = self.service.get_recommendations(request)
        
        # Verify results
        self.assertEqual(response.request_id, "test-uuid")
        self.assertEqual(response.cart_amount, 200.0)
        self.assertEqual(response.cart_category, "electronics")
        
        # Should be in new card recommendations (not existing)
        self.assertEqual(len(response.existing_card_recommendations), 0)
        self.assertEqual(len(response.new_card_recommendations), 1)
        
        # Verify card details
        card_rec = response.new_card_recommendations[0]
        self.assertEqual(card_rec.card_name, "Test Card")
        self.assertEqual(card_rec.bank_name, "Test Bank")
        self.assertEqual(card_rec.discount_value, 10.0)
        self.assertEqual(card_rec.savings_amount, 20.0)
        self.assertEqual(card_rec.final_amount, 180.0)
        self.assertFalse(card_rec.is_existing_card)


if __name__ == '__main__':
    unittest.main() 