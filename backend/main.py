# backend/main.py
from fastapi import FastAPI

app = FastAPI(title="Veridian API")

@app.get("/")
async def root():
    return {"message": "Veridian API"}