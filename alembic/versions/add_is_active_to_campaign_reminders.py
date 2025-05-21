"""Add is_active column to campaign_reminders table

Revision ID: add_is_active_column
Revises: a696da9128ea
Create Date: 2024-03-21 14:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'add_is_active_column'
down_revision: Union[str, None] = 'a696da9128ea'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Add is_active column with default value True
    op.add_column('campaign_reminders', sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'))

def downgrade() -> None:
    # Remove is_active column
    op.drop_column('campaign_reminders', 'is_active') 