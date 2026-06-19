"""
Token validation endpoint.
Other APIs (Production, Task, Monitoring) call this to verify JWT tokens
without needing to share the JWT secret directly.
"""

from fastapi import APIRouter, Depends

from api.middleware.jwt_auth import get_current_user
from api.models.user import User
from api.schemas import UserResponse

router = APIRouter(prefix="/token", tags=["Token Validation"])


@router.get("/validate", response_model=UserResponse)
def validate_token(current_user: User = Depends(get_current_user)):
    """
    Validate a JWT token and return the user info.
    
    Other APIs can call this endpoint to verify a token is valid:
      GET https://auth-api.groundup.app/token/validate
      Authorization: Bearer <token>
    
    Returns the user object if valid, 401 if invalid.
    """
    return UserResponse.model_validate(current_user)
