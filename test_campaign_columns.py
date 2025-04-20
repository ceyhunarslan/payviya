#!/usr/bin/env python
"""
Campaign Management Columns Test
"""

import os
import sys
import dotenv
from sqlalchemy import create_engine, text, MetaData, Table, inspect
from sqlalchemy.orm import sessionmaker

# Load environment variables
dotenv.load_dotenv('./venv/.env')

# Get database connection details
POSTGRES_SERVER = os.getenv("POSTGRES_SERVER", "localhost")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_USER = os.getenv("POSTGRES_USER", "ceyhun")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "")
POSTGRES_DB = os.getenv("POSTGRES_DB", "payviya")

# Create database URL
if POSTGRES_PASSWORD:
    DATABASE_URL = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_SERVER}:{POSTGRES_PORT}/{POSTGRES_DB}"
else:
    DATABASE_URL = f"postgresql://{POSTGRES_USER}@{POSTGRES_SERVER}:{POSTGRES_PORT}/{POSTGRES_DB}"

print(f"Using database URL: {DATABASE_URL}")

# Connect to database
try:
    engine = create_engine(DATABASE_URL)
    Session = sessionmaker(bind=engine)
    session = Session()
    
    # Get inspector to check table columns
    inspector = inspect(engine)
    
    # Check campaigns table
    print("\n=== Checking campaigns table columns ===")
    campaign_columns = inspector.get_columns("campaigns")
    column_names = [col["name"] for col in campaign_columns]
    print(f"Found {len(column_names)} columns in campaigns table:")
    for col in column_names:
        print(f"  - {col}")
    
    # Check for hybrid campaign management columns
    hybrid_columns = [
        "source", "status", "external_id", "priority",
        "last_sync_at", "review_notes", "reviewed_by"
    ]
    
    print("\nChecking for hybrid campaign management columns:")
    for col in hybrid_columns:
        if col in column_names:
            print(f"  ✅ {col} - Found")
        else:
            print(f"  ❌ {col} - Missing")
    
    # Check banks table
    print("\n=== Checking banks table columns ===")
    bank_columns = inspector.get_columns("banks")
    bank_column_names = [col["name"] for col in bank_columns]
    print(f"Found {len(bank_column_names)} columns in banks table:")
    for col in bank_column_names:
        print(f"  - {col}")
    
    # Check for bank sync columns
    bank_sync_columns = [
        "campaign_sync_enabled", "campaign_sync_endpoint",
        "last_campaign_sync_at", "auto_approve_campaigns"
    ]
    
    print("\nChecking for bank sync columns:")
    for col in bank_sync_columns:
        if col in bank_column_names:
            print(f"  ✅ {col} - Found")
        else:
            print(f"  ❌ {col} - Missing")
    
    # Try to select data from campaigns with the new columns
    try:
        print("\n=== Sample campaign data ===")
        result = session.execute(text("""
            SELECT id, name, source, status, priority 
            FROM campaigns
            LIMIT 3
        """))
        
        # Fixed row handling
        for row in result:
            print(f"  Campaign ID: {row.id}, Name: {row.name}")
            print(f"   - Source: {row.source}")
            print(f"   - Status: {row.status}")
            print(f"   - Priority: {row.priority}")
            print("")
    except Exception as e:
        print(f"Error querying campaign data: {str(e)}")
    
    session.close()
    print("\n=== Test Complete ===")
    
except Exception as e:
    print(f"Error: {str(e)}") 