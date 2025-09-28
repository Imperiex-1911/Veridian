# backend/routes/chat.py
"""
Hardened chat route for calling an external LLM (Hugging Face).
Optional dependencies:
    pip install aioredis requests boto3 firebase-admin fastapi pydantic
Notes:
 - If REDIS_URL is set, rate limiting will use Redis.
 - Otherwise it will use an in-memory fallback (NOT recommended for multi-worker).
 - HF API token is read from env HUGGINGFACE_API_TOKEN or (optionally) AWS Secrets Manager if configured.
"""

import os
import logging
import time
import uuid
import json
import html
from typing import Optional, Tuple, Dict, Any
from collections import deque

import requests
from requests.adapters import HTTPAdapter, Retry

from fastapi import APIRouter, HTTPException, status
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel, validator

# Firestore import (your existing firebase-admin setup must be initialized elsewhere)
from firebase_admin import firestore

# Optional Redis
try:
    import aioredis
except Exception:
    aioredis = None  # fallback below

# Optional AWS secrets manager
try:
    import boto3
    from botocore.exceptions import BotoCoreError, ClientError
except Exception:
    boto3 = None

# --- Configuration ---
router = APIRouter()
logger = logging.getLogger("chat_route")
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

# Rate limit configuration
MAX_REQUESTS = int(os.getenv("CHAT_MAX_REQUESTS", 5))
TIMEFRAME_SECONDS = int(os.getenv("CHAT_TIMEFRAME_SECONDS", 60))
REDIS_URL = os.getenv("REDIS_URL")  # e.g. redis://localhost:6379/0

# Input limits
MAX_INPUT_LEN = int(os.getenv("CHAT_MAX_INPUT_LEN", 1000))

# Hugging Face configuration
HF_MODEL = os.getenv("HF_MODEL", "mistralai/Mistral-7B-Instruct-v0.2")
HF_API_URL = f"https://api-inference.huggingface.co/models/{HF_MODEL}"
HF_API_TOKEN = None  # will be resolved at startup/get_token()

# Requests session with retry/backoff
_session = requests.Session()
_retries = Retry(total=3, backoff_factor=0.6, status_forcelist=[429, 500, 502, 503, 504])
_session.mount("https://", HTTPAdapter(max_retries=_retries))


# --- Pydantic model ---
class ChatInput(BaseModel):
    user_id: str
    message: str

    @validator("user_id")
    def user_id_must_not_be_empty(cls, v):
        v = v.strip()
        if not v:
            raise ValueError("user_id cannot be empty")
        return v

    @validator("message")
    def message_length_and_strip(cls, v):
        if v is None:
            raise ValueError("message cannot be empty")
        v = v.strip()
        if not v:
            raise ValueError("message cannot be empty")
        if len(v) > MAX_INPUT_LEN:
            raise ValueError(f"message too long (max {MAX_INPUT_LEN} characters)")
        return v


# --- Rate limiter interfaces (async) ---
_redis = None
_inmemory_tracker: Dict[str, deque] = {}
_inmemory_lock = None  # set when used


async def init_redis():
    global _redis
    if REDIS_URL and aioredis:
        try:
            _redis = await aioredis.from_url(REDIS_URL, decode_responses=True)
            logger.info("Connected to Redis for rate limiting.")
        except Exception as e:
            logger.warning(f"Failed to connect to Redis at {REDIS_URL}: {e}")
            _redis = None


async def check_rate_limit(user_id: str):
    """
    Rate limit per user_id. Uses Redis if present, otherwise in-memory fallback.
    Raises HTTPException(429) if limit exceeded.
    """
    now = int(time.time())
    if _redis:
        key = f"rate:{user_id}"
        try:
            # use INCR and EXPIRE atomic operations
            count = await _redis.incr(key)
            if count == 1:
                await _redis.expire(key, TIMEFRAME_SECONDS)
            if count > MAX_REQUESTS:
                raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                                    detail="Too many requests. Please slow down.")
        except Exception as e:
            logger.exception("Redis error during rate limiting; falling back to in-memory.")
            await _check_rate_limit_inmemory(user_id, now)
    else:
        await _check_rate_limit_inmemory(user_id, now)


async def _check_rate_limit_inmemory(user_id: str, now_ts: int):
    """
    Simple in-memory rate limiter. Works only within single-process.
    """
    global _inmemory_lock
    import asyncio
    if _inmemory_lock is None:
        _inmemory_lock = asyncio.Lock()
    async with _inmemory_lock:
        q = _inmemory_tracker.get(user_id)
        if q is None:
            q = deque()
            _inmemory_tracker[user_id] = q
        # remove stale timestamps
        while q and q[0] < now_ts - TIMEFRAME_SECONDS:
            q.popleft()
        if len(q) >= MAX_REQUESTS:
            raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                                detail="Too many requests. Please slow down.")
        q.append(now_ts)


# --- Secrets management (HF token) ---
def _get_hf_token_from_env() -> Optional[str]:
    token = os.getenv("HUGGINGFACE_API_TOKEN")
    if token:
        return token.strip()
    return None


def _get_hf_token_from_aws(secret_name: str) -> Optional[str]:
    """
    Optionally fetch token from AWS Secrets Manager. Requires boto3 and permissions.
    secret_name is the name/arn of the secret storing {"HUGGINGFACE_API_TOKEN": "..."} or a plain string.
    """
    if not boto3:
        return None
    try:
        client = boto3.client("secretsmanager")
        resp = client.get_secret_value(SecretId=secret_name)
        secret_string = resp.get("SecretString", "")
        if not secret_string:
            return None
        try:
            data = json.loads(secret_string)
            return data.get("HUGGINGFACE_API_TOKEN")
        except json.JSONDecodeError:
            # secret might be the token directly
            return secret_string
    except (BotoCoreError, ClientError) as e:
        logger.warning(f"Unable to fetch secret {secret_name}: {e}")
        return None


def resolve_hf_token() -> Optional[str]:
    """
    Resolve HF token from environment or AWS Secrets Manager if configured.
    """
    # 1) environment variable
    token = _get_hf_token_from_env()
    if token:
        return token
    # 2) optional AWS secrets manager via env var name HF_SECRET_NAME
    secret_name = os.getenv("HF_SECRET_NAME")
    if secret_name:
        token = _get_hf_token_from_aws(secret_name)
        if token:
            return token
    return None


# --- Firestore helper (blocking) ---
def _fetch_user_context_sync(user_id: str) -> Tuple[dict, dict]:
    db = firestore.client()
    user_doc = db.collection("users").document(user_id).get()
    audit_query = db.collection("audits").where("user_id", "==", user_id).order_by("timestamp", direction=firestore.Query.DESCENDING).limit(1)
    audit_docs = list(audit_query.stream())

    user_profile = user_doc.to_dict() if user_doc.exists else {"note": "No profile found"}
    latest_audit = audit_docs[0].to_dict().get("answers", {}) if audit_docs else {}
    return user_profile, latest_audit


# --- Hugging Face (blocking) call with retry/timeouts handled by requests.Session ---
def _query_huggingface_sync(payload: dict, hf_token: str, timeout: int = 20) -> Dict[str, Any]:
    if not hf_token:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="AI service not configured")
    headers = {"Authorization": f"Bearer {hf_token}", "Accept": "application/json"}
    try:
        resp = _session.post(HF_API_URL, headers=headers, json=payload, timeout=timeout)
    except requests.RequestException as e:
        logger.exception("Network error calling HF API")
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=f"AI service network error: {str(e)}")

    # Non-200: convert to 502/503 depending on code
    if resp.status_code >= 500:
        logger.error(f"Hugging Face server error: {resp.status_code} {resp.text}")
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="AI service unavailable")
    if resp.status_code == 401 or resp.status_code == 403:
        logger.error(f"Authentication error with HF API: {resp.status_code} {resp.text}")
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="AI service authentication error")
    if resp.status_code >= 400:
        logger.error(f"Hugging Face client error: {resp.status_code} {resp.text}")
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="AI service error")

    try:
        return resp.json()
    except ValueError:
        logger.exception("Invalid JSON from HF API")
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="AI service returned invalid response")


# --- Utilities ---
def build_prompt(user_profile: dict, latest_audit: dict, user_message: str) -> str:
    """
    Use a strict template and escape user-provided text to reduce prompt injection risks.
    """
    safe_message = html.escape(user_message)
    # Use a clear instructive wrapper for instruct-style models
    parts = [
        "[INST]",
        "You are Veridian, a friendly AI home energy advisor. Provide concise, positive, and actionable advice about home energy efficiency ONLY. Do not ask for personal information or perform any actions.",
        "",
        f"User profile: {json.dumps(user_profile, ensure_ascii=False)}",
        f"Latest home audit: {json.dumps(latest_audit, ensure_ascii=False)}",
        "",
        f'User message: "{safe_message}"',
        "[/INST]"
    ]
    return "\n".join(parts)


def clean_model_reply(reply: str) -> str:
    """
    Remove leftover prompt content, control tokens, and leading/trailing whitespace.
    Keep it conservative: if model returns list/object, try to extract text fields.
    """
    if not reply:
        return ""

    # Some models return array-like JSON; if input is dict/list return stringified safe content
    if isinstance(reply, (dict, list)):
        try:
            # attempt to extract known field
            if isinstance(reply, list) and len(reply) and isinstance(reply[0], dict):
                # common HF output: [{"generated_text": "..."}, ...]
                candidate = reply[0].get("generated_text") or reply[0].get("text")
                if candidate:
                    reply = candidate
                else:
                    reply = json.dumps(reply)
            else:
                reply = json.dumps(reply)
        except Exception:
            reply = str(reply)

    # Ensure reply is a str now
    reply = str(reply)

    # If the model echoed the prompt, try to cut everything before the closing token
    if "[/INST]" in reply:
        reply = reply.split("[/INST]", 1)[-1]
    # Remove possible role markers
    for marker in ["<|assistant|>", "Assistant:", "User:", "System:"]:
        if marker in reply:
            # prefer content after marker if it's at start
            idx = reply.find(marker)
            if idx != -1 and idx < 200:
                reply = reply[idx + len(marker) :].strip()
    # Normalize whitespace
    reply = reply.strip()
    # Don't return empty string
    return reply or "(no content returned by model)"


# --- Startup resolver for HF token and Redis init (call externally or at import time) ---
def startup_resolve():
    global HF_API_TOKEN
    HF_API_TOKEN = resolve_hf_token()
    if not HF_API_TOKEN:
        logger.warning("Hugging Face token not found in environment. Set HUGGINGFACE_API_TOKEN or HF_SECRET_NAME.")
    # Initialize redis (sync call wrapper) - note: this is async; user should call init_redis in their startup event
    # Here we do nothing blocking; actual init_redis should be awaited in FastAPI on_startup.


startup_resolve()


# --- Route ---
@router.post("/", status_code=200)
async def handle_chat(input_data: ChatInput):
    """
    Main chat endpoint:
    - validates input (Pydantic)
    - enforces rate limiting (Redis preferred)
    - fetches user profile & audit from Firestore (in threadpool)
    - constructs safe prompt
    - queries Hugging Face with retries/timeouts
    - cleans and returns reply
    """
    request_id = str(uuid.uuid4())
    logger.info({"event": "chat_request", "request_id": request_id, "user_id": input_data.user_id})

    # Rate limit check (async; uses Redis if configured)
    try:
        await check_rate_limit(input_data.user_id)
    except HTTPException:
        logger.warning({"event": "rate_limited", "request_id": request_id, "user_id": input_data.user_id})
        raise

    # Fetch context from Firestore (blocking -> run_in_threadpool)
    try:
        user_profile, latest_audit = await run_in_threadpool(_fetch_user_context_sync, input_data.user_id)
    except Exception as e:
        logger.exception({"event": "firestore_error", "request_id": request_id, "user_id": input_data.user_id, "error": str(e)})
        # Consider returning 503 to indicate dependency problem
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Failed to read user data")

    # Build prompt safely
    try:
        prompt = build_prompt(user_profile, latest_audit, input_data.message)
    except Exception as e:
        logger.exception({"event": "prompt_build_error", "request_id": request_id, "error": str(e)})
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to build prompt")

    # Prepare payload for HF (adjust according to model API expected schema)
    # For many HF inference endpoints, {"inputs": prompt} is fine. Add params if needed.
    payload = {"inputs": prompt, "options": {"wait_for_model": True}}

    # Query HF in threadpool (blocking function)
    try:
        api_resp = await run_in_threadpool(_query_huggingface_sync, payload, HF_API_TOKEN)
    except HTTPException as he:
        # propagate known HTTPExceptions
        logger.error({"event": "hf_error", "request_id": request_id, "status_code": he.status_code, "detail": he.detail})
        raise
    except Exception as e:
        logger.exception({"event": "hf_unexpected_error", "request_id": request_id, "error": str(e)})
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="AI service failed")

    # Extract reply text robustly
    try:
        # HF outputs various shapes; try common ones
        reply_text = ""
        if isinstance(api_resp, dict):
            # some HF endpoints return {"generated_text": "..."} or nested lists
            # but more commonly it's a list
            if "generated_text" in api_resp:
                reply_text = api_resp.get("generated_text", "")
            else:
                # fallback: stringify
                reply_text = json.dumps(api_resp)
        elif isinstance(api_resp, list):
            first = api_resp[0] if api_resp else {}
            if isinstance(first, dict):
                reply_text = first.get("generated_text") or first.get("text") or first.get("generated_texts") or ""
            else:
                reply_text = str(first)
        else:
            reply_text = str(api_resp)
    except Exception:
        logger.exception({"event": "parse_hf_response_error", "request_id": request_id})
        reply_text = ""

    cleaned = clean_model_reply(reply_text)

    # Log and return
    logger.info({"event": "chat_response", "request_id": request_id, "user_id": input_data.user_id, "reply_len": len(cleaned)})
    return {"reply": cleaned, "request_id": request_id}
