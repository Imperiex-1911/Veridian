# backend/main.py
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import auth, users, rebates, carbon, contractors

# ----------------------------
# Logging Configuration
# ----------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("veridian")

# ----------------------------
# App Initialization
# ----------------------------
app = FastAPI(
    title="Veridian API",
    version="1.0.0",
    description="API for rebates, contractors, carbon tracking, and user management."
)

# ----------------------------
# Middleware
# ----------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TIP: Replace '*' with specific domains in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------------------
# Routers
# ----------------------------
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(rebates.router, prefix="/rebates", tags=["Rebates"])
app.include_router(carbon.router, prefix="/carbon", tags=["Carbon"])
app.include_router(contractors.router, prefix="/contractors", tags=["Contractors"])

# ----------------------------
# Root Endpoint
# ----------------------------
@app.get("/", tags=["Health"])
async def root():
    """
    Health check endpoint for the Veridian API.
    """
    logger.info("Health check requested.")
    return {"message": "Veridian API is running"}
