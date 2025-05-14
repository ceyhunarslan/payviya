from fastapi import APIRouter
from pydantic import BaseModel
from datetime import datetime

class DebugCategoryResponse(BaseModel):
    id: int
    name: str
    enum: str
    icon_url: str | None = None
    color: str | None = None
    created_at: datetime
    updated_at: datetime

router = APIRouter(tags=["debug"])

@router.get("/categories", response_model=list[DebugCategoryResponse])
def debug_campaign_categories():
    """
    Debug endpoint to return mock campaign categories.
    Returns mock data to test the API structure.
    """
    from datetime import datetime, timezone
    
    # Current timestamp for created_at and updated_at
    now = datetime.now(timezone.utc)
    
    # Mock data representing campaign categories
    mock_categories = [
        {
            "id": 1,
            "name": "Groceries",
            "enum": "GROCERY",
            "icon_url": "https://example.com/icons/grocery.png",
            "color": "#4CAF50",
            "created_at": now,
            "updated_at": now
        },
        {
            "id": 2,
            "name": "Restaurants",
            "enum": "RESTAURANT",
            "icon_url": "https://example.com/icons/restaurant.png",
            "color": "#FF5722",
            "created_at": now,
            "updated_at": now
        },
        {
            "id": 3,
            "name": "Travel",
            "enum": "TRAVEL",
            "icon_url": "https://example.com/icons/travel.png",
            "color": "#2196F3",
            "created_at": now,
            "updated_at": now
        }
    ]
    
    return mock_categories 