"""
User model — stored in the 'auth' schema.
Shared across all 4 apps via JWT tokens.
"""

import uuid
from datetime import datetime

from sqlalchemy import Column, String, Boolean, DateTime, Enum
from sqlalchemy.dialects.postgresql import UUID

from api.database import Base


class User(Base):
    __tablename__ = "users"
    __table_args__ = {"schema": "auth"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, nullable=False)
    password = Column(String(255), nullable=False)  # bcrypt hashed
    role = Column(
        Enum("employee", "admin", name="user_role", schema="auth"),
        nullable=False,
        default="employee"
    )
    active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    preferred_locale = Column(String(10), nullable=True, default="en")
    receive_reports = Column(Boolean, default=True)

    def __repr__(self):
        return f"<User {self.name} ({self.role})>"
