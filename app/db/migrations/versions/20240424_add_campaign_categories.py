"""add campaign categories

Revision ID: 20240424_add_campaign_categories
Revises: bbeae1af7651
Create Date: 2024-04-24 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '20240424_add_campaign_categories'
down_revision = 'bbeae1af7651'
branch_labels = None
depends_on = None


def upgrade():
    # Create campaign_categories table
    op.create_table('campaign_categories',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('enum', sa.String(length=50), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('icon_url', sa.String(length=512), nullable=True),
        sa.Column('color', sa.String(length=20), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('enum')
    )

    # Insert default categories
    op.execute("""
        INSERT INTO campaign_categories (enum, name, icon_url, color) VALUES
        ('ELECTRONICS', 'Elektronik', '/icons/electronics.svg', '#2196F3'),
        ('FASHION', 'Moda', '/icons/fashion.svg', '#E91E63'),
        ('GROCERY', 'Market', '/icons/grocery.svg', '#4CAF50'),
        ('TRAVEL', 'Seyahat', '/icons/travel.svg', '#FF9800'),
        ('RESTAURANT', 'Restoran', '/icons/restaurant.svg', '#F44336'),
        ('FUEL', 'Yakıt', '/icons/fuel.svg', '#9C27B0'),
        ('ENTERTAINMENT', 'Eğlence', '/icons/entertainment.svg', '#00BCD4'),
        ('OTHER', 'Diğer', '/icons/other.svg', '#9E9E9E')
    """)

    # Add campaign_category_id column to campaigns table
    op.add_column('campaigns', sa.Column('campaign_category_id', sa.Integer(), nullable=True))

    # Update existing campaigns with their category IDs
    op.execute("""
        UPDATE campaigns c
        SET campaign_category_id = cc.id
        FROM campaign_categories cc
        WHERE LOWER(cc.enum) = LOWER(c.category::text)
    """)

    # Make campaign_category_id non-nullable
    op.alter_column('campaigns', 'campaign_category_id', nullable=False)

    # Add foreign key constraint
    op.create_foreign_key(
        'fk_campaigns_campaign_category_id',
        'campaigns', 'campaign_categories',
        ['campaign_category_id'], ['id']
    )

    # Drop the old category column
    op.drop_column('campaigns', 'category')


def downgrade():
    # Recreate the category column
    op.add_column('campaigns', sa.Column('category', postgresql.ENUM('electronics', 'fashion', 'grocery', 'travel', 'restaurant', 'fuel', 'entertainment', 'other', name='categoryenum'), nullable=True))

    # Update the category column with values from campaign_categories
    op.execute("""
        UPDATE campaigns c
        SET category = cc.enum::categoryenum
        FROM campaign_categories cc
        WHERE c.campaign_category_id = cc.id
    """)

    # Make category non-nullable
    op.alter_column('campaigns', 'category', nullable=False)

    # Drop the foreign key constraint
    op.drop_constraint('fk_campaigns_campaign_category_id', 'campaigns', type_='foreignkey')

    # Drop the campaign_category_id column
    op.drop_column('campaigns', 'campaign_category_id')

    # Drop the campaign_categories table
    op.drop_table('campaign_categories') 