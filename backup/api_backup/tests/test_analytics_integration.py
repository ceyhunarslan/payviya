import unittest
import json
import requests
from typing import Dict, Any, Optional

# Set the base URL - this should be a running instance of your API
BASE_URL = "http://localhost:8000/api/v1"

class TestAnalyticsIntegration(unittest.TestCase):
    """Integration tests for analytics endpoints and their interdependence with other API actions"""
    
    def setUp(self):
        """Setup for integration tests - ensures API is running"""
        self.base_url = BASE_URL
        self.verbose = True  # Set to True to see request-response details
        
        # Check if the API is running - if not, skip all tests
        try:
            response = requests.get(f"{self.base_url}/campaigns/")
            self.api_available = response.status_code == 200
        except:
            self.api_available = False
    
    def log_request_response(self, method: str, url: str, 
                            payload: Optional[Dict] = None, 
                            response: Optional[requests.Response] = None):
        """Helper method to log request and response details"""
        if not self.verbose:
            return
            
        print(f"\n=== {method} REQUEST ===")
        print(f"URL: {url}")
        if payload:
            print(f"Payload: {json.dumps(payload, indent=2)}")
        
        if response:
            print(f"\n=== RESPONSE ===")
            print(f"Status Code: {response.status_code}")
            try:
                print(f"Response: {json.dumps(response.json(), indent=2)}")
            except:
                print(f"Response: {response.text}")
    
    def get_campaign_analytics(self, days: int = 30) -> Dict[str, Any]:
        """Get campaign analytics for the specified period"""
        url = f"{self.base_url}/admin/analytics/campaigns"
        params = {"days": days}
        
        response = requests.get(url, params=params)
        self.log_request_response("GET", url, payload=params, response=response)
        
        self.assertEqual(response.status_code, 200, "Failed to get campaign analytics")
        return response.json()
    
    def get_recommendation_analytics(self, days: int = 30) -> Dict[str, Any]:
        """Get recommendation analytics for the specified period"""
        url = f"{self.base_url}/admin/analytics/recommendations"
        params = {"days": days}
        
        response = requests.get(url, params=params)
        self.log_request_response("GET", url, payload=params, response=response)
        
        self.assertEqual(response.status_code, 200, "Failed to get recommendation analytics")
        return response.json()
    
    def generate_recommendation_and_track(self, 
                                        cart_data: Dict[str, Any],
                                        track_click: bool = True) -> Dict[str, Any]:
        """Generate a recommendation and optionally track a click on it"""
        # Get recommendation
        url = f"{self.base_url}/recommendations/"
        response = requests.post(url, json=cart_data)
        self.log_request_response("POST", url, payload=cart_data, response=response)
        
        self.assertEqual(response.status_code, 200, "Failed to get recommendation")
        recommendations = response.json()
        
        # Track a click if requested and if there are recommendations
        if track_click:
            recommendation = None
            if recommendations["existing_card_recommendations"]:
                recommendation = recommendations["existing_card_recommendations"][0]
            elif recommendations["new_card_recommendations"]:
                recommendation = recommendations["new_card_recommendations"][0]
                
            if recommendation:
                click_url = f"{self.base_url}/recommendations/click"
                click_data = {
                    "recommendation_id": recommendation["campaign_id"],
                    "action_type": "select"
                }
                
                if "user_id" in cart_data:
                    click_data["user_id"] = cart_data["user_id"]
                    
                click_response = requests.post(click_url, json=click_data)
                self.log_request_response("POST", click_url, payload=click_data, response=click_response)
                
                self.assertEqual(click_response.status_code, 200, "Failed to track click")
        
        return recommendations
    
    def test_analytics_after_recommendations(self):
        """Test that analytics data updates after making recommendation requests"""
        if not self.api_available:
            self.skipTest("API is not available - skipping integration test")
        
        # Step 1: Get initial analytics data
        initial_campaign_analytics = self.get_campaign_analytics()
        initial_recommendation_analytics = self.get_recommendation_analytics()
        
        # Record the initial counts
        initial_rec_count = initial_recommendation_analytics["total_recommendations"]
        initial_click_count = initial_recommendation_analytics["total_clicks"]
        
        # Step 2: Generate some new recommendations
        cart_data_1 = {
            "cart_amount": 500,
            "cart_category": "electronics",
            "merchant_name": "Amazon"
        }
        
        cart_data_2 = {
            "cart_amount": 300,
            "cart_category": "fuel",
            "merchant_name": "Shell"
        }
        
        # Generate recommendations and track clicks
        self.generate_recommendation_and_track(cart_data_1)
        self.generate_recommendation_and_track(cart_data_2)
        
        # Step 3: Check updated analytics
        updated_campaign_analytics = self.get_campaign_analytics()
        updated_recommendation_analytics = self.get_recommendation_analytics()
        
        # Verify that the counts have increased
        updated_rec_count = updated_recommendation_analytics["total_recommendations"]
        updated_click_count = updated_recommendation_analytics["total_clicks"]
        
        self.assertGreater(updated_rec_count, initial_rec_count, 
                          "Recommendation count didn't increase after new recommendations")
        self.assertGreater(updated_click_count, initial_click_count,
                          "Click count didn't increase after tracking clicks")
        
        # Check that we've increased by 2 recommendations and 2 clicks
        self.assertEqual(updated_rec_count, initial_rec_count + 2,
                        f"Expected {initial_rec_count + 2} recs, got {updated_rec_count}")
        self.assertEqual(updated_click_count, initial_click_count + 2,
                        f"Expected {initial_click_count + 2} clicks, got {updated_click_count}")
        
        print("Successfully verified analytics integration")
    
    def test_campaign_impression_tracking(self):
        """Test that campaign impressions are tracked correctly in analytics"""
        if not self.api_available:
            self.skipTest("API is not available - skipping integration test")
        
        # Step 1: Get initial campaign analytics
        initial_analytics = self.get_campaign_analytics()
        
        # Find a campaign to test with - use Amazon campaign
        campaign_id = 1  # Amazon campaign
        
        # Get its initial impression count
        campaign_data = None
        for campaign in initial_analytics["campaigns"]:
            if campaign["campaign_id"] == campaign_id:
                campaign_data = campaign
                break
                
        if not campaign_data:
            self.skipTest(f"Campaign with ID {campaign_id} not found in analytics")
            
        initial_impressions = campaign_data["impression_count"]
        initial_clicks = campaign_data["click_count"]
        
        # Step 2: Generate new recommendations for this campaign
        cart_data = {
            "cart_amount": 200,
            "cart_category": "electronics",
            "merchant_name": "Amazon"
        }
        
        # Make the recommendation request with click tracking
        self.generate_recommendation_and_track(cart_data)
        
        # Step 3: Check updated campaign analytics
        updated_analytics = self.get_campaign_analytics()
        
        # Find the campaign in the updated data
        updated_campaign_data = None
        for campaign in updated_analytics["campaigns"]:
            if campaign["campaign_id"] == campaign_id:
                updated_campaign_data = campaign
                break
                
        self.assertIsNotNone(updated_campaign_data, f"Campaign with ID {campaign_id} not found in updated analytics")
        
        updated_impressions = updated_campaign_data["impression_count"]
        updated_clicks = updated_campaign_data["click_count"]
        
        # Verify impression and click counts increased
        self.assertGreater(updated_impressions, initial_impressions,
                        f"Expected impressions to increase, but got {initial_impressions} -> {updated_impressions}")
        self.assertGreater(updated_clicks, initial_clicks,
                        f"Expected clicks to increase, but got {initial_clicks} -> {updated_clicks}")
        
        # Verify CTR calculation is reasonable (should be between 0 and 100)
        self.assertGreaterEqual(updated_campaign_data["ctr"], 0,
                            f"CTR should be >= 0, got {updated_campaign_data['ctr']}")
        self.assertLessEqual(updated_campaign_data["ctr"], 100,
                          f"CTR should be <= 100, got {updated_campaign_data['ctr']}")
        
        # Verify CTR calculation is mathematically correct
        expected_ctr = (updated_clicks / updated_impressions) * 100 if updated_impressions > 0 else 0
        self.assertAlmostEqual(updated_campaign_data["ctr"], expected_ctr, 
                              msg=f"Expected CTR of {expected_ctr}, got {updated_campaign_data['ctr']}", 
                              delta=0.1)
        
        print(f"Successfully verified campaign impression tracking for campaign {campaign_id}")

if __name__ == "__main__":
    unittest.main() 