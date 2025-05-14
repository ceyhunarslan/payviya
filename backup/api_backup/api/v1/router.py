from fastapi import APIRouter

from app.api.v1.endpoints import campaigns, recommendations, banks, admin, mock_bank_api, auth

api_router = APIRouter()

api_router.include_router(campaigns.router, prefix="/campaigns", tags=["campaigns"])
api_router.include_router(recommendations.router, prefix="/recommendations", tags=["recommendations"])
api_router.include_router(banks.router, prefix="/banks", tags=["banks"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(mock_bank_api.router, prefix="/mock-api", tags=["mock-api"])
api_router.include_router(auth.router, prefix="/auth", tags=["auth"]) 