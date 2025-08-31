# backend/main.py
from fastapi import FastAPI
from routes import auth, users # Import the new users router

app = FastAPI(title="Veridian API")

app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/users", tags=["Users"]) # Add the users router

@app.get("/")
async def root():
    return {"message": "Veridian API"}