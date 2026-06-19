-- =====================================================
-- Ground Up Factory — Complete Database Schema V1.0
-- Run this ONCE to set up all schemas and tables.
-- =====================================================

-- =====================================================
-- 1. CREATE SCHEMAS
-- =====================================================
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS production;
CREATE SCHEMA IF NOT EXISTS tasks;
CREATE SCHEMA IF NOT EXISTS monitoring;


-- =====================================================
-- 2. AUTH SCHEMA — Users, roles, sessions
-- =====================================================

-- User role enum
DO $$ BEGIN
    CREATE TYPE auth.user_role AS ENUM ('employee', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Users table
CREATE TABLE IF NOT EXISTS auth.users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(150) UNIQUE NOT NULL,
    password    VARCHAR(255) NOT NULL,  -- bcrypt hashed
    role        auth.user_role NOT NULL DEFAULT 'employee',
    active      BOOLEAN DEFAULT true,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =====================================================
-- 3. PRODUCTION SCHEMA — Products, recipes, ingredients
-- =====================================================

-- Products
CREATE TABLE IF NOT EXISTS production.products (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(150) NOT NULL,
    category    VARCHAR(100),
    room        VARCHAR(50),
    description TEXT,
    active      BOOLEAN DEFAULT true,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Recipes (each product can have multiple versions)
CREATE TABLE IF NOT EXISTS production.recipes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id  UUID NOT NULL REFERENCES production.products(id) ON DELETE CASCADE,
    version     INTEGER DEFAULT 1,
    base_qty    DECIMAL NOT NULL DEFAULT 1.0,
    base_unit   VARCHAR(20) DEFAULT 'kg',
    notes       TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Recipe ingredients
CREATE TABLE IF NOT EXISTS production.recipe_ingredients (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id   UUID NOT NULL REFERENCES production.recipes(id) ON DELETE CASCADE,
    ingredient  VARCHAR(150) NOT NULL,
    quantity    DECIMAL NOT NULL,
    unit        VARCHAR(20) NOT NULL,
    order_index INTEGER DEFAULT 0
);

-- Production steps
CREATE TABLE IF NOT EXISTS production.production_steps (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id      UUID NOT NULL REFERENCES production.products(id) ON DELETE CASCADE,
    step_number     INTEGER NOT NULL,
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    duration_min    INTEGER  -- estimated minutes, optional
);

-- Question status enum
DO $$ BEGIN
    CREATE TYPE production.question_status AS ENUM ('open', 'answered', 'closed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Questions from employees
CREATE TABLE IF NOT EXISTS production.questions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES auth.users(id),
    product_id  UUID REFERENCES production.products(id),
    question    TEXT NOT NULL,
    voice_url   VARCHAR(255),
    status      production.question_status DEFAULT 'open',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Question photos
CREATE TABLE IF NOT EXISTS production.question_photos (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES production.questions(id) ON DELETE CASCADE,
    photo_url   VARCHAR(255) NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Question replies
CREATE TABLE IF NOT EXISTS production.question_replies (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES production.questions(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES auth.users(id),
    reply       TEXT NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =====================================================
-- 4. TASKS SCHEMA — Tasks, updates, issues
-- =====================================================

-- Task type enum
DO $$ BEGIN
    CREATE TYPE tasks.task_type AS ENUM ('daily', 'weekly', 'one_time');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Task status enum
DO $$ BEGIN
    CREATE TYPE tasks.task_status AS ENUM ('pending', 'in_progress', 'done', 'skipped');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Tasks
CREATE TABLE IF NOT EXISTS tasks.tasks (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title       VARCHAR(200) NOT NULL,
    description TEXT,
    assigned_to UUID NOT NULL REFERENCES auth.users(id),
    type        tasks.task_type NOT NULL DEFAULT 'one_time',
    status      tasks.task_status NOT NULL DEFAULT 'pending',
    due_date    DATE,
    created_by  UUID NOT NULL REFERENCES auth.users(id),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Task updates (progress reports from employees)
CREATE TABLE IF NOT EXISTS tasks.task_updates (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id     UUID NOT NULL REFERENCES tasks.tasks(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES auth.users(id),
    update_text TEXT,
    voice_url   VARCHAR(255),
    photo_url   VARCHAR(255),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Issue status enum
DO $$ BEGIN
    CREATE TYPE tasks.issue_status AS ENUM ('open', 'in_review', 'resolved');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Issues (can be linked to a task or standalone)
CREATE TABLE IF NOT EXISTS tasks.issues (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id     UUID REFERENCES tasks.tasks(id),  -- optional link
    user_id     UUID NOT NULL REFERENCES auth.users(id),
    title       VARCHAR(200) NOT NULL,
    description TEXT,
    status      tasks.issue_status DEFAULT 'open',
    photo_url   VARCHAR(255),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications
CREATE TABLE IF NOT EXISTS tasks.notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES auth.users(id),
    title       VARCHAR(200) NOT NULL,
    message     TEXT,
    read        BOOLEAN DEFAULT false,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =====================================================
-- 5. MONITORING SCHEMA — Rooms, sensors, readings, alerts
-- =====================================================

-- Room type enum
DO $$ BEGIN
    CREATE TYPE monitoring.room_type AS ENUM ('room', 'fridge', 'freezer');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Rooms (includes fridges and freezers)
CREATE TABLE IF NOT EXISTS monitoring.rooms (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    type        monitoring.room_type NOT NULL,
    description TEXT,
    active      BOOLEAN DEFAULT true,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sensor type enum
DO $$ BEGIN
    CREATE TYPE monitoring.sensor_type AS ENUM ('temperature', 'humidity');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Sensors
CREATE TABLE IF NOT EXISTS monitoring.sensors (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id         UUID NOT NULL REFERENCES monitoring.rooms(id) ON DELETE CASCADE,
    type            monitoring.sensor_type NOT NULL,
    min_threshold   DECIMAL,  -- alert if reading below this
    max_threshold   DECIMAL,  -- alert if reading above this
    active          BOOLEAN DEFAULT true,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sensor readings (time-series data)
CREATE TABLE IF NOT EXISTS monitoring.sensor_readings (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id   UUID NOT NULL REFERENCES monitoring.sensors(id) ON DELETE CASCADE,
    value       DECIMAL NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Alerts
CREATE TABLE IF NOT EXISTS monitoring.alerts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id   UUID NOT NULL REFERENCES monitoring.sensors(id),
    value       DECIMAL NOT NULL,  -- the reading that triggered the alert
    message     TEXT,
    resolved    BOOLEAN DEFAULT false,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =====================================================
-- 6. INDEXES for performance
-- =====================================================

-- Auth
CREATE INDEX IF NOT EXISTS idx_users_email ON auth.users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON auth.users(active);

-- Production
CREATE INDEX IF NOT EXISTS idx_products_active ON production.products(active);
CREATE INDEX IF NOT EXISTS idx_products_category ON production.products(category);
CREATE INDEX IF NOT EXISTS idx_recipes_product ON production.recipes(product_id);
CREATE INDEX IF NOT EXISTS idx_ingredients_recipe ON production.recipe_ingredients(recipe_id);
CREATE INDEX IF NOT EXISTS idx_steps_product ON production.production_steps(product_id);
CREATE INDEX IF NOT EXISTS idx_questions_user ON production.questions(user_id);
CREATE INDEX IF NOT EXISTS idx_questions_status ON production.questions(status);

-- Tasks
CREATE INDEX IF NOT EXISTS idx_tasks_assigned ON tasks.tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks.tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_issues_status ON tasks.issues(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON tasks.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON tasks.notifications(read);

-- Monitoring
CREATE INDEX IF NOT EXISTS idx_rooms_type ON monitoring.rooms(type);
CREATE INDEX IF NOT EXISTS idx_sensors_room ON monitoring.sensors(room_id);
CREATE INDEX IF NOT EXISTS idx_readings_sensor ON monitoring.sensor_readings(sensor_id);
CREATE INDEX IF NOT EXISTS idx_readings_time ON monitoring.sensor_readings(recorded_at);
CREATE INDEX IF NOT EXISTS idx_alerts_resolved ON monitoring.alerts(resolved);
CREATE INDEX IF NOT EXISTS idx_alerts_sensor ON monitoring.alerts(sensor_id);
