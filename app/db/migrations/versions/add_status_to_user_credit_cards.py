"""add status to user credit cards

Revision ID: add_status_to_user_credit_cards
Revises: 20240424_add_campaign_categories
Create Date: 2024-05-01 13:30:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'add_status_to_user_credit_cards'
down_revision = '20240424_add_campaign_categories'
branch_labels = None
depends_on = None


def upgrade():
    # Add status column with default value True
    op.add_column('user_credit_cards', sa.Column('status', sa.Boolean(), nullable=False, server_default='true'))
    
    # Add timestamp columns
    op.add_column('user_credit_cards', sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()))
    op.add_column('user_credit_cards', sa.Column('updated_at', sa.DateTime(timezone=True), onupdate=sa.func.now()))


def downgrade():
    # Remove the columns in reverse order
    op.drop_column('user_credit_cards', 'updated_at')
    op.drop_column('user_credit_cards', 'created_at')
    op.drop_column('user_credit_cards', 'status') 