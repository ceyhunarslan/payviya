"""merge heads

Revision ID: merge_heads
Revises: add_notification_history, create_user_auth_table
Create Date: 2025-05-19 13:45:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic
revision = 'merge_heads'
down_revision = ('add_notification_history', 'create_user_auth_table')
branch_labels = None
depends_on = None


def upgrade():
    pass


def downgrade():
    pass 