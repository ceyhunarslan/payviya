"""Convert reminder times to UTC

Revision ID: convert_reminders_to_utc
Revises: fix_notif_ts
Create Date: 2024-05-21 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'convert_reminders_to_utc'
down_revision: Union[str, None] = 'fix_notif_ts'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Convert existing reminder times from Europe/Istanbul to UTC
    op.execute("""
        UPDATE campaign_reminders 
        SET remind_at = remind_at AT TIME ZONE 'Europe/Istanbul' AT TIME ZONE 'UTC'
        WHERE remind_at IS NOT NULL;
    """)

def downgrade() -> None:
    # Convert reminder times back to Europe/Istanbul
    op.execute("""
        UPDATE campaign_reminders 
        SET remind_at = remind_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul'
        WHERE remind_at IS NOT NULL;
    """) 