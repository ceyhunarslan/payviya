from fastapi import APIRouter

from app.api.v1.endpoints import campaigns, recommendations, banks, admin, mock_bank_api, auth, users, debug, credit_cards, health, businesses, notifications

api_router = APIRouter()

# Include health check router first
api_router.include_router(health.router, tags=["health"])

# Include debug router first to avoid routing conflicts
api_router.include_router(debug.router, prefix="/debug", tags=["debug"])

# Include other routers
api_router.include_router(campaigns.router, prefix="/campaigns", tags=["campaigns"])
api_router.include_router(recommendations.router, prefix="/recommendations", tags=["recommendations"])
api_router.include_router(banks.router, prefix="/banks", tags=["banks"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(mock_bank_api.router, prefix="/mock-api", tags=["mock-api"])
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(credit_cards.router, prefix="/credit-cards", tags=["credit-cards"])
api_router.include_router(businesses.router, prefix="/businesses", tags=["businesses"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["notifications"]) 