"""merge notification details and verification codes

Revision ID: 5b7acd7a215f
Revises: ca373c517da3, create_verification_codes
Create Date: 2025-05-18 22:29:59.067732

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '5b7acd7a215f'
down_revision: Union[str, None] = ('ca373c517da3', 'create_verification_codes')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
