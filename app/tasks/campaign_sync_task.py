import asyncio
import logging
from datetime import datetime
from typing import Dict, Any
import time
import traceback

from app.db.base import SessionLocal
from app.services.campaign_sync_service import CampaignSyncService

logger = logging.getLogger(__name__)

async def sync_campaigns() -> Dict[str, Any]:
    """
    Task to sync campaigns from all configured banks
    This can be scheduled to run periodically
    """
    logger.info("Starting campaign sync task")
    start_time = time.time()
    
    db = SessionLocal()
    try:
        campaign_sync_service = CampaignSyncService(db)
        
        # Perform the sync
        result = await campaign_sync_service.sync_all_banks()
        
        # Log the result
        execution_time = time.time() - start_time
        logger.info(
            f"Campaign sync completed in {execution_time:.2f}s. "
            f"Synced {result['synced_banks']} banks, "
            f"{result['total_campaigns']} campaigns. "
            f"Failed banks: {len(result.get('failed_banks', []))}"
        )
        
        if result.get('failed_banks'):
            for failed_bank in result['failed_banks']:
                logger.error(
                    f"Failed to sync campaigns for bank {failed_bank['bank_name']} (ID: {failed_bank['bank_id']}): "
                    f"{failed_bank['error']}"
                )
        
        return result
        
    except Exception as e:
        logger.error(f"Error in campaign sync task: {str(e)}")
        logger.error(traceback.format_exc())
        return {
            "success": False,
            "message": f"Error in campaign sync task: {str(e)}"
        }
    finally:
        db.close()

def schedule_campaign_sync(scheduler):
    """
    Schedule the campaign sync task to run periodically
    
    Parameters:
    - scheduler: APScheduler instance
    """
    # Schedule to run every day at 2:00 AM
    scheduler.add_job(
        sync_campaigns,
        'cron',
        hour=2,
        minute=0,
        id='sync_campaigns',
        replace_existing=True
    )
    
    logger.info("Campaign sync task scheduled to run daily at 2:00 AM")
    
    # Run the job immediately as well, but don't use a persistent job ID 
    # to avoid issues when shutting down
    scheduler.add_job(
        sync_campaigns,
        'date',
        run_date=datetime.now(),
        id='sync_campaigns_startup',
    )
    
    # After the job runs once, it is automatically removed from the job store
    # so there's no need to call remove_job on shutdown
    
    logger.info("Campaign sync task scheduled to run on startup") 