"""create verification codes table

Revision ID: create_verification_codes
Revises: create_notification_history
Create Date: 2024-03-23 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'create_verification_codes'
down_revision = 'create_notification_history'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'verification_codes',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('code', sa.String(length=6), nullable=False),
        sa.Column('purpose', sa.String(length=50), nullable=False),
        sa.Column('is_used', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.Column('used_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.Index('idx_verification_codes_email_purpose', 'email', 'purpose'),
        sa.Index('idx_verification_codes_code', 'code')
    )


def downgrade():
    op.drop_table('verification_codes') 