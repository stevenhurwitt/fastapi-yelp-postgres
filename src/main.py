from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .core.config import settings
from .db.database import init_db
from .api import business_routes, review_routes, user_routes, tip_routes, checkin_routes

# Create FastAPI application
app = FastAPI(
    title=settings.api_title,
    description=settings.api_description,
    version=settings.api_version,
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000", 
        "http://192.168.0.9:3000",
        "*"  # Allow all origins for development
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# Include routers
app.include_router(business_routes.router, prefix="/api/v1/businesses", tags=["businesses"])
app.include_router(review_routes.router, prefix="/api/v1/reviews", tags=["reviews"])
app.include_router(user_routes.router, prefix="/api/v1/users", tags=["users"])
app.include_router(tip_routes.router, prefix="/api/v1/tips", tags=["tips"])
app.include_router(checkin_routes.router, prefix="/api/v1/checkins", tags=["checkins"])

@app.on_event("startup")
def startup_event():
    """Initialize database on startup"""
    init_db()

@app.get("/")
def read_root():
    """Root endpoint"""
    return {
        "message": "Welcome to Yelp Data API",
        "version": settings.api_version,
        "docs": "/docs"
    }

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}