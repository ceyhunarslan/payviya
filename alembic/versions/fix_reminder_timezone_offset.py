"""Fix reminder timezone offset

Revision ID: fix_reminder_timezone_offset
Revises: merge_reminder_heads
Create Date: 2024-05-21 16:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'fix_reminder_timezone_offset'
down_revision: Union[str, None] = 'merge_reminder_heads'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Mevcut kayıtları düzelt
    # Örnek: 09:15:00+03:00 -> 09:15:00+00:00 (gerçek yerel saat 12:15 olan kayıt için)
    op.execute("""
        UPDATE campaign_reminders 
        SET remind_at = remind_at AT TIME ZONE 'UTC'
        WHERE remind_at IS NOT NULL;
    """)

def downgrade() -> None:
    # Geri alma durumunda kayıtları eski haline döndür
    op.execute("""
        UPDATE campaign_reminders 
        SET remind_at = remind_at AT TIME ZONE 'Europe/Istanbul'
        WHERE remind_at IS NOT NULL;
    """) 