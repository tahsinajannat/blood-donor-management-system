CREATE TABLE IF NOT EXISTS conversations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user1_id INT UNSIGNED NOT NULL,
    user2_id INT UNSIGNED NOT NULL,

    last_message TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_conversation_user1
        FOREIGN KEY (user1_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_conversation_user2
        FOREIGN KEY (user2_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_different_users
        CHECK (user1_id <> user2_id)
);