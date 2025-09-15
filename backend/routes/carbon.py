# backend/routes/carbon.py
from fastapi import APIRouter, HTTPException
from firebase_admin import firestore
from pydantic import BaseModel
from typing import Optional

# --- 1. TYPED MODEL FOR AUDIT ANSWERS ---
# This validates the data we get from Firestore, preventing errors.
class AuditAnswers(BaseModel):
    fridge_age: Optional[str] = None
    has_dryer: Optional[bool] = False
    has_dishwasher: Optional[bool] = False
    insulation: Optional[str] = None
    window_type: Optional[str] = None
    hvac_age: Optional[str] = None
    water_heater: Optional[str] = None
    has_solar: Optional[bool] = False

# This Pydantic model defines the expected input for the API endpoint
class CarbonInput(BaseModel):
    user_id: str

# This remains our central source of truth for emission data
EMISSION_FACTORS = {
    "appliances": {
        "fridge_age": {"old": 450, "medium": 250, "new": 100},
        "has_dryer": {True: 400, False: 0},
        "has_dishwasher": {True: 150, False: 0},
    },
    "heating_cooling": {
        "insulation": {"poor": 1000, "average": 500, "good": 100},
        "hvac_age": {"old": 600, "medium": 300, "new": 100},
    },
    "water_heater": {
        "water_heater": {"electric_storage": 600, "gas_storage": 300, "heat_pump_wh": 150},
    },
    "windows": {
        "window_type": {"single": 350, "double": 100},
    },
    "solar": {
        "has_solar": {True: -2000, False: 0},
    }
}

router = APIRouter()

# --- 2. PURE CALCULATION FUNCTION ---
# This logic is now completely separate from Firestore and the API.
# It's easy to test and maintain.
def calculate_emissions(answers: AuditAnswers) -> dict:
    """Calculates carbon emissions based on a validated AuditAnswers object."""
    emissions = {
        "appliances": 0.0, "heating_cooling": 0.0,
        "water_heater": 0.0, "windows": 0.0, "solar": 0.0
    }

    # Use the model's properties directly for type-safe access
    emissions["appliances"] += EMISSION_FACTORS["appliances"]["fridge_age"].get(answers.fridge_age, 100)
    emissions["appliances"] += EMISSION_FACTORS["appliances"]["has_dryer"].get(answers.has_dryer, 0)
    emissions["appliances"] += EMISSION_FACTORS["appliances"]["has_dishwasher"].get(answers.has_dishwasher, 0)
    
    emissions["heating_cooling"] += EMISSION_FACTORS["heating_cooling"]["insulation"].get(answers.insulation, 100)
    emissions["heating_cooling"] += EMISSION_FACTORS["heating_cooling"]["hvac_age"].get(answers.hvac_age, 100)

    emissions["water_heater"] += EMISSION_FACTORS["water_heater"]["water_heater"].get(answers.water_heater, 150)
    
    emissions["windows"] += EMISSION_FACTORS["windows"]["window_type"].get(answers.window_type, 100)
    
    emissions["solar"] += EMISSION_FACTORS["solar"]["has_solar"].get(answers.has_solar, 0)

    emissions["total"] = sum(emissions.values())
    return emissions


# --- 3. CLEANER, MORE ROBUST API ENDPOINT ---
@router.post("/calculate")
async def get_carbon_footprint(input_data: CarbonInput):
    """
    API endpoint to fetch an audit, validate its answers, and calculate the
    carbon footprint using the separated business logic.
    """
    try:
        db = firestore.client()
        docs_query = db.collection("audits") \
            .where("user_id", "==", input_data.user_id) \
            .order_by("timestamp", direction=firestore.Query.DESCENDING) \
            .limit(1)
        
        docs = list(docs_query.stream())
        if not docs:
            raise HTTPException(status_code=404, detail="No audit found for this user.")

        # Get the raw answers dictionary from Firestore
        raw_answers = docs[0].to_dict().get("answers", {})
        
        # Validate and parse the raw data into our Pydantic model
        validated_answers = AuditAnswers(**raw_answers)
        
        # Call the pure function with the validated data
        emissions = calculate_emissions(validated_answers)
        
        return {"emissions": emissions}
    
    except HTTPException:
        raise  # Re-raise known HTTP exceptions (like the 404)
    except Exception as e:
        # Catch any other unexpected errors and return a generic 500
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")