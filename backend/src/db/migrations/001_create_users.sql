CREATE TABLE IF NOT EXISTS users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,

    area VARCHAR(100),
    road VARCHAR(150),
    city VARCHAR(100),

    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,

    blood_group ENUM(
        'A+', 'A-',
        'B+', 'B-',
        'AB+', 'AB-',
        'O+', 'O-'
    ) NOT NULL,

    date_of_birth DATE,

    password_hash VARCHAR(255) NOT NULL,

    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_active_donor BOOLEAN NOT NULL DEFAULT TRUE,

    last_donation_date DATE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);