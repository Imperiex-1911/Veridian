# backend/routes/auth.py
from fastapi import APIRouter, HTTPException, Depends
from firebase_admin import auth
from fastapi.security import OAuth2PasswordBearer

router = APIRouter()

# This dependency will look for an "Authorization: Bearer <TOKEN>" header
# and extract the token.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid token")

# This is a test endpoint to check if a user is authenticated.
@router.get("/me")
async def get_my_profile(current_user: dict = Depends(get_current_user)):
    # If the code reaches here, the token was valid.
    # 'current_user' contains the decoded token payload.
    uid = current_user.get("uid")
    email = current_user.get("email")
    return {"uid": uid, "email": email}