"""
JWT token creation and validation middleware.
Same JWT_SECRET is shared across all Ground Up APIs so any API can validate any token.
"""

from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from api.config import JWT_SECRET, JWT_ALGORITHM, JWT_EXPIRY_HOURS
from api.database import get_db
from api.models.user import User

security = HTTPBearer()


def create_access_token(user_id: str, role: str, name: str) -> str:
    """Create a JWT token for the given user."""
    expire = datetime.utcnow() + timedelta(hours=JWT_EXPIRY_HOURS)
    payload = {
        "sub": str(user_id),
        "role": role,
        "name": name,
        "exp": expire,
        "iat": datetime.utcnow(),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def decode_token(token: str) -> dict:
    """Decode and validate a JWT token. Raises HTTPException on failure."""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    """
    Dependency: extracts current user from JWT token.
    Use this in any route that requires authentication.
    """
    payload = decode_token(credentials.credentials)
    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
        )
    
    user = db.query(User).filter(User.id == user_id, User.active == True).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found or deactivated",
        )
    return user


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Dependency: requires the current user to have admin role."""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return current_user
