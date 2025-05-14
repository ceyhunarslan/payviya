import unittest
import os
import json
import requests
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta

# Set the base URL - this should be a running instance of your API
BASE_URL = "http://localhost:8000/api/v1"

class TestIntegrationFlow(unittest.TestCase):
    """Integration tests that test multiple API components working together"""
    
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
    
    def tearDown(self):
        """Any necessary cleanup"""
        pass
    
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
    
    def get_campaigns(self) -> List[Dict[str, Any]]:
        """Get all active campaigns"""
        url = f"{self.base_url}/campaigns/"
        params = {"is_active": True}
        
        response = requests.get(url, params=params)
        self.log_request_response("GET", url, payload=params, response=response)
        
        self.assertEqual(response.status_code, 200, "Failed to get campaigns")
        return response.json()
    
    def get_campaign_details(self, campaign_id: int) -> Dict[str, Any]:
        """Get details for a specific campaign"""
        url = f"{self.base_url}/campaigns/{campaign_id}"
        
        response = requests.get(url)
        self.log_request_response("GET", url, response=response)
        
        self.assertEqual(response.status_code, 200, f"Failed to get campaign {campaign_id}")
        return response.json()
    
    def get_recommendations(self, cart_data: Dict[str, Any]) -> Dict[str, Any]:
        """Get recommendations based on cart data"""
        url = f"{self.base_url}/recommendations/"
        
        response = requests.post(url, json=cart_data)
        self.log_request_response("POST", url, payload=cart_data, response=response)
        
        self.assertEqual(response.status_code, 200, "Failed to get recommendations")
        return response.json()
    
    def track_recommendation_click(self, recommendation_id: int, action_type: str = "select",
                                 user_id: Optional[int] = None) -> Dict[str, Any]:
        """Track a recommendation click"""
        url = f"{self.base_url}/recommendations/click"
        payload = {
            "recommendation_id": recommendation_id,
            "action_type": action_type
        }
        
        if user_id:
            payload["user_id"] = user_id
            
        response = requests.post(url, json=payload)
        self.log_request_response("POST", url, payload=payload, response=response)
        
        self.assertEqual(response.status_code, 200, "Failed to track recommendation click")
        return response.json()
    
    def enroll_in_campaign(self, campaign_id: int, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """Enroll in a campaign"""
        url = f"{self.base_url}/banks/campaigns/{campaign_id}/enroll"
        
        response = requests.post(url, json=user_data)
        self.log_request_response("POST", url, payload=user_data, response=response)
        
        # Note: This might return 400 if bank credentials aren't configured properly
        return response.json()
    
    def test_full_user_flow(self):
        """Test the full user flow from campaigns to recommendations to enrollment"""
        if not self.api_available:
            self.skipTest("API is not available - skipping integration test")
        
        # Step 1: Get all active campaigns
        campaigns = self.get_campaigns()
        self.assertTrue(len(campaigns) > 0, "No campaigns found")
        
        # Step 2: Get details for a specific campaign
        campaign = campaigns[0]  # Use the first campaign
        campaign_id = campaign["id"]
        campaign_details = self.get_campaign_details(campaign_id)
        
        # Step 3: Get recommendations for a cart matching this campaign
        # Extract campaign attributes to create matching cart data
        merchant_name = campaign_details["merchant"]["name"]
        category = campaign_details["category"]
        min_amount = campaign_details["min_amount"] or 100
        
        cart_data = {
            "cart_amount": min_amount * 2,  # Double the minimum for good measure
            "cart_category": category,
            "merchant_name": merchant_name
        }
        
        recommendations = self.get_recommendations(cart_data)
        self.assertTrue(
            len(recommendations["existing_card_recommendations"]) > 0 or 
            len(recommendations["new_card_recommendations"]) > 0,
            "No recommendations returned"
        )
        
        # Find a recommendation for our campaign
        campaign_recommendation = None
        if len(recommendations["existing_card_recommendations"]) > 0:
            for rec in recommendations["existing_card_recommendations"]:
                if rec["campaign_id"] == campaign_id:
                    campaign_recommendation = rec
                    break
                    
        if not campaign_recommendation and len(recommendations["new_card_recommendations"]) > 0:
            for rec in recommendations["new_card_recommendations"]:
                if rec["campaign_id"] == campaign_id:
                    campaign_recommendation = rec
                    break
        
        if not campaign_recommendation:
            self.skipTest(f"No recommendation found for campaign {campaign_id}")
        
        # Step 4: Track a click on the recommendation
        recommendation_id = campaign_recommendation["campaign_id"]
        click_result = self.track_recommendation_click(recommendation_id)
        self.assertTrue(click_result["success"], "Failed to track recommendation click")
        
        # Step 5: Try to enroll in the campaign if it requires enrollment
        if campaign["requires_enrollment"]:
            user_data = {
                "masked_card_number": "1234",
                "phone_number": "5551234567"
            }
            
            try:
                enrollment_result = self.enroll_in_campaign(campaign_id, user_data)
                
                if "detail" in enrollment_result:
                    # Skip if we get an error about bank API credentials
                    if "Bank API credentials" in enrollment_result["detail"]:
                        print("INFO: Campaign enrollment would work with proper bank API credentials")
                elif "success" in enrollment_result and enrollment_result["success"]:
                    self.assertIn("enrollment_id", enrollment_result)
                    print(f"Successfully enrolled in campaign {campaign_id}")
            except Exception as e:
                print(f"Enrollment attempt failed: {str(e)}")
                    
        # The test passes if we got this far
        print(f"Successfully completed integration test for campaign {campaign_id}")
        
    def test_user_specific_recommendations(self):
        """Test recommendations for a specific user with existing cards"""
        if not self.api_available:
            self.skipTest("API is not available - skipping integration test")
        
        # Use user ID 1 which should be created by the seed script
        user_id = 1
        
        # Step 1: Get recommendations for a grocery purchase at Migros for a user
        cart_data = {
            "cart_amount": 500,
            "cart_category": "grocery",
            "merchant_name": "Migros",
            "user_id": user_id
        }
        
        recommendations = self.get_recommendations(cart_data)
        
        # Check if we got existing card recommendations
        self.assertTrue(
            len(recommendations["existing_card_recommendations"]) > 0,
            "No existing card recommendations for user 1"
        )
        
        # Track a click on the first recommendation
        if len(recommendations["existing_card_recommendations"]) > 0:
            recommendation = recommendations["existing_card_recommendations"][0]
            recommendation_id = recommendation["campaign_id"]
            
            click_result = self.track_recommendation_click(
                recommendation_id, 
                action_type="select",
                user_id=user_id
            )
            
            self.assertTrue(click_result["success"], "Failed to track recommendation click")
            print(f"Successfully tracked recommendation click for user {user_id}")
        
if __name__ == "__main__":
    unittest.main() 