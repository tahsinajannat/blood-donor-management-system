from fastapi import HTTPException


async def create_conversation(current_user_id: int, other_user_id: int, db):
    connection, cursor = db

    # User cannot message themselves
    if current_user_id == other_user_id:
        raise HTTPException(
            status_code=400,
            detail="You cannot create a conversation with yourself"
        )

    # Check whether the other user exists
    await cursor.execute(
        """
        SELECT id, first_name, last_name
        FROM users
        WHERE id = %s
        """,
        (other_user_id,)
    )

    other_user = await cursor.fetchone()

    if not other_user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    # Keep user IDs in fixed order
    user1_id = min(current_user_id, other_user_id)
    user2_id = max(current_user_id, other_user_id)

    # Check existing conversation
    await cursor.execute(
        """
        SELECT
            c.id,
            c.user1_id,
            c.user2_id,
            c.last_message,
            c.created_at,
            c.updated_at,

            u1.first_name AS user1_first_name,
            u1.last_name AS user1_last_name,

            u2.first_name AS user2_first_name,
            u2.last_name AS user2_last_name

        FROM conversations c

        JOIN users u1
            ON c.user1_id = u1.id

        JOIN users u2
            ON c.user2_id = u2.id

        WHERE c.user1_id = %s
        AND c.user2_id = %s
        """,
        (user1_id, user2_id)
    )

    conversation = await cursor.fetchone()

    if conversation:
        return {
            "message": "Conversation already exists",
            "conversation": conversation
        }

    # Create new conversation
    await cursor.execute(
        """
        INSERT INTO conversations
        (user1_id, user2_id)
        VALUES (%s, %s)
        """,
        (user1_id, user2_id)
    )

    conversation_id = cursor.lastrowid

    # Get conversation with user names
    await cursor.execute(
        """
        SELECT
            c.id,
            c.user1_id,
            c.user2_id,
            c.last_message,
            c.created_at,
            c.updated_at,

            u1.first_name AS user1_first_name,
            u1.last_name AS user1_last_name,

            u2.first_name AS user2_first_name,
            u2.last_name AS user2_last_name

        FROM conversations c

        JOIN users u1
            ON c.user1_id = u1.id

        JOIN users u2
            ON c.user2_id = u2.id

        WHERE c.id = %s
        """,
        (conversation_id,)
    )

    conversation = await cursor.fetchone()

    return {
        "message": "Conversation created successfully",
        "conversation": conversation
    }


async def get_my_conversations(current_user_id: int, db):
    connection, cursor = db

    await cursor.execute(
        """
        SELECT
            c.id,
            c.user1_id,
            c.user2_id,
            c.last_message,
            c.created_at,
            c.updated_at,

            CASE
                WHEN c.user1_id = %s
                THEN c.user2_id
                ELSE c.user1_id
            END AS other_user_id,

            CASE
                WHEN c.user1_id = %s
                THEN u2.first_name
                ELSE u1.first_name
            END AS other_user_first_name,

            CASE
                WHEN c.user1_id = %s
                THEN u2.last_name
                ELSE u1.last_name
            END AS other_user_last_name

        FROM conversations c

        JOIN users u1
            ON c.user1_id = u1.id

        JOIN users u2
            ON c.user2_id = u2.id

        WHERE c.user1_id = %s
           OR c.user2_id = %s

        ORDER BY c.updated_at DESC
        """,
        (
            current_user_id,
            current_user_id,
            current_user_id,
            current_user_id,
            current_user_id
        )
    )

    conversations = await cursor.fetchall()

    return {
        "conversations": conversations
    }


async def get_conversation(
    conversation_id: int,
    current_user_id: int,
    db
):
    connection, cursor = db

    await cursor.execute(
        """
        SELECT
            c.id,
            c.user1_id,
            c.user2_id,
            c.last_message,
            c.created_at,
            c.updated_at,

            u1.first_name AS user1_first_name,
            u1.last_name AS user1_last_name,

            u2.first_name AS user2_first_name,
            u2.last_name AS user2_last_name

        FROM conversations c

        JOIN users u1
            ON c.user1_id = u1.id

        JOIN users u2
            ON c.user2_id = u2.id

        WHERE c.id = %s
        AND (c.user1_id = %s OR c.user2_id = %s)
        """,
        (
            conversation_id,
            current_user_id,
            current_user_id
        )
    )

    conversation = await cursor.fetchone()

    if not conversation:
        raise HTTPException(
            status_code=404,
            detail="Conversation not found"
        )

    return conversation