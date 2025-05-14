import unittest
import requests
import json
from typing import Dict, Any

BASE_URL = "http://localhost:8000/api/v1"

class TestRecommendationAPI(unittest.TestCase):
    def setUp(self):
        self.base_url = BASE_URL
        self.verbose = True  # Set to True to see request-response details
        
    def get_recommendations(self, cart_amount: float, cart_category: str, 
                           merchant_name: str = None, user_id: int = None, 
                           session_id: str = None) -> Dict[str, Any]:
        """Get card recommendations based on cart data"""
        url = f"{self.base_url}/recommendations/"
        
        payload = {
            "cart_amount": cart_amount,
            "cart_category": cart_category,
            "merchant_name": merchant_name,
            "user_id": user_id,
            "session_id": session_id
        }
        
        # Remove None values
        payload = {k: v for k, v in payload.items() if v is not None}
        
        if self.verbose:
            print("\n=== REQUEST ===")
            print(f"URL: {url}")
            print(f"Method: POST")
            print(f"Payload: {json.dumps(payload, indent=2)}")
        
        response = requests.post(url, json=payload)
        
        if self.verbose:
            print("\n=== RESPONSE ===")
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return response.json()

    def track_recommendation_click(self, recommendation_id: int, action_type: str,
                                  user_id: int = None, session_id: str = None) -> Dict[str, Any]:
        """Track a click on a recommendation"""
        url = f"{self.base_url}/recommendations/click"
        
        payload = {
            "recommendation_id": recommendation_id,
            "action_type": action_type,
            "user_id": user_id,
            "session_id": session_id
        }
        
        # Remove None values
        payload = {k: v for k, v in payload.items() if v is not None}
        
        if self.verbose:
            print("\n=== REQUEST ===")
            print(f"URL: {url}")
            print(f"Method: POST")
            print(f"Payload: {json.dumps(payload, indent=2)}")
        
        response = requests.post(url, json=payload)
        
        if self.verbose:
            print("\n=== RESPONSE ===")
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return response.json()
    
    def test_grocery_recommendation(self):
        """Test recommendation for grocery shopping"""
        result = self.get_recommendations(
            cart_amount=500,
            cart_category="grocery",
            merchant_name="Migros",
            user_id=1
        )
        
        # Verify the API response structure
        self.assertIn("request_id", result)
        self.assertIn("cart_amount", result)
        self.assertIn("cart_category", result)
        
        # Check if we have recommendations
        existing_recs = result.get("existing_card_recommendations", [])
        new_recs = result.get("new_card_recommendations", [])
        
        # Assert we have at least some recommendations
        self.assertTrue(len(existing_recs) > 0 or len(new_recs) > 0, 
                       "No recommendations returned for grocery category")
        
        # If there are recommendations, verify their structure and test clicking on one
        recommendations = existing_recs + new_recs
        
        if recommendations:
            rec = recommendations[0]
            # Verify recommendation structure
            self.assertIn("card_name", rec)
            self.assertIn("bank_name", rec)
            self.assertIn("discount_value", rec)
            self.assertIn("savings_amount", rec)
            
            # Use campaign_id for the recommendation click tracking
            # Since we don't have recommendation_id in the response
            if "campaign_id" in rec:
                click_result = self.track_recommendation_click(
                    recommendation_id=rec["campaign_id"],
                    action_type="select",
                    user_id=1
                )
                self.assertIn("success", click_result)

    def test_electronics_recommendation(self):
        """Test recommendation for electronics shopping"""
        result = self.get_recommendations(
            cart_amount=2000,
            cart_category="electronics",
            merchant_name="Amazon"
        )
        
        self.assertIn("request_id", result)
        self.assertIn("cart_amount", result)
        self.assertEqual(result["cart_amount"], 2000)
        self.assertEqual(result["cart_category"], "electronics")
        
        # Check recommendations
        existing_recs = result.get("existing_card_recommendations", [])
        new_recs = result.get("new_card_recommendations", [])
        
        # Verify recommendations if any
        recommendations = existing_recs + new_recs
        if recommendations:
            for rec in recommendations:
                self.assertIn("discount_value", rec)
                self.assertIn("savings_amount", rec)
                self.assertIn("final_amount", rec)

    def test_travel_recommendation(self):
        """Test recommendation for travel purchase"""
        result = self.get_recommendations(
            cart_amount=5000,
            cart_category="travel",
            merchant_name="Turkish Airlines"
        )
        
        self.assertIn("request_id", result)
        self.assertIn("cart_amount", result)
        self.assertEqual(result["cart_amount"], 5000)
        self.assertEqual(result["cart_category"], "travel")
        
        # Check recommendations
        existing_recs = result.get("existing_card_recommendations", [])
        new_recs = result.get("new_card_recommendations", [])
        
        # Verify recommendations if any
        recommendations = existing_recs + new_recs
        if recommendations:
            for rec in recommendations:
                self.assertIn("card_name", rec)
                self.assertIn("bank_name", rec)
                self.assertIn("discount_type", rec)

    def test_fuel_recommendation(self):
        """Test recommendation for fuel purchase"""
        result = self.get_recommendations(
            cart_amount=300,
            cart_category="fuel",
            merchant_name="Shell"
        )
        
        self.assertIn("request_id", result)
        self.assertIn("cart_amount", result)
        self.assertEqual(result["cart_amount"], 300)
        self.assertEqual(result["cart_category"], "fuel")
        
        # Check recommendations
        existing_recs = result.get("existing_card_recommendations", [])
        new_recs = result.get("new_card_recommendations", [])
        
        # Verify recommendations if any
        recommendations = existing_recs + new_recs
        if recommendations:
            for rec in recommendations:
                self.assertIn("is_existing_card", rec)
                if rec["is_existing_card"]:
                    self.assertIn("card_name", rec)
                else:
                    self.assertIn("application_url", rec)

if __name__ == "__main__":
    unittest.main() 