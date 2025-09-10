# backend/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import auth, users, rebates # 1. IMPORT THE NEW REBATES ROUTER

app = FastAPI(title="Veridian API")

# Your CORS middleware (no changes here)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Your Router Configuration ---
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(rebates.router, prefix="/rebates", tags=["Rebates"]) # 2. ADD THE REBATES ROUTER

@app.get("/")
async def root():
    return {"message": "Veridian API"}