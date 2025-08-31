# backend/scripts/seed.py
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv
from pathlib import Path
import os

print("Attempting to initialize Firebase and seed data...")

# This block robustly finds your .env file
backend_dir = Path(__file__).resolve().parent.parent
dotenv_path = backend_dir / '.env'
load_dotenv(dotenv_path=dotenv_path)

cred_path_or_json = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
if not cred_path_or_json:
    raise ValueError("Failed to load GOOGLE_APPLICATION_CREDENTIALS from .env file.")

# This block initializes Firebase ONCE
try:
    firebase_admin.get_app()
except ValueError:
    cred = credentials.Certificate(cred_path_or_json)
    firebase_admin.initialize_app(cred)

db = firestore.client()
print("Firestore client initialized successfully.")

# --- This block seeds your data ---
users_data = {
    "email": "test@veridian.com", "location": "CA, 90210", "home_size_sqft": 2000,
    "family_size": 4, "annual_income": 80000, "monthly_energy_bill": 150
}
rebates_data = {
    "title": "Veridian Solar Rebate", "amount": 5000,
    "eligibility_criteria": {"location": ["CA"], "income_max": 100000},
    "application_url": "http://example.com"
}
contractors_data = {
    "name": "Veridian Solar Co", "services": ["solar", "HVAC"], "location": "CA",
    "contact_email": "contact@veridiansolar.com", "website": "http://veridiansolar.com"
}

db.collection("users").document("test-user").set(users_data)
print("- Seeded test-user.")
db.collection("rebates").document("rebate_001").set(rebates_data)
print("- Seeded rebate_001.")
db.collection("contractors").document("contractor_001").set(contractors_data)
print("- Seeded contractor_001.")

print("\n✅ Test data seeded successfully!")