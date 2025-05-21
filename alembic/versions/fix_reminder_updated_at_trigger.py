"""Fix reminder updated_at trigger

Revision ID: fix_reminder_updated_at_trigger
Revises: merge_timezone_heads
Create Date: 2024-05-21 12:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'fix_reminder_updated_at_trigger'
down_revision: Union[str, None] = 'merge_timezone_heads'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Drop existing trigger and function
    op.execute("""
        DROP TRIGGER IF EXISTS update_campaign_reminder_updated_at 
        ON campaign_reminders;
        
        DROP FUNCTION IF EXISTS update_updated_at_column();
    """)
    
    # Create new function that properly converts local time to UTC
    op.execute("""
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            -- Get current timestamp in Europe/Istanbul and convert to UTC
            NEW.updated_at = (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul') AT TIME ZONE 'UTC';
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

def downgrade() -> None:
    # Drop trigger and function
    op.execute("""
        DROP TRIGGER IF EXISTS update_campaign_reminder_updated_at 
        ON campaign_reminders;
        
        DROP FUNCTION IF EXISTS update_updated_at_column();
    """)
    
    # Recreate original function and trigger
    op.execute("""
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
            RETURN NEW;
        END;
        $$ language 'plpgsql';
    """)
    
    op.execute("""
        CREATE TRIGGER update_campaign_reminder_updated_at
            BEFORE UPDATE ON campaign_reminders
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    """) 