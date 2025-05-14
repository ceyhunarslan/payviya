from fastapi import APIRouter, HTTPException
from app.services.osm_service import OSMService
from typing import List, Dict
from pydantic import BaseModel

router = APIRouter()

class LocationRequest(BaseModel):
    latitude: float
    longitude: float
    radius: int = 50

@router.post("/nearby-businesses", response_model=List[Dict])
async def get_nearby_businesses(location: LocationRequest):
    """
    Get nearby businesses based on location using OpenStreetMap
    """
    try:
        businesses = await OSMService.get_nearby_businesses(
            latitude=location.latitude,
            longitude=location.longitude,
            radius=location.radius
        )
        return businesses
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 