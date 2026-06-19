"""
PostgreSQL database connection using SQLAlchemy.
Uses the 'auth' schema for users, roles, and sessions.
"""

from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, declarative_base
from api.config import DATABASE_URL

engine = create_engine(DATABASE_URL, pool_pre_ping=True)

# Set the search_path to 'auth' schema for this API
@event.listens_for(engine, "connect")
def set_search_path(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("SET search_path TO auth, public")
    cursor.close()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """Dependency that provides a database session per request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
