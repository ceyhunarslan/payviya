from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
from app.db.session import get_db, SessionLocal, Base

engine = create_engine(str(settings.SQLALCHEMY_DATABASE_URI), pool_pre_ping=True)

__all__ = ["get_db", "Base", "engine", "SessionLocal"] 