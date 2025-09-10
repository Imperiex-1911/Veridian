# backend/routes/rebates.py
from fastapi import APIRouter, HTTPException
from firebase_admin import firestore
from pydantic import BaseModel

# Create a router, which is like a mini-FastAPI app
router = APIRouter()

# Define the data model for the incoming request
class RebateFilter(BaseModel):
    location: str
    income: float

# Define the endpoint at the root of this router (which will be /rebates)
@router.post("/")
async def get_rebates(filter: RebateFilter):
    """
    Fetches rebates from Firestore based on the user's location and income.
    Includes both state-specific and federal ("AUS") rebates.
    """
    try:
        db = firestore.client()
        
        # --- THIS IS THE ALTERED QUERY ---
        # It now checks if the rebate's location is either the user's state OR "AUS".
        query = db.collection("rebates") \
                  .where("location", "in", [filter.location, "AUS"]) \
                  .where("income_max", ">=", filter.income)
        
        docs = query.stream()
        rebates = [{"id": doc.id, **doc.to_dict()} for doc in docs]
        
        return {"rebates": rebates}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))