# backend/routes/users.py
from fastapi import APIRouter, HTTPException
from config.db import db

router = APIRouter()

@router.get("/{user_id}")
async def get_user(user_id: str):
    doc_ref = db.collection("users").document(user_id)
    doc = doc_ref.get()
    if doc.exists:
        return doc.to_dict()
    raise HTTPException(status_code=404, detail="User not found")