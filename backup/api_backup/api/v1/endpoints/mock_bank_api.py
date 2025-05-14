from fastapi import APIRouter, Body
from typing import Dict, Any
import uuid

# Create a router for the mock bank API
router = APIRouter()

@router.post("/campaigns/enroll")
async def mock_enroll_in_campaign(data: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    """
    Mock endpoint for bank campaign enrollment
    This simulates what a real bank API would return when enrolling in a campaign
    """
    # Generate a unique enrollment ID
    enrollment_id = str(uuid.uuid4())
    
    return {
        "success": True,
        "message": "Enrollment successful",
        "enrollment_id": enrollment_id,
        "status": "approved",
        "expiry": "2025-12-31T23:59:59"
    }

@router.get("/campaigns/enrollments/{enrollment_id}")
async def mock_check_enrollment_status(enrollment_id: str) -> Dict[str, Any]:
    """
    Mock endpoint for checking campaign enrollment status
    This simulates what a real bank API would return when checking enrollment status
    """
    return {
        "success": True,
        "status": "approved",
        "message": "Enrollment is active",
        "expiry": "2025-12-31T23:59:59"
    } 