from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import auth, users, rebates, carbon # 1. Import carbon router

app = FastAPI(title="Veridian API")

# Your CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include all your routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(rebates.router, prefix="/rebates", tags=["Rebates"])
app.include_router(carbon.router, prefix="/carbon", tags=["Carbon"]) # 2. Include carbon router

@app.get("/")
async def root():
    return {"message": "Veridian API"}