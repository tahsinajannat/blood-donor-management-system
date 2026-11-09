CREATE TABLE IF NOT EXISTS blood_requests (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    user_id INT NOT NULL,

    patient_name VARCHAR(100) NOT NULL,

    contact_number VARCHAR(20) NULL,

    blood_group VARCHAR(3) NOT NULL,

    units INT NOT NULL,

    request_type VARCHAR(10) NOT NULL,

    status VARCHAR(10) NOT NULL DEFAULT 'pending',

    cause VARCHAR(255) NOT NULL,

    location_detail VARCHAR(255) NOT NULL,

    required_time TIMESTAMP NOT NULL,

    note TEXT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    resolved_at TIMESTAMP NULL DEFAULT NULL,

    CONSTRAINT fk_blood_request_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_blood_request_blood_group
        CHECK (blood_group IN (
            'A+', 'A-',
            'B+', 'B-',
            'AB+', 'AB-',
            'O+', 'O-'
        )),

    CONSTRAINT chk_blood_request_type
        CHECK (request_type IN ('critical', 'urgent', 'normal')),

    CONSTRAINT chk_blood_request_status
        CHECK (status IN ('pending', 'accepted', 'fulfilled', 'cancelled')),

    CONSTRAINT chk_blood_request_units
        CHECK (units > 0)
);

CREATE INDEX IF NOT EXISTS idx_blood_requests_user
    ON blood_requests (user_id);

CREATE OR REPLACE TRIGGER trg_blood_requests_updated_at
    BEFORE UPDATE ON blood_requests
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();
