-- =====================================================
-- Ground Up Factory — Seed Data
-- Creates the initial admin user and facility data.
-- Run AFTER 001_initial_schema.sql
-- =====================================================

-- =====================================================
-- 1. Create Admin User
-- Password: admin123 (bcrypt hashed)
-- CHANGE THIS PASSWORD after first login!
-- =====================================================
INSERT INTO auth.users (name, email, password, role) VALUES
    ('Admin', 'admin@groundup.app', '$2b$12$u3wLKU9OteIxBtWaPUplgu8KQSUJPFup6EwRq2gfCwPLHHTFitVfi', 'admin')
ON CONFLICT (email) DO NOTHING;


-- =====================================================
-- 2. Create Test Employees
-- Password for all: employee123 (bcrypt hashed)
-- =====================================================
INSERT INTO auth.users (name, email, password, role) VALUES
    ('Employee 1', 'employee1@groundup.app', '$2b$12$WHXYZ2sRLhg14bIfWhwcvedbNiFuSpjjURSR3R4gjjRfFu7clE1T.', 'employee'),
    ('Employee 2', 'employee2@groundup.app', '$2b$12$WHXYZ2sRLhg14bIfWhwcvedbNiFuSpjjURSR3R4gjjRfFu7clE1T.', 'employee'),
    ('Employee 3', 'employee3@groundup.app', '$2b$12$WHXYZ2sRLhg14bIfWhwcvedbNiFuSpjjURSR3R4gjjRfFu7clE1T.', 'employee'),
    ('Employee 4', 'employee4@groundup.app', '$2b$12$WHXYZ2sRLhg14bIfWhwcvedbNiFuSpjjURSR3R4gjjRfFu7clE1T.', 'employee')
ON CONFLICT (email) DO NOTHING;


-- =====================================================
-- 3. Create Monitoring Rooms / Fridges / Freezers
-- (From blueprint: 4 rooms, 6 fridges, 3 freezers)
-- =====================================================
INSERT INTO monitoring.rooms (name, type) VALUES
    ('Room 1', 'room'),
    ('Room 3', 'room'),
    ('Main Kitchen', 'room'),
    ('Rooftop', 'room'),
    ('Fridge 1', 'fridge'),
    ('Fridge 2', 'fridge'),
    ('Fridge 3', 'fridge'),
    ('Fridge 4', 'fridge'),
    ('Fridge 5', 'fridge'),
    ('Fridge 6', 'fridge'),
    ('Freezer 1', 'freezer'),
    ('Freezer 2', 'freezer'),
    ('Freezer 3', 'freezer');


-- =====================================================
-- 4. Create Sensors for each room
-- Rooms get temperature + humidity sensors
-- Fridges and freezers get temperature sensors only
-- =====================================================

-- Room sensors (temperature + humidity)
INSERT INTO monitoring.sensors (room_id, type, min_threshold, max_threshold)
SELECT r.id, 'temperature'::monitoring.sensor_type, 18.0, 35.0
FROM monitoring.rooms r WHERE r.type = 'room';

INSERT INTO monitoring.sensors (room_id, type, min_threshold, max_threshold)
SELECT r.id, 'humidity'::monitoring.sensor_type, 30.0, 80.0
FROM monitoring.rooms r WHERE r.type = 'room';

-- Fridge sensors (temperature only)
INSERT INTO monitoring.sensors (room_id, type, min_threshold, max_threshold)
SELECT r.id, 'temperature'::monitoring.sensor_type, 1.0, 5.0
FROM monitoring.rooms r WHERE r.type = 'fridge';

-- Freezer sensors (temperature only)
INSERT INTO monitoring.sensors (room_id, type, min_threshold, max_threshold)
SELECT r.id, 'temperature'::monitoring.sensor_type, -25.0, -15.0
FROM monitoring.rooms r WHERE r.type = 'freezer';


-- =====================================================
-- 5. Sample Products (for testing)
-- Replace with real data from Excel import later.
-- =====================================================
INSERT INTO production.products (name, category, room, description) VALUES
    ('White Miso', 'Miso', 'Room 1', 'Light and sweet miso paste made from soybeans and rice koji'),
    ('Red Miso', 'Miso', 'Room 1', 'Bold and savory miso with longer fermentation'),
    ('Toasted Sesame Miso', 'Miso', 'Room 1', 'Miso with toasted sesame for rich nutty flavor'),
    ('Seaweed Miso', 'Miso', 'Room 3', 'Miso infused with Konkan coast seaweed'),
    ('White Bean Miso', 'Miso', 'Room 3', 'Lighter miso made with white beans instead of soy');

-- Sample recipe for White Miso
INSERT INTO production.recipes (product_id, version, base_qty, base_unit, notes)
SELECT id, 1, 1.0, 'kg', 'Standard White Miso base recipe'
FROM production.products WHERE name = 'White Miso';

-- Sample ingredients for White Miso (per 1 kg base)
INSERT INTO production.recipe_ingredients (recipe_id, ingredient, quantity, unit, order_index)
SELECT r.id, 'Soybean', 0.50, 'kg', 1
FROM production.recipes r
JOIN production.products p ON r.product_id = p.id
WHERE p.name = 'White Miso';

INSERT INTO production.recipe_ingredients (recipe_id, ingredient, quantity, unit, order_index)
SELECT r.id, 'Rice Koji', 0.40, 'kg', 2
FROM production.recipes r
JOIN production.products p ON r.product_id = p.id
WHERE p.name = 'White Miso';

INSERT INTO production.recipe_ingredients (recipe_id, ingredient, quantity, unit, order_index)
SELECT r.id, 'Salt', 0.10, 'kg', 3
FROM production.recipes r
JOIN production.products p ON r.product_id = p.id
WHERE p.name = 'White Miso';

-- Sample production steps for White Miso
INSERT INTO production.production_steps (product_id, step_number, title, description, duration_min)
SELECT id, 1, 'Soak Soybeans', 'Soak soybeans in clean water overnight (12-18 hours). Soybeans should double in size.', 1080
FROM production.products WHERE name = 'White Miso';

INSERT INTO production.production_steps (product_id, step_number, title, description, duration_min)
SELECT id, 2, 'Cook Soybeans', 'Pressure cook soaked soybeans until very soft. They should crush easily between your fingers.', 90
FROM production.products WHERE name = 'White Miso';

INSERT INTO production.production_steps (product_id, step_number, title, description, duration_min)
SELECT id, 3, 'Mash Soybeans', 'Drain and mash the cooked soybeans until smooth. Can use food processor or potato masher.', 20
FROM production.products WHERE name = 'White Miso';

INSERT INTO production.production_steps (product_id, step_number, title, description, duration_min)
SELECT id, 4, 'Mix with Koji and Salt', 'Combine mashed soybeans with rice koji and salt. Mix thoroughly until uniform texture.', 15
FROM production.products WHERE name = 'White Miso';

INSERT INTO production.production_steps (product_id, step_number, title, description, duration_min)
SELECT id, 5, 'Pack and Ferment', 'Pack mixture tightly into fermentation vessel. Remove air pockets. Cover with plastic wrap directly on surface. Place weight on top. Store in Room 1.', 10
FROM production.products WHERE name = 'White Miso';
