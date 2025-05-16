"""create notification history table

Revision ID: create_notification_history
Revises: b19320a89e16
Create Date: 2024-05-16 15:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import func

# revision identifiers, used by Alembic.
revision = 'create_notification_history'
down_revision = 'b19320a89e16'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'notification_history',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('merchant_id', sa.Integer(), sa.ForeignKey('merchants.id'), nullable=True),
        sa.Column('campaign_id', sa.Integer(), sa.ForeignKey('campaigns.id'), nullable=False),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('sent_at', sa.DateTime(timezone=True), server_default=func.now()),
        sa.Column('sent_date', sa.Date(), server_default=func.current_date(), nullable=False),
        sa.Column('location_hash', sa.String(50), nullable=False),
        sa.Column('category_id', sa.Integer(), sa.ForeignKey('campaign_categories.id'), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.Index('idx_notification_history_user', 'user_id'),
        sa.Index('idx_notification_history_campaign', 'campaign_id'),
        sa.Index('idx_notification_history_merchant', 'merchant_id'),
        sa.Index('idx_notification_history_category', 'category_id'),
        sa.Index('idx_notification_history_location', 'latitude', 'longitude'),
        sa.Index('idx_notification_history_sent_date', 'sent_date')
    )


def downgrade():
    op.drop_table('notification_history') 