# backend/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware # --- 1. IMPORT THIS ---
from routes import auth, users

app = FastAPI(title="Veridian API")

# --- 2. ADD THIS MIDDLEWARE BLOCK ---
# This block tells your backend that it's okay to accept requests
# from your Flutter web app, fixing the CORS error.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for simplicity in development
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all headers (like 'Authorization')
)
# --- END OF NEW BLOCK ---

# Your existing router configuration
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/users", tags=["Users"])

@app.get("/")
async def root():
    return {"message": "Veridian API"}