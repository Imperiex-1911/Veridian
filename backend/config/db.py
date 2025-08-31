# backend/config/db.py
import firebase_admin
from firebase_admin import credentials, firestore
import os

# --- This block now uses a direct, hardcoded path ---
# NOTE: This is for debugging or specific local setups.
# The .env file is NOT used by this configuration.

cred_path = "C:/Home_audit/Veridian/backend/serviceAccountKey.json"

# A quick check to make sure the hardcoded file path actually exists.
if not os.path.exists(cred_path):
    raise FileNotFoundError(
        f"The specified service account key file was not found at the hardcoded path: {cred_path}"
    )

# --- This block initializes Firebase ONCE, preventing crashes during hot-reload ---
try:
    # Check if the app is already initialized to prevent errors
    firebase_admin.get_app()
except ValueError:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()