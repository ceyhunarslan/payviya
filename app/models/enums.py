import enum

class CategoryEnum(str, enum.Enum):
    GROCERY = "GROCERY"
    ELECTRONICS = "ELECTRONICS" 
    TRAVEL = "TRAVEL"
    FUEL = "FUEL"
    RESTAURANT = "RESTAURANT"
    ENTERTAINMENT = "ENTERTAINMENT"
    FASHION = "FASHION"
    HEALTH = "HEALTH"
    EDUCATION = "EDUCATION"
    INSURANCE = "INSURANCE"
    TELECOM = "TELECOM"
    COSMETICS = "COSMETICS"
    JEWELRY = "JEWELRY"
    HOME = "HOME"
    AUTOMOTIVE = "AUTOMOTIVE"
    OTHER = "OTHER"

class DiscountType(str, enum.Enum):
    PERCENTAGE = "PERCENTAGE"
    CASHBACK = "CASHBACK"
    POINTS = "POINTS"
    INSTALLMENT = "INSTALLMENT"

class CampaignSource(str, enum.Enum):
    MANUAL = "MANUAL"           # Created manually in admin panel
    BANK_API = "BANK_API"       # Imported from bank API
    FINTECH_API = "FINTECH_API" # Imported from fintech partners
    PARTNER_API = "PARTNER_API" # Imported from other partners

class CampaignStatus(str, enum.Enum):
    DRAFT = "DRAFT"             # Newly created, not yet approved
    PENDING = "PENDING"         # Pending approval (for imported campaigns)
    APPROVED = "APPROVED"       # Approved and active
    REJECTED = "REJECTED"       # Rejected by admin
    ARCHIVED = "ARCHIVED"       # No longer active but kept for reference 