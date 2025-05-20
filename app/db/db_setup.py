from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# Create SQLAlchemy engine with string URL
engine = create_engine(
    str(settings.SQLALCHEMY_DATABASE_URI),
    pool_pre_ping=True,
    connect_args={
        "client_encoding": "utf8",
        "options": "-c lc_messages=tr_TR.UTF-8 -c lc_monetary=tr_TR.UTF-8 -c lc_numeric=tr_TR.UTF-8 -c lc_time=tr_TR.UTF-8"
    }
)

# Create SessionLocal class
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
    expire_on_commit=False
) 