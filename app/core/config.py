import secrets
from typing import List, Optional, Dict, Any

from pydantic import PostgresDsn, validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "PayViya API"
    SECRET_KEY: str = "your-secret-key-here-make-it-long-and-random"  # Default fallback value
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days
    ALGORITHM: str = "HS256"  # Algorithm for JWT
    
    # Frontend URL
    FRONTEND_URL: str = "payviya://reset-password"  # Mobile app deep link scheme for development
    
    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = "firebase-service-account.json"
    
    # SMTP Settings for Mailtrap
    SMTP_HOST: str = "smtp.mailtrap.io"
    SMTP_PORT: int = 587  # TLS port
    SMTP_USERNAME: str = "ac4c6e994b3bdf"
    SMTP_PASSWORD: str = "afc0d3cee82453"
    SMTP_FROM_EMAIL: str = "noreply@payviya.com"
    
    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:54326",
        "http://127.0.0.1:54326",
        "http://localhost:*",
        "http://127.0.0.1:*"
    ]
    
    # Database
    POSTGRES_SERVER: str = "localhost"
    POSTGRES_USER: str = "ceyhun"
    POSTGRES_PASSWORD: str = ""
    POSTGRES_DB: str = "payviya"
    POSTGRES_PORT: int = 5432
    SQLALCHEMY_DATABASE_URI: Optional[PostgresDsn] = None

    @validator("SQLALCHEMY_DATABASE_URI", pre=True)
    def assemble_db_connection(cls, v: Optional[str], values: Dict[str, Any]) -> Any:
        if isinstance(v, str):
            return v
        return PostgresDsn.build(
            scheme="postgresql",
            username=values.get("POSTGRES_USER"),
            password=values.get("POSTGRES_PASSWORD"),
            host=values.get("POSTGRES_SERVER"),
            port=values.get("POSTGRES_PORT"),
            path=f"{values.get('POSTGRES_DB') or ''}",
        )

    class Config:
        case_sensitive = True
        env_file = ".env"


settings = Settings() 