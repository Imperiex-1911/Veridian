# backend/seed_contractors.py
import os
import sys
import logging
from typing import List, Dict, Any

from firebase_admin import credentials, firestore, initialize_app
from dotenv import load_dotenv

# ----------------------------
# Setup logging
# ----------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

# ----------------------------
# Load environment variables
# ----------------------------
load_dotenv()
key_path = os.getenv("FIREBASE_KEY_PATH")

if not key_path:
    logger.error("FIREBASE_KEY_PATH not set. Please create a .env file with the path to your service account JSON.")
    sys.exit(1)

# ----------------------------
# Initialize Firebase
# ----------------------------
cred = credentials.Certificate(key_path)
try:
    initialize_app(cred)
except ValueError:
    # Avoid "App already initialized" error if re-run
    pass

db = firestore.client()

# ----------------------------
# Seed data
# ----------------------------
CONTRACTORS: List[Dict[str, Any]] = [
    {
        "id": "vic_solar_pros",
        "name": "Melbourne Solar & Battery",
        "services": ["solar", "battery", "hot_water"],
        "location": "VIC",
        "contact": "sales@msb.com.au",
        "rating": 4.8,
    },
    {
        "id": "nsw_insulation_kings",
        "name": "Sydney Insulation & Windows",
        "services": ["insulation", "windows"],
        "location": "NSW",
        "contact": "contact@insulationkings.com.au",
        "rating": 4.6,
    },
    {
        "id": "qld_ev_charge",
        "name": "Brisbane EV Charging Solutions",
        "services": ["ev_charger", "solar"],
        "location": "QLD",
        "contact": "support@qldev.com.au",
        "rating": 4.9,
    },
    {
        "id": "vic_energy_upgrades",
        "name": "VIC Energy Upgraders",
        "services": ["heating_cooling", "lighting", "insulation"],
        "location": "VIC",
        "contact": "quotes@veu.net.au",
        "rating": 4.5,
    },
    {
        "id": "sa_home_comfort",
        "name": "Adelaide Home Comfort",
        "services": ["heating_cooling", "windows"],
        "location": "SA",
        "contact": "info@adelaidecomfort.com.au",
        "rating": 4.7,
    },
    {
        "id": "aussie_green_savers",
        "name": "Aussie Green Savers",
        "services": ["energy_audit", "solar", "insulation"],
        "location": "AUS",  # A national provider
        "contact": "help@aussiesavers.com",
        "rating": 4.8,
    },
]

# ----------------------------
# Helper functions
# ----------------------------
def validate_contractor(contractor: Dict[str, Any]) -> bool:
    """Basic validation for contractor data."""
    required_fields = {"id", "name", "services", "location", "contact", "rating"}
    missing = required_fields - contractor.keys()
    if missing:
        logger.warning(f"Contractor {contractor.get('id', '?')} missing fields: {missing}")
        return False
    if not isinstance(contractor["services"], list):
        logger.warning(f"Contractor {contractor['id']} has invalid services format.")
        return False
    if not (0 <= contractor["rating"] <= 5):
        logger.warning(f"Contractor {contractor['id']} has invalid rating: {contractor['rating']}")
        return False
    return True


def seed_contractors(data: List[Dict[str, Any]]):
    """Insert contractors into Firestore with validation and error handling."""
    logger.info("Starting contractor seeding...")

    for contractor in data:
        if not validate_contractor(contractor):
            logger.error(f"Skipping invalid contractor: {contractor}")
            continue

        try:
            # Use set(..., merge=True) so reruns don’t overwrite everything blindly
            db.collection("contractors").document(contractor["id"]).set(contractor, merge=True)
            logger.info(f"Seeded: {contractor['id']}")
        except Exception as e:
            logger.exception(f"Failed to seed {contractor['id']}: {e}")

    logger.info("Contractor seeding complete.")


# ----------------------------
# Entry point
# ----------------------------
if __name__ == "__main__":
    try:
        seed_contractors(CONTRACTORS)
    except Exception as e:
        logger.exception(f"Unexpected error during seeding: {e}")
        sys.exit(1)
