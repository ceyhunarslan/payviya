from datetime import datetime, timedelta
import sys
import os
from sqlalchemy import create_engine, text

# Database connection string
DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/payviya"

def update_reminder():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        try:
            # Update the remind_at time to current time in UTC
            result = conn.execute(
                text("UPDATE campaign_reminders SET remind_at = CURRENT_TIMESTAMP AT TIME ZONE 'UTC' WHERE id = 5")
            )
            conn.commit()
            print("Updated reminder successfully")
        
        except Exception as e:
            print(f"Error updating reminder: {e}")
            conn.rollback()

if __name__ == "__main__":
    update_reminder() 