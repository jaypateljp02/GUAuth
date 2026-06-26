"""
User management routes — Admin only.
Used by the Admin App to create, update, and deactivate employees.
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from api.database import get_db
from api.models.user import User
from api.middleware.jwt_auth import require_admin, get_current_user
from api.schemas import UserResponse, UserCreate, UserUpdate, MessageResponse

router = APIRouter(prefix="/users", tags=["Users"])

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


@router.get("", response_model=List[UserResponse])
def list_users(
    active: bool = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all users. Optionally filter by active status."""
    query = db.query(User)
    if active is not None:
        query = query.filter(User.active == active)
    return [UserResponse.model_validate(u) for u in query.all()]


@router.get("/count")
def count_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get count of active users. Used by Admin dashboard widget."""
    count = db.query(User).filter(User.active == True).count()
    return {"count": count}


@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    """Get a single user by ID. Admin only."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.model_validate(user)


@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(
    request: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    """Create a new user (employee or admin). Admin only."""
    # Check if email already exists
    existing = db.query(User).filter(User.email == request.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    user = User(
        name=request.name,
        email=request.email,
        password=pwd_context.hash(request.password),
        role=request.role,
        receive_reports=request.receive_reports if request.receive_reports is not None else True,
        preferred_locale=request.preferred_locale if request.preferred_locale is not None else "en",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return UserResponse.model_validate(user)


@router.put("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: str,
    request: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    """Update user details. Admin only. Can change name, email, role, active status."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if request.name is not None:
        user.name = request.name
        # Propagate name change to tasks.issue_messages history
        from sqlalchemy import text
        try:
            db.execute(
                text("UPDATE tasks.issue_messages SET sender_name = :new_name WHERE sender_id = :uid"),
                {"new_name": request.name, "uid": user.id}
            )
        except Exception as e:
            print(f"Failed to update historic sender names: {e}")
            
    if request.email is not None:
        user.email = request.email
    if request.role is not None:
        user.role = request.role
    if request.active is not None:
        user.active = request.active
    if request.preferred_locale is not None:
        user.preferred_locale = request.preferred_locale
    if request.receive_reports is not None:
        user.receive_reports = request.receive_reports

    db.commit()
    db.refresh(user)
    return UserResponse.model_validate(user)


@router.post("/{user_id}/reset-password", response_model=MessageResponse)
def reset_password(
    user_id: str,
    new_password: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    """Reset a user's password. Admin only."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.password = pwd_context.hash(new_password)
    db.commit()
    return MessageResponse(message=f"Password reset for {user.name}")


@router.get("/profile", response_model=UserResponse)
def get_profile(
    current_user: User = Depends(get_current_user),
):
    """Get the current logged-in user's profile."""
    return UserResponse.model_validate(current_user)


@router.put("/profile/locale", response_model=UserResponse)
def update_profile_locale(
    preferred_locale: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update the current user's preferred language."""
    if preferred_locale not in ["en", "hi", "mr", "bn"]:
        raise HTTPException(status_code=400, detail="Invalid language locale code. Must be one of en, hi, mr, bn.")
    
    current_user.preferred_locale = preferred_locale
    db.commit()
    db.refresh(current_user)
    return UserResponse.model_validate(current_user)

