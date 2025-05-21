"""merge multiple heads

Revision ID: b2322c2fd31e
Revises: add_notification_data_field
Create Date: 2025-05-21 14:01:14.863538

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b2322c2fd31e'
down_revision: Union[str, None] = 'add_notification_data_field'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
