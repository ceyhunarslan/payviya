"""Fix notification history timestamps

Revision ID: fix_notif_ts
Revises: fix_reminder_timestamps
Create Date: 2024-03-21 16:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'fix_notif_ts'
down_revision: Union[str, None] = 'fix_reminder_timestamps'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # 1. Convert sent_at to timestamptz
    op.execute("""
        ALTER TABLE notification_history 
        ALTER COLUMN sent_at TYPE timestamptz 
        USING sent_at AT TIME ZONE 'UTC'
    """)
    
    # 2. Convert read_at to timestamptz
    op.execute("""
        ALTER TABLE notification_history 
        ALTER COLUMN read_at TYPE timestamptz 
        USING CASE 
            WHEN read_at IS NOT NULL THEN read_at AT TIME ZONE 'UTC'
            ELSE NULL
        END
    """)
    
    # 3. Add trigger for automatic timezone handling
    op.execute("""
        CREATE OR REPLACE FUNCTION update_notification_timestamps()
        RETURNS TRIGGER AS $$
        BEGIN
            IF TG_OP = 'INSERT' THEN
                -- Use current timestamp in Europe/Istanbul timezone
                NEW.sent_at = CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul';
            END IF;
            IF NEW.is_read = true AND OLD.is_read = false THEN
                -- Use current timestamp in Europe/Istanbul timezone for read_at too
                NEW.read_at = CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul';
            END IF;
            RETURN NEW;
        END;
        $$ language 'plpgsql';
    """)
    
    op.execute("""
        DROP TRIGGER IF EXISTS update_notification_timestamps_trigger 
        ON notification_history;
        
        CREATE TRIGGER update_notification_timestamps_trigger
            BEFORE INSERT OR UPDATE ON notification_history
            FOR EACH ROW
            EXECUTE FUNCTION update_notification_timestamps();
    """)

def downgrade() -> None:
    # Remove trigger
    op.execute("""
        DROP TRIGGER IF EXISTS update_notification_timestamps_trigger 
        ON notification_history;
    """)
    
    op.execute("DROP FUNCTION IF EXISTS update_notification_timestamps();")
    
    # Convert columns back to timestamp without timezone
    op.execute("""
        ALTER TABLE notification_history 
        ALTER COLUMN sent_at TYPE timestamp 
        USING sent_at AT TIME ZONE 'UTC'
    """)
    
    op.execute("""
        ALTER TABLE notification_history 
        ALTER COLUMN read_at TYPE timestamp 
        USING CASE 
            WHEN read_at IS NOT NULL THEN read_at AT TIME ZONE 'UTC'
            ELSE NULL
        END
    """) 