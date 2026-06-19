"""
Application configuration — loaded from environment variables.
For local development, uses .env file. In production (DigitalOcean), set via App Platform env vars.
"""

import os
from dotenv import load_dotenv

load_dotenv()

# Database
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:1234@localhost:5432/groundup"
)

# JWT Settings
JWT_SECRET = os.getenv("JWT_SECRET", "ground-up-dev-secret-change-in-production")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_EXPIRY_HOURS = int(os.getenv("JWT_EXPIRY_HOURS", "72"))

# App Settings
APP_NAME = "Ground Up Auth API"
APP_VERSION = "1.0.0"
DEBUG = os.getenv("DEBUG", "true").lower() == "true"

# CORS — allow all origins in dev, restrict in production
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")
