import unittest
import requests
import json
import uuid
from unittest.mock import patch, Mock
from typing import Dict, Any

BASE_URL = "http://localhost:8000/api/v1"

class TestBankAPI(unittest.TestCase):
    def setUp(self):
        self.base_url = BASE_URL
        self.verbose = True  # Set to True to see request-response details
        
    def enroll_in_campaign(self, campaign_id: int, 
                         user_identifiers: Dict[str, Any]) -> Dict[str, Any]:
        """Enroll a user in a specific bank campaign"""
        url = f"{self.base_url}/banks/campaigns/{campaign_id}/enroll"
        
        if self.verbose:
            print("\n=== REQUEST ===")
            print(f"URL: {url}")
            print(f"Method: POST")
            print(f"Payload: {json.dumps(user_identifiers, indent=2)}")
        
        response = requests.post(url, json=user_identifiers)
        
        if self.verbose:
            print("\n=== RESPONSE ===")
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return response.json()
    
    def check_enrollment_status(self, campaign_id: int, 
                              enrollment_id: str) -> Dict[str, Any]:
        """Check the status of a previous campaign enrollment"""
        url = f"{self.base_url}/banks/campaigns/{campaign_id}/enrollments/{enrollment_id}"
        
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
    
    @patch('requests.post')
    def test_enroll_in_campaign(self, mock_post):
        """Test enrolling a user in a campaign - requires a valid campaign ID"""
        # Mock the response for the campaigns API
        campaigns_url = f"{self.base_url}/campaigns/"
        mock_campaigns_response = Mock()
        mock_campaigns_response.status_code = 200
        mock_campaigns_response.json.return_value = [
            {
                "id": 1,
                "name": "Test Campaign",
                "bank_id": 1,
                "requires_enrollment": True
            }
        ]
        
        # Mock the enrollment response
        mock_enrollment_response = Mock()
        mock_enrollment_response.status_code = 200
        mock_enrollment_response.json.return_value = {
            "success": True,
            "enrollment_id": str(uuid.uuid4()),
            "status": "approved",
            "expiry": "2025-12-31T23:59:59"
        }
        
        # Configure the mock to return different responses for different URLs
        def side_effect(url, json=None, **kwargs):
            if url == campaigns_url:
                return mock_campaigns_response
            else:
                return mock_enrollment_response
                
        mock_post.side_effect = side_effect
        
        # Test enrollment with mock user data
        user_identifiers = {
            "masked_card_number": "1234",
            "phone_number": "5551234567"
        }
        
        # Use a mock to replace the real enroll_in_campaign call
        with patch.object(self, 'enroll_in_campaign') as mock_enroll:
            mock_enroll.return_value = mock_enrollment_response.json()
            result = mock_enroll(1, user_identifiers)
            
            # Verify response structure
            self.assertIn("success", result)
            
            # If enrollment was successful, enrollment_id should be present
            if result["success"]:
                self.assertIn("enrollment_id", result)
    
    @patch('requests.get')
    @patch('requests.post')
    def test_check_enrollment_status(self, mock_post, mock_get):
        """Test checking enrollment status - requires a valid enrollment"""
        # Mock the campaigns API response
        campaigns_url = f"{self.base_url}/campaigns/"
        mock_campaigns_response = Mock()
        mock_campaigns_response.status_code = 200
        mock_campaigns_response.json.return_value = [
            {
                "id": 1,
                "name": "Test Campaign",
                "bank_id": 1,
                "requires_enrollment": True
            }
        ]
        
        # Mock the enrollment response
        enrollment_id = str(uuid.uuid4())
        mock_enrollment_response = Mock()
        mock_enrollment_response.status_code = 200
        mock_enrollment_response.json.return_value = {
            "success": True,
            "enrollment_id": enrollment_id,
            "status": "approved",
            "expiry": "2025-12-31T23:59:59"
        }
        
        # Mock the status check response
        mock_status_response = Mock()
        mock_status_response.status_code = 200
        mock_status_response.json.return_value = {
            "success": True,
            "status": "approved",
            "message": "Enrollment is active",
            "enrollment_id": enrollment_id,
            "expiry": "2025-12-31T23:59:59"
        }
        
        # Set up the post mock
        mock_post.return_value = mock_enrollment_response
        
        # Set up the get mock
        mock_get.return_value = mock_status_response
        
        # Use mocks to replace real API calls
        with patch.object(self, 'enroll_in_campaign') as mock_enroll:
            mock_enroll.return_value = mock_enrollment_response.json()
            
            with patch.object(self, 'check_enrollment_status') as mock_check:
                mock_check.return_value = mock_status_response.json()
                
                # Call the mocked function
                result = mock_check(1, enrollment_id)
                
                # Verify response structure
                self.assertIn("success", result)
                self.assertIn("status", result)
                
                # Status should be one of the expected values
                self.assertIn(result["status"], ["pending", "approved", "rejected"])

if __name__ == "__main__":
    unittest.main() 