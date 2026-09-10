from fastapi import HTTPException


async def send_message(
    conversation_id: int,
    current_user_id: int,
    message_text: str,
    db
):
    connection, cursor = db

    # Check conversation and authorization
    await cursor.execute(
        """
        SELECT id
        FROM conversations
        WHERE id = %s
        AND (user1_id = %s OR user2_id = %s)
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

    # Remove unnecessary spaces
    message_text = message_text.strip()

    if not message_text:
        raise HTTPException(
            status_code=400,
            detail="Message cannot be empty"
        )

    # Insert message
    await cursor.execute(
        """
        INSERT INTO messages
        (conversation_id, sender_id, message)
        VALUES (%s, %s, %s)
        """,
        (
            conversation_id,
            current_user_id,
            message_text
        )
    )

    message_id = cursor.lastrowid

    # Update last message in conversation
    await cursor.execute(
        """
        UPDATE conversations
        SET last_message = %s
        WHERE id = %s
        """,
        (
            message_text,
            conversation_id
        )
    )

    # Get inserted message with sender information
    await cursor.execute(
        """
        SELECT
            m.id,
            m.conversation_id,
            m.sender_id,

            u.first_name AS sender_first_name,
            u.last_name AS sender_last_name,

            m.message,
            m.created_at,
            m.updated_at

        FROM messages m

        JOIN users u
            ON m.sender_id = u.id

        WHERE m.id = %s
        """,
        (message_id,)
    )

    new_message = await cursor.fetchone()

    return new_message


async def get_messages(
    conversation_id: int,
    current_user_id: int,
    db,
    page: int = 1,
    items_per_page: int = 20
):
    connection, cursor = db

    # Check conversation membership
    await cursor.execute(
        """
        SELECT id
        FROM conversations
        WHERE id = %s
        AND (user1_id = %s OR user2_id = %s)
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

    # Pagination
    offset = (page - 1) * items_per_page

    # Get total messages
    await cursor.execute(
        """
        SELECT COUNT(*) AS total
        FROM messages
        WHERE conversation_id = %s
        """,
        (conversation_id,)
    )

    result = await cursor.fetchone()
    total = result["total"]

    # Get messages with sender information
    await cursor.execute(
        """
        SELECT
            m.id,
            m.conversation_id,
            m.sender_id,

            u.first_name AS sender_first_name,
            u.last_name AS sender_last_name,

            m.message,
            m.created_at,
            m.updated_at

        FROM messages m

        JOIN users u
            ON m.sender_id = u.id

        WHERE m.conversation_id = %s

        ORDER BY m.created_at ASC

        LIMIT %s OFFSET %s
        """,
        (
            conversation_id,
            items_per_page,
            offset
        )
    )

    messages = await cursor.fetchall()

    return {
        "conversation_id": conversation_id,
        "page": page,
        "items_per_page": items_per_page,
        "total": total,
        "messages": messages
    }