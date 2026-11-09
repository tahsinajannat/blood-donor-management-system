CREATE TABLE IF NOT EXISTS conversations (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    user1_id INT NOT NULL,
    user2_id INT NOT NULL,

    last_message TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

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

CREATE INDEX IF NOT EXISTS idx_conversations_user1
    ON conversations (user1_id);

CREATE INDEX IF NOT EXISTS idx_conversations_user2
    ON conversations (user2_id);

CREATE OR REPLACE TRIGGER trg_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();
