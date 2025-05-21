"""Fix reminder updated_at trigger to use UTC

Revision ID: fix_utc_trigger
Revises: fix_reminder_timezone_offset
Create Date: 2024-05-21 17:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'fix_utc_trigger'
down_revision: Union[str, None] = 'fix_reminder_timezone_offset'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Drop existing trigger and function
    op.execute("""
        DROP TRIGGER IF EXISTS update_campaign_reminder_updated_at 
        ON campaign_reminders;
        
        DROP FUNCTION IF EXISTS update_updated_at_column();
    """)
    
    # Create new function that uses UTC
    op.execute("""
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
            RETURN NEW;
        END;
        $$ language 'plpgsql';
    """)
    
    # Create new trigger
    op.execute("""
        CREATE TRIGGER update_campaign_reminder_updated_at
            BEFORE UPDATE ON campaign_reminders
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    """)
    
    # Fix existing updated_at values
    op.execute("""
        UPDATE campaign_reminders 
        SET updated_at = updated_at AT TIME ZONE 'UTC'
        WHERE updated_at IS NOT NULL;
    """)

def downgrade() -> None:
    # Drop UTC trigger and function
    op.execute("""
        DROP TRIGGER IF EXISTS update_campaign_reminder_updated_at 
        ON campaign_reminders;
        
        DROP FUNCTION IF EXISTS update_updated_at_column();
    """)
    
    # Create original function that uses local time
    op.execute("""
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul';
            RETURN NEW;
        END;
        $$ language 'plpgsql';
    """)
    
    # Create original trigger
    op.execute("""
        CREATE TRIGGER update_campaign_reminder_updated_at
            BEFORE UPDATE ON campaign_reminders
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    """)
    
    # Restore original updated_at values
    op.execute("""
        UPDATE campaign_reminders 
        SET updated_at = updated_at AT TIME ZONE 'Europe/Istanbul'
        WHERE updated_at IS NOT NULL;
    """) 