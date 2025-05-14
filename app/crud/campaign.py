from typing import Any, Dict, Optional, Union
from sqlalchemy.orm import Session

from app.crud.base import CRUDBase
from app.models.campaign import Campaign
from app.schemas.campaign import CampaignCreate, CampaignUpdate


class CRUDCampaign(CRUDBase[Campaign, CampaignCreate, CampaignUpdate]):
    def create(self, db: Session, *, obj_in: CampaignCreate) -> Campaign:
        db_obj = Campaign(
            name=obj_in.name,
            description=obj_in.description,
            bank_id=obj_in.bank_id,
            card_id=obj_in.card_id,
            category=obj_in.category,
            discount_type=obj_in.discount_type,
            discount_value=obj_in.discount_value,
            min_amount=obj_in.min_amount,
            max_discount=obj_in.max_discount,
            start_date=obj_in.start_date,
            end_date=obj_in.end_date,
            merchant_id=obj_in.merchant_id,
            is_active=obj_in.is_active,
            requires_enrollment=obj_in.requires_enrollment,
            enrollment_url=obj_in.enrollment_url,
            source=obj_in.source,
            status=obj_in.status,
            external_id=obj_in.external_id,
            priority=obj_in.priority
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def update(
        self, db: Session, *, db_obj: Campaign, obj_in: Union[CampaignUpdate, Dict[str, Any]]
    ) -> Campaign:
        if isinstance(obj_in, dict):
            update_data = obj_in
        else:
            update_data = obj_in.dict(exclude_unset=True)
        
        return super().update(db, db_obj=db_obj, obj_in=update_data)


campaign = CRUDCampaign(Campaign) 