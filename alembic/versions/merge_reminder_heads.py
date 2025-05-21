"""Merge reminder migration heads

Revision ID: merge_reminder_heads
Revises: b89390d04b11, convert_reminders_to_utc, fix_notif_data, fix_reminder_server_defaults
Create Date: 2024-05-21 15:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'merge_reminder_heads'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = ('b89390d04b11', 'convert_reminders_to_utc', 'fix_notif_data', 'fix_reminder_server_defaults')

def upgrade() -> None:
    pass

def downgrade() -> None:
    pass 