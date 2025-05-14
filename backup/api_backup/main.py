import logging
import uvicorn
import os
import sys
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from apscheduler.schedulers.background import BackgroundScheduler

# Add the parent directory to path to fix import issues
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Now use absolute imports
from api.api.v1.router import api_router
from api.core.config import settings
from api.tasks.campaign_sync_task import schedule_campaign_sync

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="PayViya API",
    description="Payment assistant API for card recommendations and campaign participation",
    version="0.1.0",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development (restrict this in production)
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
    expose_headers=["Content-Length", "Content-Type", "Authorization"],
)

# Include API routes
app.include_router(api_router, prefix="/api/v1")

# Set up APScheduler for background tasks
scheduler = BackgroundScheduler()

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    logger.info("Starting application...")
    
    # Schedule campaign sync tasks
    schedule_campaign_sync(scheduler)
    
    # Start the scheduler
    scheduler.start()
    
    logger.info("Application startup complete")

@app.on_event("shutdown")
async def shutdown_event():
    """Clean up on shutdown"""
    logger.info("Shutting down application...")
    
    # Shut down the scheduler
    if scheduler.running:
        scheduler.shutdown()
    
    logger.info("Application shutdown complete")

# Root endpoint
@app.get("/")
async def root():
    return {
        "message": "Welcome to PayViya API - Payment Assistant and Card Recommendation Service",
        "docs": "/docs"
    }

if __name__ == "__main__":
    # Print current working directory and sys.path to help with debugging
    print(f"Current directory: {os.getcwd()}")
    print(f"Python path: {sys.path}")
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True) 