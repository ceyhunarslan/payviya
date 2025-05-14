import logging
import asyncio
from datetime import datetime
from typing import Dict, Any, List, Optional
import aiohttp
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_

from app.models.campaign import Bank, Campaign, CampaignSource, CampaignStatus
from app.utils.crypto import decrypt_data

logger = logging.getLogger(__name__)


class CampaignSyncService:
    """Service for syncing campaigns from bank APIs and managing the approval process"""
    
    def __init__(self, db: Session):
        self.db = db
    
    async def sync_all_banks(self) -> Dict[str, Any]:
        """Sync campaigns from all banks that have campaign_sync_enabled"""
        
        banks = self.db.query(Bank).filter(Bank.campaign_sync_enabled == True).all()
        if not banks:
            return {
                "success": True,
                "message": "No banks configured for campaign syncing",
                "synced_banks": 0,
                "total_campaigns": 0
            }
        
        total_campaigns = 0
        synced_banks = 0
        failed_banks = []
        
        for bank in banks:
            try:
                result = await self.sync_bank_campaigns(bank.id)
                if result["success"]:
                    total_campaigns += result["imported_campaigns"]
                    synced_banks += 1
                else:
                    failed_banks.append({
                        "bank_id": bank.id,
                        "bank_name": bank.name,
                        "error": result["message"]
                    })
            except Exception as e:
                logger.error(f"Error syncing campaigns for bank {bank.name}: {str(e)}")
                failed_banks.append({
                    "bank_id": bank.id,
                    "bank_name": bank.name,
                    "error": str(e)
                })
        
        return {
            "success": True,
            "message": f"Synced campaigns from {synced_banks} banks",
            "synced_banks": synced_banks,
            "failed_banks": failed_banks,
            "total_campaigns": total_campaigns
        }
    
    async def sync_bank_campaigns(self, bank_id: int) -> Dict[str, Any]:
        """
        Sync campaigns from a specific bank's API
        
        Parameters:
        - bank_id: The ID of the bank to sync campaigns from
        
        Returns:
        - Dictionary with sync status and details
        """
        # Get bank details
        bank = self.db.query(Bank).filter(Bank.id == bank_id).first()
        if not bank:
            return {
                "success": False,
                "message": "Bank not found"
            }
        
        if not bank.campaign_sync_enabled or not bank.campaign_sync_endpoint:
            return {
                "success": False,
                "message": "Campaign sync not enabled for this bank"
            }
        
        # Decrypt API credentials
        api_key = decrypt_data(bank.api_key) if bank.api_key else None
        api_secret = decrypt_data(bank.api_secret) if bank.api_secret else None
        
        if not api_key or not api_secret:
            return {
                "success": False,
                "message": "Bank API credentials not configured"
            }
        
        # Call bank API to get campaigns
        try:
            campaigns = await self._call_bank_api(
                bank=bank,
                endpoint=bank.campaign_sync_endpoint,
                method="GET",
                data=None,
                api_key=api_key,
                api_secret=api_secret
            )
            
            if not campaigns or not isinstance(campaigns, list):
                return {
                    "success": False,
                    "message": "Invalid campaign data format from bank API"
                }
            
            # Process the imported campaigns
            import_result = await self._process_imported_campaigns(
                bank_id=bank.id,
                campaigns=campaigns,
                auto_approve=bank.auto_approve_campaigns
            )
            
            # Update the last sync time
            bank.last_campaign_sync_at = datetime.now()
            self.db.commit()
            
            return {
                "success": True,
                "message": f"Successfully synced {import_result['imported_campaigns']} campaigns",
                "imported_campaigns": import_result["imported_campaigns"],
                "updated_campaigns": import_result["updated_campaigns"],
                "new_campaigns": import_result["new_campaigns"],
                "pending_approval": import_result["pending_approval"],
                "auto_approved": import_result["auto_approved"]
            }
            
        except Exception as e:
            logger.error(f"Error syncing campaigns from bank {bank.name}: {str(e)}")
            return {
                "success": False,
                "message": f"Sync failed: {str(e)}"
            }
    
    async def _process_imported_campaigns(
        self,
        bank_id: int,
        campaigns: List[Dict[str, Any]],
        auto_approve: bool = False
    ) -> Dict[str, int]:
        """
        Process imported campaigns from a bank API
        
        Parameters:
        - bank_id: The bank ID these campaigns belong to
        - campaigns: List of campaign data from the bank API
        - auto_approve: Whether to automatically approve campaigns
        
        Returns:
        - Stats about processed campaigns
        """
        imported_campaigns = 0
        updated_campaigns = 0
        new_campaigns = 0
        pending_approval = 0
        auto_approved = 0
        
        for campaign_data in campaigns:
            external_id = campaign_data.get("external_id") or campaign_data.get("id")
            
            if not external_id:
                logger.warning("Campaign without external ID, skipping")
                continue
            
            # Check if this campaign already exists
            existing_campaign = self.db.query(Campaign).filter(
                and_(
                    Campaign.bank_id == bank_id,
                    Campaign.external_id == str(external_id),
                    Campaign.source == CampaignSource.BANK_API
                )
            ).first()
            
            if existing_campaign:
                # Update existing campaign
                self._update_campaign_from_data(existing_campaign, campaign_data)
                updated_campaigns += 1
            else:
                # Create new campaign
                new_campaign = self._create_campaign_from_data(bank_id, campaign_data)
                
                if auto_approve:
                    new_campaign.status = CampaignStatus.APPROVED
                    auto_approved += 1
                else:
                    new_campaign.status = CampaignStatus.PENDING
                    pending_approval += 1
                
                self.db.add(new_campaign)
                new_campaigns += 1
            
            imported_campaigns += 1
        
        self.db.commit()
        
        return {
            "imported_campaigns": imported_campaigns,
            "updated_campaigns": updated_campaigns,
            "new_campaigns": new_campaigns,
            "pending_approval": pending_approval,
            "auto_approved": auto_approved
        }
    
    def _create_campaign_from_data(
        self,
        bank_id: int,
        campaign_data: Dict[str, Any]
    ) -> Campaign:
        """Create a new Campaign object from imported data"""
        
        # Map external category to internal category
        category = self._map_external_category(campaign_data.get("category", "other"))
        
        # Map external discount type to internal discount type
        discount_type = self._map_external_discount_type(campaign_data.get("discount_type", "percentage"))
        
        # Create new campaign
        campaign = Campaign(
            name=campaign_data.get("name", "Unnamed Campaign"),
            description=campaign_data.get("description", ""),
            bank_id=bank_id,
            card_id=campaign_data.get("card_id"),  # May need to map from external ID
            category=category,
            discount_type=discount_type,
            discount_value=float(campaign_data.get("discount_value", 0)),
            min_amount=float(campaign_data.get("min_amount", 0)),
            max_discount=float(campaign_data.get("max_discount")) if campaign_data.get("max_discount") else None,
            start_date=self._parse_date(campaign_data.get("start_date")),
            end_date=self._parse_date(campaign_data.get("end_date")),
            merchant_id=campaign_data.get("merchant_id"),  # May need to map from external ID
            is_active=campaign_data.get("is_active", True),
            requires_enrollment=campaign_data.get("requires_enrollment", False),
            enrollment_url=campaign_data.get("enrollment_url"),
            source=CampaignSource.BANK_API,
            external_id=str(campaign_data.get("external_id") or campaign_data.get("id")),
            last_sync_at=datetime.now()
        )
        
        return campaign
    
    def _update_campaign_from_data(
        self,
        campaign: Campaign,
        campaign_data: Dict[str, Any]
    ) -> None:
        """Update an existing Campaign object from imported data"""
        
        # Only update if the campaign is not edited manually
        # If it's pending or approved, update it
        if campaign.status in [CampaignStatus.PENDING, CampaignStatus.APPROVED]:
            campaign.name = campaign_data.get("name", campaign.name)
            campaign.description = campaign_data.get("description", campaign.description)
            
            # Only update card_id if provided and valid
            if campaign_data.get("card_id"):
                campaign.card_id = campaign_data.get("card_id")
            
            # Map category if provided
            if campaign_data.get("category"):
                campaign.category = self._map_external_category(campaign_data.get("category"))
            
            # Map discount_type if provided
            if campaign_data.get("discount_type"):
                campaign.discount_type = self._map_external_discount_type(campaign_data.get("discount_type"))
            
            # Update numeric values if provided
            if campaign_data.get("discount_value") is not None:
                campaign.discount_value = float(campaign_data.get("discount_value"))
            
            if campaign_data.get("min_amount") is not None:
                campaign.min_amount = float(campaign_data.get("min_amount"))
            
            if campaign_data.get("max_discount") is not None:
                campaign.max_discount = float(campaign_data.get("max_discount"))
            
            # Update dates if provided
            if campaign_data.get("start_date"):
                campaign.start_date = self._parse_date(campaign_data.get("start_date"))
            
            if campaign_data.get("end_date"):
                campaign.end_date = self._parse_date(campaign_data.get("end_date"))
            
            # Update merchant if provided
            if campaign_data.get("merchant_id"):
                campaign.merchant_id = campaign_data.get("merchant_id")
            
            # Update boolean flags if provided
            if campaign_data.get("is_active") is not None:
                campaign.is_active = campaign_data.get("is_active")
            
            if campaign_data.get("requires_enrollment") is not None:
                campaign.requires_enrollment = campaign_data.get("requires_enrollment")
            
            # Update enrollment URL if provided
            if campaign_data.get("enrollment_url"):
                campaign.enrollment_url = campaign_data.get("enrollment_url")
            
            # Update sync time
            campaign.last_sync_at = datetime.now()
    
    def _map_external_category(self, external_category: str) -> str:
        """Map external category to internal category enum"""
        category_map = {
            "electronics": "electronics",
            "electronic": "electronics",
            "tech": "electronics",
            
            "fashion": "fashion",
            "clothing": "fashion",
            "apparel": "fashion",
            
            "grocery": "grocery",
            "supermarket": "grocery",
            "food": "grocery",
            
            "travel": "travel",
            "flight": "travel",
            "hotel": "travel",
            
            "restaurant": "restaurant",
            "dining": "restaurant",
            "cafe": "restaurant",
            
            "fuel": "fuel",
            "gas": "fuel",
            "petrol": "fuel",
            
            "entertainment": "entertainment",
            "movie": "entertainment",
            "game": "entertainment"
        }
        
        normalized = external_category.lower().strip()
        return category_map.get(normalized, "other")
    
    def _map_external_discount_type(self, external_type: str) -> str:
        """Map external discount type to internal discount type enum"""
        type_map = {
            "percentage": "percentage",
            "percent": "percentage",
            "%": "percentage",
            
            "cashback": "cashback",
            "cash_back": "cashback",
            "rebate": "cashback",
            
            "points": "points",
            "point": "points",
            "mile": "points",
            "miles": "points",
            
            "installment": "installment",
            "installments": "installment",
            "payment_plan": "installment"
        }
        
        normalized = external_type.lower().strip()
        return type_map.get(normalized, "percentage")
    
    def _parse_date(self, date_str: Optional[str]) -> datetime:
        """Parse date string from external API into datetime object"""
        if not date_str:
            # Default to current date if not provided
            return datetime.now()
        
        try:
            # Try different date formats
            for fmt in ["%Y-%m-%dT%H:%M:%S", "%Y-%m-%d %H:%M:%S", "%Y-%m-%d"]:
                try:
                    return datetime.strptime(date_str, fmt)
                except ValueError:
                    continue
            
            # If none of the formats work, default to now
            return datetime.now()
        except Exception:
            return datetime.now()
    
    async def _call_bank_api(
        self,
        bank: Bank,
        endpoint: str,
        method: str,
        data: Optional[Dict[str, Any]],
        api_key: str,
        api_secret: str
    ) -> Any:
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
                    
            except Exception as e:
                logger.error(f"Error calling bank API: {str(e)}")
                raise
    
    # Campaign approval methods
    
    def approve_campaign(
        self, 
        campaign_id: int,
        admin_id: int,
        review_notes: Optional[str] = None
    ) -> Dict[str, Any]:
        """Approve a pending campaign"""
        
        campaign = self.db.query(Campaign).filter(Campaign.id == campaign_id).first()
        if not campaign:
            return {
                "success": False,
                "message": "Campaign not found"
            }
        
        if campaign.status != CampaignStatus.PENDING:
            return {
                "success": False,
                "message": f"Campaign is not pending approval (current status: {campaign.status})"
            }
        
        # Update campaign status
        campaign.status = CampaignStatus.APPROVED
        campaign.review_notes = review_notes
        campaign.reviewed_by = admin_id
        campaign.is_active = True
        
        self.db.commit()
        
        return {
            "success": True,
            "message": "Campaign approved successfully",
            "campaign_id": campaign.id
        }
    
    def reject_campaign(
        self, 
        campaign_id: int,
        admin_id: int,
        review_notes: Optional[str] = None
    ) -> Dict[str, Any]:
        """Reject a pending campaign"""
        
        campaign = self.db.query(Campaign).filter(Campaign.id == campaign_id).first()
        if not campaign:
            return {
                "success": False,
                "message": "Campaign not found"
            }
        
        if campaign.status != CampaignStatus.PENDING:
            return {
                "success": False,
                "message": f"Campaign is not pending approval (current status: {campaign.status})"
            }
        
        # Update campaign status
        campaign.status = CampaignStatus.REJECTED
        campaign.review_notes = review_notes
        campaign.reviewed_by = admin_id
        campaign.is_active = False
        
        self.db.commit()
        
        return {
            "success": True,
            "message": "Campaign rejected",
            "campaign_id": campaign.id
        }
    
    def get_pending_campaigns(
        self,
        skip: int = 0,
        limit: int = 100
    ) -> List[Campaign]:
        """Get campaigns that are pending approval"""
        
        return self.db.query(Campaign)\
            .filter(Campaign.status == CampaignStatus.PENDING)\
            .order_by(Campaign.created_at.desc())\
            .offset(skip)\
            .limit(limit)\
            .all() 