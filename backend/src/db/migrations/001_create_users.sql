-- Keeps updated_at current on every UPDATE
-- (PostgreSQL has no ON UPDATE CURRENT_TIMESTAMP).
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS users (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,

    area VARCHAR(100),
    road VARCHAR(150),
    city VARCHAR(100),

    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,

    blood_group VARCHAR(3) NOT NULL,

    date_of_birth DATE,

    password_hash VARCHAR(255) NOT NULL,

    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_active_donor BOOLEAN NOT NULL DEFAULT TRUE,

    last_donation_date DATE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_user_blood_group
        CHECK (blood_group IN (
            'A+', 'A-',
            'B+', 'B-',
            'AB+', 'AB-',
            'O+', 'O-'
        ))
);

CREATE INDEX IF NOT EXISTS idx_users_blood_group
    ON users (blood_group);

CREATE OR REPLACE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();
