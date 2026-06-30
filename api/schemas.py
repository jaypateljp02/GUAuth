"""
Pydantic schemas for request/response validation.
Keeps API contracts clean and documented.
"""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr


# --- Auth Schemas ---

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


# --- User Schemas ---

class UserResponse(BaseModel):
    id: UUID
    name: str
    email: str
    role: str
    active: bool
    created_at: Optional[datetime] = None
    preferred_locale: Optional[str] = "en"
    receive_reports: Optional[bool] = True

    class Config:
        from_attributes = True


class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str = "employee"
    receive_reports: Optional[bool] = True
    preferred_locale: Optional[str] = "en"


class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    role: Optional[str] = None
    active: Optional[bool] = None
    preferred_locale: Optional[str] = None
    receive_reports: Optional[bool] = None


class MessageResponse(BaseModel):
    message: str
