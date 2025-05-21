"""Update notification history nullable fields

Revision ID: update_notification_history_nullable
Revises: merge_reminder_timestamp_heads
Create Date: 2024-05-21 19:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'update_notification_history_nullable'
down_revision: Union[str, None] = 'merge_reminder_timestamp_heads'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Make location fields nullable
    op.alter_column('notification_history', 'latitude',
        existing_type=sa.Float(),
        nullable=True
    )
    
    op.alter_column('notification_history', 'longitude',
        existing_type=sa.Float(),
        nullable=True
    )
    
    op.alter_column('notification_history', 'location_hash',
        existing_type=sa.String(50),
        nullable=True
    )
    
    op.alter_column('notification_history', 'category_id',
        existing_type=sa.Integer(),
        nullable=True
    )

def downgrade() -> None:
    # Make location fields required again
    op.alter_column('notification_history', 'latitude',
        existing_type=sa.Float(),
        nullable=False
    )
    
    op.alter_column('notification_history', 'longitude',
        existing_type=sa.Float(),
        nullable=False
    )
    
    op.alter_column('notification_history', 'location_hash',
        existing_type=sa.String(50),
        nullable=False
    )
    
    op.alter_column('notification_history', 'category_id',
        existing_type=sa.Integer(),
        nullable=False
    ) 