"""Merge reminder timestamp heads

Revision ID: merge_reminder_timestamp_heads
Revises: fix_reminder_timestamp_defaults, fix_utc_trigger
Create Date: 2024-05-21 18:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'merge_reminder_timestamp_heads'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = ('fix_reminder_timestamp_defaults', 'fix_utc_trigger')

def upgrade() -> None:
    pass

def downgrade() -> None:
    pass 