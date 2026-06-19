"""
Ground Up Auth API — Main Application Entry Point.

This is the shared authentication service for all Ground Up Factory apps.
All 4 mobile apps (Production, Task, Monitoring, Admin) call this API for:
  - User login (POST /auth/login)
  - Token validation (GET /token/validate)
  - User management (admin-only CRUD on /users)
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.config import APP_NAME, APP_VERSION, CORS_ORIGINS, DEBUG
from api.routes import auth, users, token

# Create the FastAPI app
app = FastAPI(
    title=APP_NAME,
    version=APP_VERSION,
    description="Shared authentication service for Ground Up Factory platform",
    docs_url="/docs" if DEBUG else None,  # Disable docs in production
    redoc_url="/redoc" if DEBUG else None,
)

# CORS — allow mobile apps and other APIs to call this service
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(token.router)


@app.get("/", tags=["Health"])
def health_check():
    """Health check endpoint. DigitalOcean App Platform uses this."""
    return {
        "status": "healthy",
        "service": APP_NAME,
        "version": APP_VERSION,
    }


@app.get("/health", tags=["Health"])
def health():
    """Alternative health endpoint."""
    return {"status": "ok"}
