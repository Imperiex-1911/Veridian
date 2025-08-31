# backend/scripts/seed.py
import firebase_admin
from firebase_admin import credentials, firestore, initialize_app
import os
from pathlib import Path

# --- START OF TEMPORARY DEBUGGING BLOCK ---

print("--- RUNNING IN DEBUG MODE ---")

# Please double-check that this path is EXACTLY correct on your system.
cred_path = "C:/Home_audit/Veridian/backend/serviceAccountKey.json"

# This check will give us a clearer error if the path is still wrong.
if not os.path.exists(cred_path):
    raise FileNotFoundError(f"DEBUG CHECK FAILED: The system cannot find the file at the hardcoded path: {cred_path}")

print(f"DEBUG: Successfully found credentials file at the hardcoded path.")
# --- END OF TEMPORARY DEBUGGING BLOCK ---


# Initialize Firebase with the hardcoded path
cred = credentials.Certificate(cred_path)

try:
    firebase_admin.get_app()
except ValueError:
    initialize_app(cred)

db = firestore.client()
print("Firestore client initialized.")

# ... the rest of your file (seeding data) stays the same ...

try:
    # Check if the app is already initialized to prevent errors
    firebase_admin.get_app()
except ValueError:
    initialize_app(cred)

db = firestore.client()
print("Firestore client initialized.")

# Data for seeding
users_data = {
    "email": "test@veridian.com",
    "location": "CA, 90210",
    "home_size_sqft": 2000,
    "family_size": 4,
    "annual_income": 80000,
    "monthly_energy_bill": 150
}

rebates_data = {
    "title": "Veridian Solar Rebate",
    "amount": 5000,
    "eligibility_criteria": {"location": ["CA"], "income_max": 100000},
    "application_url": "http://example.com"
}

contractors_data = {
    "name": "Veridian Solar Co",
    "services": ["solar", "HVAC"],
    "location": "CA",
    "contact_email": "contact@veridiansolar.com",
    "website": "http://veridiansolar.com"
}

# Seeding logic
db.collection("users").document("test-user").set(users_data)
print("Seeded test-user.")

db.collection("rebates").document("rebate_001").set(rebates_data)
print("Seeded rebate_001.")

db.collection("contractors").document("contractor_001").set(contractors_data)
print("Seeded contractor_001.")

print("\nTest data seeded successfully!")