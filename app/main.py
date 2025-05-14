import logging
import os
import sys
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse, JSONResponse
from fastapi.encoders import jsonable_encoder
from apscheduler.schedulers.background import BackgroundScheduler
from sqlalchemy import text
from app.db.base import SessionLocal
from app.routes import location_routes

# Add the parent directory to path to fix import issues
parent_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(parent_dir))

from app.api.v1.router import api_router
from app.models.campaign import CampaignSource
from app.core.config import settings
from app.tasks.campaign_sync_task import schedule_campaign_sync

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Custom JSON response class with UTF-8 encoding
class UnicodeJSONResponse(JSONResponse):
    media_type = "application/json; charset=utf-8"

app = FastAPI(
    title="PayViya API",
    description="API for the Payviya app",
    version="0.1.0",
    default_response_class=UnicodeJSONResponse,  # Use custom response class with UTF-8
)

# Include API router
app.include_router(api_router, prefix="/api/v1")

# Set all CORS enabled origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
    expose_headers=["Content-Length", "Content-Type", "Authorization"],
    max_age=86400,  # Cache preflight requests for 24 hours
)

# Set up APScheduler for background tasks
scheduler = BackgroundScheduler()

@app.on_event("startup")
def startup_event():
    """Initialize services on startup"""
    logger.info("Starting application...")
    
    # Print directory and Python path for debugging
    print(f"Current directory: {os.getcwd()}")
    print(f"Python path: {sys.path}")
    
    # Fix campaign source enum values in database
    fix_campaign_source_values()
    
    # Schedule campaign sync tasks
    schedule_campaign_sync(scheduler)
    
    # Start the scheduler
    scheduler.start()
    
    logger.info("Application startup complete")

def fix_campaign_source_values():
    """Convert lowercase enum values to uppercase for campaign sources"""
    try:
        db = SessionLocal()
        try:
            # Update manual -> MANUAL
            db.execute(text("UPDATE campaigns SET source = 'MANUAL' WHERE source = 'manual'"))
            # Update other sources
            db.execute(text("UPDATE campaigns SET source = 'BANK_API' WHERE source = 'bank_api'"))
            db.execute(text("UPDATE campaigns SET source = 'FINTECH_API' WHERE source = 'fintech_api'"))
            db.execute(text("UPDATE campaigns SET source = 'PARTNER_API' WHERE source = 'partner_api'"))
            db.commit()
            logger.info("Campaign source values updated to uppercase in database")
        except Exception as e:
            db.rollback()
            logger.error(f"Error updating campaign source values: {e}")
        finally:
            db.close()
    except Exception as e:
        logger.error(f"Error connecting to database during migration: {e}")

@app.on_event("shutdown")
def shutdown_event():
    """Clean up on shutdown"""
    logger.info("Shutting down application...")
    
    # Shut down the scheduler gracefully to avoid job lookup errors
    if scheduler.running:
        try:
            # Gracefully shutdown the scheduler
            scheduler.shutdown(wait=False)
            logger.info("Scheduler has been shut down")
        except Exception as e:
            logger.error(f"Error shutting down scheduler: {e}")
    
    logger.info("Application shutdown complete")

# Root endpoint
@app.get("/")
async def root():
    return {
        "message": "Welcome to PayViya API - Payment Assistant and Card Recommendation Service",
        "docs": "/docs"
    }

# Router'ları ekle
app.include_router(location_routes.router, prefix="/api/v1/location", tags=["location"])

if __name__ == "__main__":
    # Print current working directory and sys.path to help with debugging
    print(f"Current directory: {os.getcwd()}")
    print(f"Python path: {sys.path}")
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True) 