# backend/routes/contractors.py
import logging
from fastapi import APIRouter, HTTPException, Query
from firebase_admin import firestore
from pydantic import BaseModel, Field, validator
from typing import List, Optional

router = APIRouter()
logger = logging.getLogger(__name__)

# ----------------------------
# Pydantic Model
# ----------------------------
class ContractorFilter(BaseModel):
    location: str = Field(..., description="State or region code (e.g., VIC, NSW, QLD, SA, AUS)")
    services: List[str] = Field(..., min_items=1, description="List of services required")

    @validator("location")
    def location_uppercase(cls, v):
        return v.strip().upper()

    @validator("services", each_item=True)
    def normalize_service(cls, v):
        return v.strip().lower()


# ----------------------------
# Routes
# ----------------------------
@router.post("/", response_model=dict)
async def get_contractors(filter_data: ContractorFilter):
    """
    Fetch contractors based on location and a list of required services.
    Returns contractors from the user's state/region and national providers ("AUS").
    """
    try:
        db = firestore.client()

        # Base query: contractors in the user’s location OR national providers
        base_query = db.collection("contractors").where(
            "location", "in", [filter_data.location, "AUS"]
        )

        # Multi-service filter: contractors offering at least ONE required service
        query = base_query.where("services", "array_contains_any", filter_data.services)

        docs = list(query.stream())
        contractors = [{"id": doc.id, **doc.to_dict()} for doc in docs]

        if not contractors:
            logger.info(f"No contractors found for {filter_data.location} with services {filter_data.services}")

        return {"count": len(contractors), "contractors": contractors}

    except Exception as e:
        logger.exception(f"Error fetching contractors for {filter_data}")
        raise HTTPException(status_code=500, detail="Failed to fetch contractors")
