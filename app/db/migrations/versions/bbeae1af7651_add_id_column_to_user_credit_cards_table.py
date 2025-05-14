"""Add id column to user_credit_cards table

Revision ID: bbeae1af7651
Revises: 
Create Date: 2024-04-28 16:42:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'bbeae1af7651'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Add id column as primary key
    op.add_column('user_credit_cards', sa.Column('id', sa.Integer(), nullable=False))
    
    # Create a sequence for the id column
    op.execute('CREATE SEQUENCE user_credit_cards_id_seq')
    op.execute('ALTER TABLE user_credit_cards ALTER COLUMN id SET DEFAULT nextval(\'user_credit_cards_id_seq\')')
    
    # Set values for existing rows
    op.execute('UPDATE user_credit_cards SET id = nextval(\'user_credit_cards_id_seq\')')
    
    # Make id the primary key
    op.execute('ALTER TABLE user_credit_cards ADD PRIMARY KEY (id)')


def downgrade():
    # Remove primary key constraint
    op.drop_constraint('user_credit_cards_pkey', 'user_credit_cards', type_='primary')
    
    # Drop the sequence
    op.execute('DROP SEQUENCE user_credit_cards_id_seq')
    
    # Remove id column
    op.drop_column('user_credit_cards', 'id')
