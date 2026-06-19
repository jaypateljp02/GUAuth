# Ground Up Auth API

Shared authentication service for the Ground Up Factory platform.  
All 4 mobile apps (Production, Task, Monitoring, Admin) use this API for login and user management.

## API Endpoints

### Authentication
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/auth/login` | Login with email + password → returns JWT | No |
| POST | `/auth/logout` | Logout (invalidate token) | Yes |
| GET | `/auth/profile` | Get current user profile | Yes |

### User Management (Admin Only)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/users` | List all users | Admin |
| GET | `/users/count` | Count active users | Yes |
| GET | `/users/{id}` | Get single user | Admin |
| POST | `/users` | Create new user | Admin |
| PUT | `/users/{id}` | Update user | Admin |
| POST | `/users/{id}/reset-password` | Reset password | Admin |

### Token
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/token/validate` | Validate JWT token | Yes |

## Local Setup

### Prerequisites
- Python 3.12+
- PostgreSQL 16+

### Steps
```bash
# 1. Create virtual environment
py -m venv venv
venv\Scripts\activate

# 2. Install dependencies
pip install -r api/requirements.txt

# 3. Set up database (PostgreSQL must be running)
psql -U postgres -c "CREATE DATABASE groundup;"
psql -U postgres -d groundup -f database/migrations/001_initial_schema.sql
psql -U postgres -d groundup -f database/seeds/001_seed_data.sql

# 4. Run the API
uvicorn api.main:app --reload --port 8000

# 5. Open docs
# http://localhost:8000/docs
```

### Test Login
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@groundup.app", "password": "admin123"}'
```

## Default Users

| Name | Email | Password | Role |
|------|-------|----------|------|
| Admin | admin@groundup.app | admin123 | admin |
| Employee 1 | employee1@groundup.app | employee123 | employee |
| Employee 2 | employee2@groundup.app | employee123 | employee |
| Employee 3 | employee3@groundup.app | employee123 | employee |
| Employee 4 | employee4@groundup.app | employee123 | employee |

## Deployment (DigitalOcean App Platform)

1. Connect this GitHub repo to DO App Platform
2. Set Source Directory to `/` (root)
3. Set environment variables:
   - `DATABASE_URL` = your managed PostgreSQL URL
   - `JWT_SECRET` = generate a strong secret
   - `DEBUG` = false
4. Deploy ✅
