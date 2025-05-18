"""add notification details columns

Revision ID: ca373c517da3
Revises: previous_revision_id
Create Date: 2024-03-24 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ca373c517da3'
down_revision: Union[str, None] = None  # Update this with the actual previous revision ID
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add new columns
    op.add_column('notification_history', sa.Column('title', sa.String(255), nullable=False, server_default='Notification'))
    op.add_column('notification_history', sa.Column('body', sa.Text(), nullable=False, server_default=''))
    op.add_column('notification_history', sa.Column('is_read', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('notification_history', sa.Column('read_at', sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    # Remove columns
    op.drop_column('notification_history', 'read_at')
    op.drop_column('notification_history', 'is_read')
    op.drop_column('notification_history', 'body')
    op.drop_column('notification_history', 'title')
