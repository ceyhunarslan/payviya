"""add fcm_token to users

Revision ID: add_fcm_token_to_users
Revises: 
Create Date: 2025-05-19 11:19:17.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'add_fcm_token_to_users'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Add fcm_token column to users table
    op.add_column('users', sa.Column('fcm_token', sa.String(255), nullable=True))


def downgrade():
    # Remove fcm_token column from users table
    op.drop_column('users', 'fcm_token') 