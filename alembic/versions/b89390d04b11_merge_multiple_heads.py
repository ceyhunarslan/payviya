"""merge multiple heads

Revision ID: b89390d04b11
Revises: 67971154c330, merge_heads
Create Date: 2025-05-19 15:24:03.610740

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b89390d04b11'
down_revision: Union[str, None] = ('67971154c330', 'merge_heads')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
