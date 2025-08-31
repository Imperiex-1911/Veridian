# backend/config/db.py
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv
from pathlib import Path
import os

# This block robustly finds your .env file by creating an absolute path to it
config_dir = Path(__file__).resolve().parent
backend_dir = config_dir.parent
dotenv_path = backend_dir / '.env'
load_dotenv(dotenv_path=dotenv_path)

# Load the credentials path from the environment
cred_path_or_json = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
if not cred_path_or_json:
    raise ValueError("GOOGLE_APPLICATION_CREDENTIALS environment variable not set or .env file not found.")

# This block initializes Firebase ONCE, preventing crashes during hot-reload
try:
    firebase_admin.get_app()
except ValueError:
    cred = credentials.Certificate(cred_path_or_json)
    firebase_admin.initialize_app(cred)

db = firestore.client()