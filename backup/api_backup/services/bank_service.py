import logging
from typing import Dict, Any, Optional
import aiohttp
from aiohttp import ClientError
from sqlalchemy.orm import Session

from app.models.campaign import Bank, Campaign
from app.utils.crypto import encrypt_data, decrypt_data

logger = logging.getLogger(__name__)


class BankService:
    """Service for integrating with bank APIs for campaign enrollment"""
    
    def __init__(self, db: Session):
        self.db = db
    
    async def enroll_in_campaign(
        self,
        campaign_id: int,
        user_identifiers: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Enroll a user in a bank campaign through the bank's API
        
        Parameters:
        - campaign_id: The ID of the campaign to enroll in
        - user_identifiers: Dict containing user identifiers required by the bank
          (may include masked card number, customer ID, phone, etc.)
        
        Returns:
        - Dictionary with enrollment status and details
        """
        # Get campaign and bank details
        campaign = self.db.query(Campaign).filter(Campaign.id == campaign_id).first()
        if not campaign:
            return {
                "success": False,
                "message": "Campaign not found"
            }
        
        # Check if campaign requires enrollment
        if not campaign.requires_enrollment:
            return {
                "success": True,
                "message": "No enrollment required for this campaign"
            }
        
        # Get bank API details
        bank = campaign.bank
        if not bank.api_base_url:
            return {
                "success": False,
                "message": "Bank API integration not available"
            }
        
        # Decrypt API credentials
        api_key = decrypt_data(bank.api_key) if bank.api_key else None
        api_secret = decrypt_data(bank.api_secret) if bank.api_secret else None
        
        if not api_key or not api_secret:
            return {
                "success": False,
                "message": "Bank API credentials not configured"
            }
        
        # Prepare enrollment request
        enrollment_data = {
            "campaign_id": campaign.id,
            "campaign_reference": f"PAYVIYA-{campaign.id}",
            "user_data": user_identifiers
        }
        
        # Call bank API to enroll in the campaign
        try:
            response = await self._call_bank_api(
                bank=bank,
                endpoint="/campaigns/enroll",
                method="POST",
                data=enrollment_data,
                api_key=api_key,
                api_secret=api_secret
            )
            
            return {
                "success": response.get("success", False),
                "message": response.get("message", "Enrollment request processed"),
                "enrollment_id": response.get("enrollment_id"),
                "status": response.get("status"),
                "expiry": response.get("expiry")
            }
            
        except Exception as e:
            logger.error(f"Error during campaign enrollment: {str(e)}")
            return {
                "success": False,
                "message": f"Enrollment failed: {str(e)}"
            }
    
    async def check_enrollment_status(
        self,
        campaign_id: int,
        enrollment_id: str
    ) -> Dict[str, Any]:
        """Check the status of a previous campaign enrollment"""
        
        # Get campaign and bank details
        campaign = self.db.query(Campaign).filter(Campaign.id == campaign_id).first()
        if not campaign:
            return {
                "success": False,
                "message": "Campaign not found"
            }
        
        # Get bank API details
        bank = campaign.bank
        if not bank.api_base_url:
            return {
                "success": False,
                "message": "Bank API integration not available"
            }
        
        # Decrypt API credentials
        api_key = decrypt_data(bank.api_key) if bank.api_key else None
        api_secret = decrypt_data(bank.api_secret) if bank.api_secret else None
        
        if not api_key or not api_secret:
            return {
                "success": False,
                "message": "Bank API credentials not configured"
            }
        
        # Call bank API to check enrollment status
        try:
            response = await self._call_bank_api(
                bank=bank,
                endpoint=f"/campaigns/enrollments/{enrollment_id}",
                method="GET",
                data=None,
                api_key=api_key,
                api_secret=api_secret
            )
            
            return {
                "success": response.get("success", False),
                "status": response.get("status"),
                "message": response.get("message", "Enrollment status checked"),
                "enrollment_id": enrollment_id,
                "expiry": response.get("expiry")
            }
            
        except Exception as e:
            logger.error(f"Error checking enrollment status: {str(e)}")
            return {
                "success": False,
                "message": f"Status check failed: {str(e)}"
            }
    
    async def _call_bank_api(
        self,
        bank: Bank,
        endpoint: str,
        method: str,
        data: Optional[Dict[str, Any]],
        api_key: str,
        api_secret: str
    ) -> Dict[str, Any]:
        """Make an API call to a bank's API endpoint"""
        
        url = f"{bank.api_base_url}{endpoint}"
        headers = {
            "Content-Type": "application/json",
            "X-API-Key": api_key,
            "X-API-Secret": api_secret
        }
        
        async with aiohttp.ClientSession() as session:
            try:
                if method.upper() == "GET":
                    async with session.get(url, headers=headers) as response:
                        response.raise_for_status()
                        return await response.json()
                        
                elif method.upper() == "POST":
                    async with session.post(url, headers=headers, json=data) as response:
                        response.raise_for_status()
                        return await response.json()
                        
                else:
                    raise ValueError(f"Unsupported method: {method}")
                    
            except ClientError as e:
                logger.error(f"Bank API error: {str(e)}")
                raise
            except Exception as e:
                logger.error(f"Error calling bank API: {str(e)}")
                raise 