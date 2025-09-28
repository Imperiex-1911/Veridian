# backend/routes/chat.py
import os
import logging
import time
from collections import deque
from fastapi import APIRouter, HTTPException, status
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel
from firebase_admin import firestore
import google.generativeai as genai
from google.api_core import exceptions as google_exceptions

# --- Configuration ---
router = APIRouter()
logger = logging.getLogger("chat_route")

# Rate limit configuration
MAX_REQUESTS = int(os.getenv("CHAT_MAX_REQUESTS", 5))
TIMEFRAME_SECONDS = int(os.getenv("CHAT_TIMEFRAME_SECONDS", 60))

# --- Gemini API Configuration ---
try:
    gemini_api_key = os.getenv("GEMINI_API_KEY")
    if not gemini_api_key:
        raise ValueError("GEMINI_API_KEY environment variable not set.")
    genai.configure(api_key=gemini_api_key)
    model = genai.GenerativeModel('gemini-1.0-pro')
    logger.info("Gemini API configured successfully.")
except Exception as e:
    logger.error(f"Failed to configure Gemini API: {e}")
    model = None

# --- Pydantic Model ---
class ChatInput(BaseModel):
    user_id: str
    message: str

# --- Rate Limiter ---
rate_limit_tracker = {}

# --- Helper Functions (Blocking) ---
def _fetch_user_context_sync(user_id: str):
    """Fetches user profile and latest audit from Firestore."""
    db = firestore.client()
    user_doc = db.collection("users").document(user_id).get()
    audit_query = db.collection("audits").where("user_id", "==", user_id).order_by("timestamp", direction=firestore.Query.DESCENDING).limit(1)
    audit_docs = list(audit_query.stream())
    
    user_profile = user_doc.to_dict() if user_doc.exists else {"note": "No profile found"}
    latest_audit = audit_docs[0].to_dict().get("answers", {}) if audit_docs else {}
    
    return user_profile, latest_audit

def _generate_gemini_content_sync(prompt: str):
    """Calls the Gemini API to generate content."""
    try:
        response = model.generate_content(prompt)
        return response.text
    except google_exceptions.GoogleAPICallError as e:
        logger.error(f"Google API Call Error: {e}")
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=f"AI service call failed: {e.message}")
    except Exception as e:
        logger.exception(f"Unexpected error during Gemini API call: {e}")
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="An unexpected error occurred with the AI service.")

@router.post("/")
async def handle_chat(input_data: ChatInput):
    if not model:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="AI service is not configured or available.")

    # --- Rate Limiter ---
    user_id = input_data.user_id
    current_time = time.time()
    if user_id not in rate_limit_tracker:
        rate_limit_tracker[user_id] = deque(maxlen=MAX_REQUESTS)
    while rate_limit_tracker[user_id] and rate_limit_tracker[user_id][0] < current_time - TIMEFRAME_SECONDS:
        rate_limit_tracker[user_id].popleft()
    if len(rate_limit_tracker[user_id]) >= MAX_REQUESTS:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="Too Many Requests.")
    rate_limit_tracker[user_id].append(current_time)

    try:
        logger.info(f"Chat request from {user_id}: {input_data.message}")
        
        # Fetch data in a threadpool to avoid blocking
        user_profile, latest_audit = await run_in_threadpool(_fetch_user_context_sync, user_id)

        # Build a hardened prompt
        system_prompt = """
        You are Veridian, a friendly AI home energy advisor.
        - Provide concise, positive, safe, and actionable advice based on the user's data.
        - Focus ONLY on home energy efficiency, sustainability, and related savings.
        - Politely decline any requests that are off-topic.
        """
        prompt = f"{system_prompt}\n\nUser Profile: {user_profile}\nLatest Home Audit: {latest_audit}\n\nUser message: \"{input_data.message}\""
        
        # Generate content in a threadpool
        reply = await run_in_threadpool(_generate_gemini_content_sync, prompt)

        if not reply:
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="AI service returned an empty response.")

        return {"reply": reply}

    except HTTPException:
        raise # Re-raise HTTPException to preserve status code and detail
    except Exception as e:
        logger.exception(f"Error processing chat request for user {user_id}: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="An error occurred while processing your request.")