# backend/routes/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from firebase_admin import auth

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token") # This is used by FastAPI's docs

# Dependency to verify the Firebase token
async def verify_firebase_token(token: str = Depends(oauth2_scheme)):
    try:
        # The Authorization header from Flutter will be "Bearer <token>"
        # The oauth2_scheme dependency automatically extracts the <token> part for you.
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication credentials: {e}",
            headers={"WWW-Authenticate": "Bearer"},
        )

# --- THIS IS THE CORRECTED LINE ---
# Change @router.get("/me") to @router.post("/me")
@router.post("/me")
async def get_me(current_user: dict = Depends(verify_firebase_token)):
    """
    Verifies the Firebase ID token and returns the user's details.
    """
    return {"uid": current_user["uid"], "email": current_user.get("email")}