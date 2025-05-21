"""Fix reminder server defaults

Revision ID: fix_reminder_server_defaults
Revises: fix_reminder_timestamps_utc
Create Date: 2024-05-21 14:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'fix_reminder_server_defaults'
down_revision: Union[str, None] = 'fix_reminder_timestamps_utc'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Update server defaults to use UTC directly
    op.execute("""
        -- Update created_at server default
        ALTER TABLE campaign_reminders 
        ALTER COLUMN created_at 
        SET DEFAULT CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
        
        -- Add server default for remind_at
        ALTER TABLE campaign_reminders 
        ALTER COLUMN remind_at 
        SET DEFAULT CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
    """)
    
    # Ensure all existing timestamps are in UTC
    op.execute("""
        -- Update any remaining non-UTC timestamps in remind_at
        UPDATE campaign_reminders 
        SET remind_at = remind_at AT TIME ZONE 'UTC'
        WHERE remind_at IS NOT NULL 
        AND remind_at::text LIKE '%+03%';
        
        -- Update any remaining non-UTC timestamps in created_at
        UPDATE campaign_reminders 
        SET created_at = created_at AT TIME ZONE 'UTC'
        WHERE created_at IS NOT NULL 
        AND created_at::text LIKE '%+03%';
        
        -- Update any remaining non-UTC timestamps in updated_at
        UPDATE campaign_reminders 
        SET updated_at = updated_at AT TIME ZONE 'UTC'
        WHERE updated_at IS NOT NULL 
        AND updated_at::text LIKE '%+03%';
    """)

def downgrade() -> None:
    # Revert server defaults to previous state
    op.execute("""
        -- Revert created_at server default
        ALTER TABLE campaign_reminders 
        ALTER COLUMN created_at 
        SET DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul' - INTERVAL '3 hours') AT TIME ZONE 'UTC';
        
        -- Remove server default from remind_at
        ALTER TABLE campaign_reminders 
        ALTER COLUMN remind_at 
        DROP DEFAULT;
    """) 