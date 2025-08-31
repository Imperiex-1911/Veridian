# backend/config/db.py
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv
from pathlib import Path
import os
import json # <-- Import the JSON library

# This block robustly finds your .env file for local development
config_dir = Path(__file__).resolve().parent
backend_dir = config_dir.parent
dotenv_path = backend_dir / '.env'
load_dotenv(dotenv_path=dotenv_path)

# Load the credentials from the environment
cred_path_or_json = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
if not cred_path_or_json:
    raise ValueError("GOOGLE_APPLICATION_CREDENTIALS environment variable not set.")

# --- This is the new, smarter block for handling credentials ---
try:
    # First, try to treat the variable as JSON content
    cred_json = json.loads(cred_path_or_json)
    cred = credentials.Certificate(cred_json)
except json.JSONDecodeError:
    # If that fails, it must be a file path
    cred = credentials.Certificate(cred_path_or_json)


# --- This block initializes Firebase ONCE, preventing crashes ---
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app(cred)

db = firestore.client()