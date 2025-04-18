import unittest
import requests
import json
from typing import Dict, Any

BASE_URL = "http://localhost:8000/api/v1"

class TestCampaignAPI(unittest.TestCase):
    def setUp(self):
        self.base_url = BASE_URL
        self.verbose = True  # Set to True to see request-response details
        
    def list_campaigns(self, bank_id=None, card_id=None, category=None, 
                      is_active=True, skip=0, limit=100) -> Dict[str, Any]:
        """Get a list of campaigns with optional filters"""
        url = f"{self.base_url}/campaigns/"
        
        params = {
            "bank_id": bank_id,
            "card_id": card_id,
            "category": category,
            "is_active": is_active,
            "skip": skip,
            "limit": limit
        }
        
        # Remove None values
        params = {k: v for k, v in params.items() if v is not None}
        
        if self.verbose:
            print("\n=== REQUEST ===")
            print(f"URL: {url}")
            print(f"Method: GET")
            print(f"Params: {json.dumps(params, indent=2)}")
        
        response = requests.get(url, params=params)
        
        if self.verbose:
            print("\n=== RESPONSE ===")
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return response.json()
    
    def get_campaign(self, campaign_id: int) -> Dict[str, Any]:
        """Get details of a specific campaign"""
        url = f"{self.base_url}/campaigns/{campaign_id}"
        
        if self.verbose:
            print("\n=== REQUEST ===")
            print(f"URL: {url}")
            print(f"Method: GET")
        
        response = requests.get(url)
        
        if self.verbose:
            print("\n=== RESPONSE ===")
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return response.json()
    
    def create_campaign(self, campaign_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new campaign"""
        url = f"{self.base_url}/campaigns/"
        
        if self.verbose:
            print("\n=== REQUEST ===")
            print(f"URL: {url}")
            print(f"Method: POST")
            print(f"Payload: {json.dumps(campaign_data, indent=2)}")
        
        response = requests.post(url, json=campaign_data)
        
        if self.verbose:
            print("\n=== RESPONSE ===")
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return response.json()
    
    def update_campaign(self, campaign_id: int, 
                       update_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update an existing campaign"""
        url = f"{self.base_url}/campaigns/{campaign_id}"
        
        if self.verbose:
            print("\n=== REQUEST ===")
            print(f"URL: {url}")
            print(f"Method: PUT")
            print(f"Payload: {json.dumps(update_data, indent=2)}")
        
        response = requests.put(url, json=update_data)
        
        if self.verbose:
            print("\n=== RESPONSE ===")
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return response.json()
    
    def delete_campaign(self, campaign_id: int) -> Dict[str, Any]:
        """Delete (deactivate) a campaign"""
        url = f"{self.base_url}/campaigns/{campaign_id}"
        
        if self.verbose:
            print("\n=== REQUEST ===")
            print(f"URL: {url}")
            print(f"Method: DELETE")
        
        response = requests.delete(url)
        
        if self.verbose:
            print("\n=== RESPONSE ===")
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return response.json()
    
    def test_list_campaigns(self):
        """Test getting a list of campaigns"""
        result = self.list_campaigns()
        
        # Verify response structure
        self.assertIsInstance(result, list)
        
        # If there are campaigns, check their structure
        if result:
            campaign = result[0]
            self.assertIn("id", campaign)
            self.assertIn("name", campaign)
            self.assertIn("bank_id", campaign)
            self.assertIn("card_id", campaign)
            self.assertIn("discount_type", campaign)
            self.assertIn("discount_value", campaign)
    
    def test_get_campaign(self):
        """Test getting a specific campaign - requires an existing campaign ID"""
        # First, get a list of campaigns to find an ID to use
        campaigns = self.list_campaigns()
        
        # Skip test if no campaigns exist
        if not campaigns:
            self.skipTest("No campaigns available to test with")
        
        # Get the first campaign's ID
        campaign_id = campaigns[0]["id"]
        
        # Get the specific campaign
        result = self.get_campaign(campaign_id)
        
        # Verify response
        self.assertEqual(result["id"], campaign_id)
        self.assertIn("name", result)
        self.assertIn("bank", result)
        self.assertIn("credit_card", result)
        
        # Check that related objects are included
        self.assertIn("name", result["bank"])
        self.assertIn("name", result["credit_card"])

if __name__ == "__main__":
    unittest.main() 