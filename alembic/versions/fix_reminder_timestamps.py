"""Fix reminder timestamps

Revision ID: fix_reminder_timestamps
Revises: add_is_active_column
Create Date: 2024-03-21 15:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'fix_reminder_timestamps'
down_revision: Union[str, None] = 'add_is_active_column'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # 1. First convert remind_at to timestamptz if it's not already
    op.execute("""
        ALTER TABLE campaign_reminders 
        ALTER COLUMN remind_at TYPE timestamptz 
        USING remind_at AT TIME ZONE 'UTC'
    """)
    
    # 2. Ensure created_at and updated_at are timestamptz
    op.execute("""
        ALTER TABLE campaign_reminders 
        ALTER COLUMN created_at TYPE timestamptz 
        USING created_at AT TIME ZONE 'UTC'
    """)
    
    op.execute("""
        ALTER TABLE campaign_reminders 
        ALTER COLUMN updated_at TYPE timestamptz 
        USING updated_at AT TIME ZONE 'UTC'
    """)
    
    # 3. Add a trigger to automatically handle updated_at in UTC
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
        DROP TRIGGER IF EXISTS update_campaign_reminder_updated_at 
        ON campaign_reminders;
        
        CREATE TRIGGER update_campaign_reminder_updated_at
            BEFORE UPDATE ON campaign_reminders
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    """)

def downgrade() -> None:
    # Remove trigger
    op.execute("""
        DROP TRIGGER IF EXISTS update_campaign_reminder_updated_at 
        ON campaign_reminders;
    """)
    
    op.execute("DROP FUNCTION IF EXISTS update_updated_at_column();")
    
    # Convert columns back to timestamp without timezone
    op.execute("""
        ALTER TABLE campaign_reminders 
        ALTER COLUMN remind_at TYPE timestamp 
        USING remind_at AT TIME ZONE 'UTC'
    """)
    
    op.execute("""
        ALTER TABLE campaign_reminders 
        ALTER COLUMN created_at TYPE timestamp 
        USING created_at AT TIME ZONE 'UTC'
    """)
    
    op.execute("""
        ALTER TABLE campaign_reminders 
        ALTER COLUMN updated_at TYPE timestamp 
        USING updated_at AT TIME ZONE 'UTC'
    """) 