"""remove unique constraint from user credit cards

Revision ID: remove_unique_constraint
Revises: add_status_to_user_credit_cards
Create Date: 2024-05-01 14:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'remove_unique_constraint'
down_revision = 'add_status_to_user_credit_cards'
branch_labels = None
depends_on = None


def upgrade():
    # Drop the unique constraint
    op.execute('ALTER TABLE user_credit_cards DROP CONSTRAINT uix_user_credit_card')


def downgrade():
    # Re-create the unique constraint
    op.execute('ALTER TABLE user_credit_cards ADD CONSTRAINT uix_user_credit_card UNIQUE (user_id, credit_card_id)') 