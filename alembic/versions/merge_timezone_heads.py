"""merge timezone heads

Revision ID: merge_timezone_heads
Revises: convert_reminders_to_utc, fix_notif_data, b89390d04b11
Create Date: 2024-03-22 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'merge_timezone_heads'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = ('convert_reminders_to_utc', 'fix_notif_data', 'b89390d04b11')

def upgrade() -> None:
    pass

def downgrade() -> None:
    pass 