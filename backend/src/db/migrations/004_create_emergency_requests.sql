CREATE TABLE IF NOT EXISTS emergency_blood_requests (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    user_id INT NOT NULL,

    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,

    blood_group VARCHAR(3) NOT NULL,

    contact VARCHAR(100) NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL DEFAULT NULL,

    CONSTRAINT fk_emergency_request_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_emergency_blood_group
        CHECK (blood_group IN (
            'A+', 'A-',
            'B+', 'B-',
            'AB+', 'AB-',
            'O+', 'O-'
        ))
);
