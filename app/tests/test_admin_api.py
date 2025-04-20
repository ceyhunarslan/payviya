import unittest
import requests
import json
from typing import Dict, Any, List

BASE_URL = "http://localhost:8000/api/v1"

class TestAdminAPI(unittest.TestCase):
    def setUp(self):
        self.base_url = BASE_URL
        self.verbose = True  # Set to True to see request-response details
    
    # Bank API methods
    def list_banks(self, skip=0, limit=100) -> List[Dict[str, Any]]:
        """List all banks"""
        url = f"{self.base_url}/admin/banks"
        
        params = {
            "skip": skip,
            "limit": limit
        }
        
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
    
    def create_bank(self, bank_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new bank"""
        url = f"{self.base_url}/admin/banks"
        
        if self.verbose:
            print("\n=== REQUEST ===")
            print(f"URL: {url}")
            print(f"Method: POST")
            print(f"Payload: {json.dumps(bank_data, indent=2)}")
        
        response = requests.post(url, json=bank_data)
        
        if self.verbose:
            print("\n=== RESPONSE ===")
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return response.json()
    
    # Credit Card API methods
    def list_credit_cards(self, bank_id=None, skip=0, limit=100) -> List[Dict[str, Any]]:
        """List all credit cards, optionally filtered by bank"""
        url = f"{self.base_url}/admin/credit-cards"
        
        params = {
            "bank_id": bank_id,
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
    
    def create_credit_card(self, card_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new credit card"""
        url = f"{self.base_url}/admin/credit-cards"
        
        if self.verbose:
            print("\n=== REQUEST ===")
            print(f"URL: {url}")
            print(f"Method: POST")
            print(f"Payload: {json.dumps(card_data, indent=2)}")
        
        response = requests.post(url, json=card_data)
        
        if self.verbose:
            print("\n=== RESPONSE ===")
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return response.json()
    
    # Merchant API methods
    def list_merchants(self, skip=0, limit=100) -> List[Dict[str, Any]]:
        """List all merchants"""
        url = f"{self.base_url}/admin/merchants"
        
        params = {
            "skip": skip,
            "limit": limit
        }
        
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
    
    def create_merchant(self, merchant_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new merchant"""
        url = f"{self.base_url}/admin/merchants"
        
        if self.verbose:
            print("\n=== REQUEST ===")
            print(f"URL: {url}")
            print(f"Method: POST")
            print(f"Payload: {json.dumps(merchant_data, indent=2)}")
        
        response = requests.post(url, json=merchant_data)
        
        if self.verbose:
            print("\n=== RESPONSE ===")
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return response.json()
    
    # Analytics API methods
    def get_recommendation_stats(self, days=30) -> Dict[str, Any]:
        """Get recommendation statistics"""
        url = f"{self.base_url}/admin/analytics/recommendations"
        
        params = {
            "days": days
        }
        
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
    
    def get_campaign_stats(self, days=30) -> Dict[str, Any]:
        """Get campaign performance statistics"""
        url = f"{self.base_url}/admin/analytics/campaigns"
        
        params = {
            "days": days
        }
        
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
    
    # Test methods
    def test_list_banks(self):
        """Test listing all banks"""
        result = self.list_banks()
        
        # Verify response structure
        self.assertIsInstance(result, list)
        
        # If there are banks, check their structure
        if result:
            bank = result[0]
            self.assertIn("id", bank)
            self.assertIn("name", bank)
    
    def test_list_credit_cards(self):
        """Test listing all credit cards"""
        result = self.list_credit_cards()
        
        # Verify response structure
        self.assertIsInstance(result, list)
        
        # If there are credit cards, check their structure
        if result:
            card = result[0]
            self.assertIn("id", card)
            self.assertIn("name", card)
            self.assertIn("bank_id", card)
    
    def test_list_merchants(self):
        """Test listing all merchants"""
        result = self.list_merchants()
        
        # Verify response structure
        self.assertIsInstance(result, list)
        
        # If there are merchants, check their structure
        if result:
            merchant = result[0]
            self.assertIn("id", merchant)
            self.assertIn("name", merchant)
    
    def test_get_recommendation_stats(self):
        """Test getting recommendation statistics"""
        result = self.get_recommendation_stats(days=30)
        
        # Verify response structure
        self.assertIn("period_days", result)
        self.assertEqual(result["period_days"], 30)
        
        self.assertIn("total_recommendations", result)
        self.assertIn("total_clicks", result)
        self.assertIn("conversion_rate", result)
        self.assertIn("clicks_by_type", result)
    
    def test_get_campaign_stats(self):
        """Test getting campaign statistics"""
        result = self.get_campaign_stats(days=30)
        
        # Verify response structure
        self.assertIn("period_days", result)
        
        # Other fields may be empty arrays if no data, but should exist
        self.assertIn("campaigns", result)

if __name__ == "__main__":
    unittest.main() 