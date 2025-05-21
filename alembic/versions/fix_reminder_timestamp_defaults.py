"""Fix reminder timestamp defaults to use local time

Revision ID: fix_reminder_timestamp_defaults
Revises: fix_reminder_server_defaults
Create Date: 2024-05-21 18:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'fix_reminder_timestamp_defaults'
down_revision: Union[str, None] = 'fix_reminder_server_defaults'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Drop existing trigger first
    op.execute("""
        DROP TRIGGER IF EXISTS update_campaign_reminder_updated_at 
        ON campaign_reminders;
        
        DROP FUNCTION IF EXISTS update_updated_at_column();
    """)
    
    # Create new trigger function that uses local time
    op.execute("""
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            -- Use current timestamp with local timezone
            NEW.updated_at = CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul';
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
    
    # Update created_at default to use local time
    op.execute("""
        ALTER TABLE campaign_reminders 
        ALTER COLUMN created_at 
        SET DEFAULT CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul';
    """)
    
    # Fix existing timestamps by adding 3 hours
    op.execute("""
        UPDATE campaign_reminders 
        SET created_at = created_at + INTERVAL '3 hours',
            updated_at = updated_at + INTERVAL '3 hours'
        WHERE created_at IS NOT NULL;
    """)

def downgrade() -> None:
    # Drop trigger
    op.execute("""
        DROP TRIGGER IF EXISTS update_campaign_reminder_updated_at 
        ON campaign_reminders;
        
        DROP FUNCTION IF EXISTS update_updated_at_column();
    """)
    
    # Restore original trigger function
    op.execute("""
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
            RETURN NEW;
        END;
        $$ language 'plpgsql';
    """)
    
    # Restore original trigger
    op.execute("""
        CREATE TRIGGER update_campaign_reminder_updated_at
            BEFORE UPDATE ON campaign_reminders
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    """)
    
    # Restore created_at default
    op.execute("""
        ALTER TABLE campaign_reminders 
        ALTER COLUMN created_at 
        SET DEFAULT CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
    """)
    
    # Revert timestamp fix
    op.execute("""
        UPDATE campaign_reminders 
        SET created_at = created_at - INTERVAL '3 hours',
            updated_at = updated_at - INTERVAL '3 hours'
        WHERE created_at IS NOT NULL;
    """) 