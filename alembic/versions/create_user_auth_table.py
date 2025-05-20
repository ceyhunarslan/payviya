"""create user auth table and remove fcm_token

Revision ID: create_user_auth_table
Revises: add_fcm_token_to_users
Create Date: 2025-05-19 11:45:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'create_user_auth_table'
down_revision = 'add_fcm_token_to_users'
branch_labels = None
depends_on = None


def upgrade():
    # Create user_auth table
    op.create_table(
        'user_auth',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('fcm_token', sa.String(255), nullable=True),
        sa.Column('device_id', sa.String(255), nullable=True),
        sa.Column('device_type', sa.String(50), nullable=True),
        sa.Column('last_login', sa.DateTime(timezone=True), nullable=True),
        sa.Column('is_active', sa.Boolean(), server_default='true', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_user_auth_id'), 'user_auth', ['id'], unique=False)
    
    # Copy existing FCM tokens to new table
    op.execute("""
        INSERT INTO user_auth (user_id, fcm_token, created_at)
        SELECT id, fcm_token, now()
        FROM users
        WHERE fcm_token IS NOT NULL
    """)
    
    # Remove fcm_token from users table
    op.drop_column('users', 'fcm_token')


def downgrade():
    # Add fcm_token back to users table
    op.add_column('users', sa.Column('fcm_token', sa.String(255), nullable=True))
    
    # Copy FCM tokens back to users table
    op.execute("""
        UPDATE users u
        SET fcm_token = (
            SELECT fcm_token
            FROM user_auth ua
            WHERE ua.user_id = u.id
            ORDER BY ua.created_at DESC
            LIMIT 1
        )
    """)
    
    # Drop user_auth table
    op.drop_index(op.f('ix_user_auth_id'), table_name='user_auth')
    op.drop_table('user_auth') 