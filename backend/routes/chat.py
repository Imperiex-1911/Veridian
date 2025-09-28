# backend/routes/chat.py
import os
import logging
import time
import requests
from collections import deque
from fastapi import APIRouter, HTTPException
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel
from firebase_admin import firestore

# --- Setup ---
router = APIRouter()
logger = logging.getLogger(__name__)

# --- Pydantic Models ---
class ChatInput(BaseModel):
    user_id: str
    message: str

# --- Rate Limiter (Unchanged) ---
MAX_REQUESTS = 5
TIMEFRAME_SECONDS = 60
rate_limit_tracker = {}

# --- Hugging Face API Configuration ---
HF_API_TOKEN = os.getenv("HUGGINGFACE_API_TOKEN")
MODEL_NAME = "mistralai/Mistral-7B-Instruct-v0.2"
API_URL = f"https://api-inference.huggingface.co/models/{MODEL_NAME}"
headers = {"Authorization": f"Bearer {HF_API_TOKEN}"}

# --- Helper function for fetching data (Unchanged) ---
def _fetch_user_context_sync(user_id: str):
    db = firestore.client()
    user_doc = db.collection("users").document(user_id).get()
    audit_query = db.collection("audits").where("user_id", "==", user_id).order_by("timestamp", direction=firestore.Query.DESCENDING).limit(1)
    audit_docs = list(audit_query.stream())
    
    user_profile = user_doc.to_dict() if user_doc.exists else {"note": "No profile found"}
    latest_audit = audit_docs[0].to_dict().get("answers", {}) if audit_docs else {}
    
    return user_profile, latest_audit

# --- Helper function for calling Hugging Face API ---
def _query_huggingface_sync(payload):
    """Blocking function to make the API call."""
    response = requests.post(API_URL, headers=headers, json=payload)
    if response.status_code != 200:
        logger.error(f"Hugging Face API Error: {response.status_code} {response.text}")
        raise HTTPException(status_code=502, detail=f"AI service failed: {response.text}")
    return response.json()

@router.post("/")
async def handle_chat(input_data: ChatInput):
    if not HF_API_TOKEN:
        raise HTTPException(status_code=503, detail="AI service is not configured.")

    # --- Rate Limiter Logic (Unchanged) ---
    user_id = input_data.user_id
    current_time = time.time()
    if user_id not in rate_limit_tracker:
        rate_limit_tracker[user_id] = deque(maxlen=MAX_REQUESTS)
    while rate_limit_tracker[user_id] and rate_limit_tracker[user_id][0] < current_time - TIMEFRAME_SECONDS:
        rate_limit_tracker[user_id].popleft()
    if len(rate_limit_tracker[user_id]) >= MAX_REQUESTS:
        raise HTTPException(status_code=429, detail="Too Many Requests. Please try again later.")
    rate_limit_tracker[user_id].append(current_time)

    try:
        logger.info(f"Chat request from {user_id}: {input_data.message}")
        
        user_profile, latest_audit = await run_in_threadpool(_fetch_user_context_sync, user_id)

        # --- Build Prompt for an Instruct Model ---
        # Note: Instruct models often use specific formatting for prompts.
        prompt = f"""
        [INST]
        You are Veridian, a friendly AI home energy advisor. Your role is to provide concise, positive, and actionable advice based on the user's data. Focus ONLY on home energy efficiency.

        User Profile: {user_profile}
        Latest Home Audit: {latest_audit}

        Based on that data, answer the following question.
        [/INST]
        User message: "{input_data.message}"
        """
        
        # --- Call Hugging Face API ---
        api_response = await run_in_threadpool(_query_huggingface_sync, {"inputs": prompt})
        
        # Safely parse the response to find the generated text
        reply = api_response[0].get("generated_text", "")
        
        # The model often includes the prompt in its reply, so we clean it up.
        cleaned_reply = reply.split('[/INST]')[-1].strip()

        if not cleaned_reply:
            raise HTTPException(status_code=502, detail="AI service returned an empty response.")

        return {"reply": cleaned_reply}

    except Exception as e:
        logger.exception(f"Error processing chat request for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="An error occurred while processing your request.")