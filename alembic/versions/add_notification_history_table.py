"""Add notification_history table

Revision ID: add_notification_history
Revises: a696da9128ea
Create Date: 2025-05-19 13:45:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import func

# revision identifiers, used by Alembic.
revision = 'add_notification_history'
down_revision = 'a696da9128ea'
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
        sa.Column('title', sa.String(255), server_default='Notification', nullable=False),
        sa.Column('body', sa.Text(), server_default='', nullable=False),
        sa.Column('is_read', sa.Boolean(), server_default='false', nullable=False),
        sa.Column('read_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_notification_history_user', 'notification_history', ['user_id'])
    op.create_index('idx_notification_history_campaign', 'notification_history', ['campaign_id'])
    op.create_index('idx_notification_history_merchant', 'notification_history', ['merchant_id'])
    op.create_index('idx_notification_history_category', 'notification_history', ['category_id'])
    op.create_index('idx_notification_history_location', 'notification_history', ['latitude', 'longitude'])
    op.create_index('idx_notification_history_sent_date', 'notification_history', ['sent_date'])


def downgrade():
    op.drop_table('notification_history') 