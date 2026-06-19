"""
Application configuration — loaded from environment variables.
For local development, uses .env file. In production (DigitalOcean), set via App Platform env vars.
"""

import os
from dotenv import load_dotenv

load_dotenv()

# Database
# Render supplies DATABASE_URL with the legacy "postgres://" scheme.
# SQLAlchemy 2.0 only accepts "postgresql://", so we normalise here.
_raw_db_url = os.getenv("DATABASE_URL", "postgresql://postgres:1234@localhost:5432/groundup")
DATABASE_URL = _raw_db_url.replace("postgres://", "postgresql://", 1) if _raw_db_url.startswith("postgres://") else _raw_db_url

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
