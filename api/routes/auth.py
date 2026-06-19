"""
Authentication routes: login, logout, profile.
These are called by ALL 4 mobile apps for user login.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from api.database import get_db
from api.models.user import User
from api.middleware.jwt_auth import create_access_token, get_current_user
from api.schemas import LoginRequest, LoginResponse, UserResponse, MessageResponse

router = APIRouter(prefix="/auth", tags=["Authentication"])

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


@router.post("/login", response_model=LoginResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    """
    Login with email + password. Returns JWT token.
    Used by all 4 apps (Production, Task, Monitoring, Admin).
    """
    user = db.query(User).filter(
        User.email == request.email,
        User.active == True
    ).first()

    if not user or not pwd_context.verify(request.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    token = create_access_token(
        user_id=str(user.id),
        role=user.role,
        name=user.name,
    )

    return LoginResponse(
        access_token=token,
        user=UserResponse.model_validate(user),
    )


@router.post("/logout", response_model=MessageResponse)
def logout(current_user: User = Depends(get_current_user)):
    """
    Logout. In a JWT system, the client simply discards the token.
    This endpoint exists for completeness and can be extended
    to blacklist tokens if needed.
    """
    return MessageResponse(message="Logged out successfully")


@router.get("/profile", response_model=UserResponse)
def get_profile(current_user: User = Depends(get_current_user)):
    """Get the current logged-in user's profile."""
    return UserResponse.model_validate(current_user)
