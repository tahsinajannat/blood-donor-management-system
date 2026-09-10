CREATE TABLE IF NOT EXISTS blood_requests (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id INT UNSIGNED NOT NULL,

    patient_name VARCHAR(100) NOT NULL,

    contact_number VARCHAR(20) NULL,

    blood_group ENUM(
        'A+',
        'A-',
        'B+',
        'B-',
        'AB+',
        'AB-',
        'O+',
        'O-'
    ) NOT NULL,

    units INT UNSIGNED NOT NULL,

    request_type ENUM(
        'critical',
        'urgent',
        'normal'
    ) NOT NULL,

    status ENUM(
        'pending',
        'accepted',
        'fulfilled',
        'cancelled'
    ) NOT NULL DEFAULT 'pending',

    cause VARCHAR(255) NOT NULL,

    location_detail VARCHAR(255) NOT NULL,

    required_time DATETIME NOT NULL,

    note TEXT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    resolved_at TIMESTAMP NULL DEFAULT NULL,

    CONSTRAINT fk_blood_request_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_blood_request_units
        CHECK (units > 0)
);