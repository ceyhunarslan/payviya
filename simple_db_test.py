#!/usr/bin/env python
"""
Simple Database Test
"""

import os
import sys
import dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Load environment variables
dotenv.load_dotenv('./venv/.env')

# Get database connection details
POSTGRES_SERVER = os.getenv("POSTGRES_SERVER", "localhost")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_USER = os.getenv("POSTGRES_USER", "ceyhun")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "")
POSTGRES_DB = os.getenv("POSTGRES_DB", "payviya")

# Print environment settings
print(f"Database settings:")
print(f"  Server: {POSTGRES_SERVER}")
print(f"  Port: {POSTGRES_PORT}")
print(f"  User: {POSTGRES_USER}")
print(f"  Database: {POSTGRES_DB}")

# Create database URL
if POSTGRES_PASSWORD:
    DATABASE_URL = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_SERVER}:{POSTGRES_PORT}/{POSTGRES_DB}"
else:
    DATABASE_URL = f"postgresql://{POSTGRES_USER}@{POSTGRES_SERVER}:{POSTGRES_PORT}/{POSTGRES_DB}"

print(f"Using database URL: {DATABASE_URL}")

# Test database connection
try:
    # Create engine and session
    engine = create_engine(DATABASE_URL)
    Session = sessionmaker(bind=engine)
    session = Session()
    
    # Try a simple query
    result = session.execute(text("SELECT 1 as test"))
    value = result.scalar()
    print(f"Database connection successful! Test query result: {value}")
    
    # Try to get tables list
    result = session.execute(text("SELECT tablename FROM pg_tables WHERE schemaname = 'public'"))
    tables = [row[0] for row in result]
    print(f"Found {len(tables)} tables:")
    for table in tables:
        print(f"  - {table}")
    
    session.close()
except Exception as e:
    print(f"Error connecting to database: {str(e)}") 