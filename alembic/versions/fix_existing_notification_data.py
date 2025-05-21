"""Fix existing notification data timestamps

Revision ID: fix_notif_data
Revises: fix_notif_ts
Create Date: 2024-03-21 17:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'fix_notif_data'
down_revision: Union[str, None] = 'fix_notif_ts'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Fix existing notification timestamps by converting them to UTC
    op.execute("""
        UPDATE notification_history 
        SET sent_at = sent_at AT TIME ZONE 'Europe/Istanbul' AT TIME ZONE 'UTC'
        WHERE sent_at IS NOT NULL;
    """)
    
    op.execute("""
        UPDATE notification_history 
        SET read_at = read_at AT TIME ZONE 'Europe/Istanbul' AT TIME ZONE 'UTC'
        WHERE read_at IS NOT NULL;
    """)

def downgrade() -> None:
    # Convert timestamps back to local time
    op.execute("""
        UPDATE notification_history 
        SET sent_at = sent_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul'
        WHERE sent_at IS NOT NULL;
    """)
    
    op.execute("""
        UPDATE notification_history 
        SET read_at = read_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul'
        WHERE read_at IS NOT NULL;
    """) 