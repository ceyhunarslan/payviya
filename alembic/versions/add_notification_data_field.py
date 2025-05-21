"""Add data field to notification history

Revision ID: add_notification_data_field
Revises: update_notification_history_nullable
Create Date: 2024-05-21 19:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

# revision identifiers, used by Alembic.
revision: str = 'add_notification_data_field'
down_revision: Union[str, None] = 'update_notification_history_nullable'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Add data column
    op.add_column('notification_history',
        sa.Column('data', JSONB, nullable=True)
    )

def downgrade() -> None:
    # Remove data column
    op.drop_column('notification_history', 'data') 