import logging
import os
import sys
import asyncio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse, JSONResponse
from fastapi.encoders import jsonable_encoder
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from sqlalchemy import text
from app.db.base import SessionLocal
from app.routes import location_routes
from datetime import datetime
import pytz
from functools import partial

# Add the parent directory to path to fix import issues
parent_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(parent_dir))

from app.api.v1.router import api_router
from app.models.campaign import CampaignSource
from app.core.config import settings
from app.tasks.reminder_notifications import send_reminder_notifications

# Configure logging
logging.basicConfig(level=logging.DEBUG)
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

# Initialize scheduler
scheduler = AsyncIOScheduler()

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    logger.info("Starting application...")
    
    # Print directory and Python path for debugging
    print(f"Current directory: {os.getcwd()}")
    print(f"Python path: {sys.path}")
    
    # Configure scheduler with proper async handling
    scheduler.configure(timezone=pytz.UTC)
    
    # Schedule reminder notification task (every 5 minutes)
    scheduler.add_job(
        send_reminder_notifications,
        'interval',
        minutes=5,
        name='reminder_notifications',
        misfire_grace_time=300  # Allow job to be late by up to 5 minutes
    )
    
    # Add immediate run of reminder notifications
    scheduler.add_job(
        send_reminder_notifications,
        'date',
        run_date=datetime.utcnow(),
        name='immediate_reminder_check'
    )
    
    # Start the scheduler
    scheduler.start()
    
    logger.info("Application startup complete")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on application shutdown"""
    logger.info("Shutting down application...")
    
    # Shutdown scheduler gracefully
    scheduler.shutdown(wait=False)
    
    # Close any remaining event loops
    try:
        loop = asyncio.get_running_loop()
        
        # Get all tasks
        tasks = [t for t in asyncio.all_tasks(loop) if t is not asyncio.current_task()]
        
        if tasks:
            # Cancel all tasks
            for task in tasks:
                task.cancel()
            
            # Wait for all tasks to complete with a timeout
            try:
                await asyncio.wait(tasks, timeout=5.0)
                logger.info(f"Successfully cancelled {len(tasks)} tasks")
            except asyncio.TimeoutError:
                logger.warning("Timeout while waiting for tasks to cancel")
        
        # Stop the loop
        if not loop.is_closed():
            loop.stop()
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}")
    
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