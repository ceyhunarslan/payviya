"""Fix reminder timestamps to UTC

Revision ID: fix_reminder_timestamps_utc
Revises: fix_reminder_updated_at_trigger
Create Date: 2024-05-21 13:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'fix_reminder_timestamps_utc'
down_revision: Union[str, None] = 'fix_reminder_updated_at_trigger'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Mevcut remind_at değerleri yerel saat (+03:00) olarak saklanıyor
    # UTC'ye çevirirken hem saat farkını hem de timezone'u düzeltmeliyiz
    op.execute("""
        UPDATE campaign_reminders 
        SET remind_at = (
            remind_at::timestamp - INTERVAL '3 hours'
        ) AT TIME ZONE 'UTC'
        WHERE remind_at IS NOT NULL;
    """)
    
    # Mevcut created_at değerleri yerel saat (+03:00) olarak saklanıyor
    op.execute("""
        UPDATE campaign_reminders 
        SET created_at = (
            created_at::timestamp - INTERVAL '3 hours'
        ) AT TIME ZONE 'UTC'
        WHERE created_at IS NOT NULL;
    """)
    
    # Update server_default for created_at to use UTC
    op.execute("""
        ALTER TABLE campaign_reminders 
        ALTER COLUMN created_at 
        SET DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul' - INTERVAL '3 hours') AT TIME ZONE 'UTC';
    """)

def downgrade() -> None:
    # UTC'den yerel saate çevirirken hem saat farkını hem de timezone'u düzeltmeliyiz
    op.execute("""
        UPDATE campaign_reminders 
        SET remind_at = (
            remind_at::timestamp + INTERVAL '3 hours'
        ) AT TIME ZONE 'Europe/Istanbul'
        WHERE remind_at IS NOT NULL;
    """)
    
    # UTC'den yerel saate çevirirken hem saat farkını hem de timezone'u düzeltmeliyiz
    op.execute("""
        UPDATE campaign_reminders 
        SET created_at = (
            created_at::timestamp + INTERVAL '3 hours'
        ) AT TIME ZONE 'Europe/Istanbul'
        WHERE created_at IS NOT NULL;
    """)
    
    # Restore original server_default for created_at
    op.execute("""
        ALTER TABLE campaign_reminders 
        ALTER COLUMN created_at 
        SET DEFAULT CURRENT_TIMESTAMP;
    """) 