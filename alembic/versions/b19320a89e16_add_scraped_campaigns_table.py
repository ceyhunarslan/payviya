"""add scraped_campaigns table

Revision ID: b19320a89e16
Revises: 
Create Date: 2024-03-05 17:08:48.293000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'b19320a89e16'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create scraped_campaigns table
    op.execute("""
    CREATE TABLE scraped_campaigns (
        LIKE campaigns INCLUDING ALL,
        
        -- Additional fields
        is_processed BOOLEAN DEFAULT FALSE,
        scrape_source TEXT,
        scrape_attempted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        scrape_log TEXT
    )
    """)


def downgrade() -> None:
    # Drop scraped_campaigns table
    op.drop_table('scraped_campaigns')
