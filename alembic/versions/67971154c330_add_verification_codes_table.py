"""add_verification_codes_table

Revision ID: 67971154c330
Revises: 
Create Date: 2024-03-19 15:35:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import func


# revision identifiers, used by Alembic.
revision = '67971154c330'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'verification_codes',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('code', sa.String(length=6), nullable=False),
        sa.Column('purpose', sa.String(length=50), nullable=False),
        sa.Column('is_used', sa.Boolean(), server_default='false', nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=func.now(), nullable=False),
        sa.Column('used_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_verification_codes_id'), 'verification_codes', ['id'], unique=False)


def downgrade():
    op.drop_index(op.f('ix_verification_codes_id'), table_name='verification_codes')
    op.drop_table('verification_codes')
