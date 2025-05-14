from sqlalchemy import text
from app.db.base import SessionLocal

def fix_campaign_status_values():
    """Convert lowercase enum values to uppercase for campaign status"""
    try:
        db = SessionLocal()
        try:
            # Update all status values to uppercase
            db.execute(text("UPDATE campaigns SET status = 'APPROVED' WHERE status = 'approved'"))
            db.execute(text("UPDATE campaigns SET status = 'PENDING' WHERE status = 'pending'"))
            db.execute(text("UPDATE campaigns SET status = 'DRAFT' WHERE status = 'draft'"))
            db.execute(text("UPDATE campaigns SET status = 'REJECTED' WHERE status = 'rejected'"))
            db.execute(text("UPDATE campaigns SET status = 'ARCHIVED' WHERE status = 'archived'"))
            db.commit()
            print("Campaign status values updated to uppercase in database")
        except Exception as e:
            db.rollback()
            print(f"Error updating campaign status values: {e}")
        finally:
            db.close()
    except Exception as e:
        print(f"Error connecting to database during migration: {e}")

if __name__ == "__main__":
    fix_campaign_status_values() 