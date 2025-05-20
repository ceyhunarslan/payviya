from datetime import datetime, timedelta
import sys
import os
from sqlalchemy import create_engine, text

# Database connection string
DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/payviya"

def check_reminder():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        try:
            # Get the reminder
            result = conn.execute(
                text("SELECT * FROM campaign_reminders WHERE id = 5")
            )
            reminder = result.fetchone()
            if reminder:
                print(f"Reminder ID: {reminder.id}")
                print(f"User ID: {reminder.user_id}")
                print(f"Campaign ID: {reminder.campaign_id}")
                print(f"Remind At: {reminder.remind_at}")
                print(f"Is Sent: {reminder.is_sent}")
            else:
                print("Reminder not found")
        
        except Exception as e:
            print(f"Error checking reminder: {e}")

if __name__ == "__main__":
    check_reminder() 