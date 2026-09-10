from fastapi import HTTPException


async def create_blood_request(
    current_user_id: int,
    data,
    db
):
    connection, cursor = db

    # Check user exists
    await cursor.execute(
        """
        SELECT id
        FROM users
        WHERE id = %s
        """,
        (current_user_id,)
    )

    user = await cursor.fetchone()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    # Validate blood group
    valid_blood_groups = [
        "A+",
        "A-",
        "B+",
        "B-",
        "AB+",
        "AB-",
        "O+",
        "O-"
    ]

    if data.blood_group not in valid_blood_groups:
        raise HTTPException(
            status_code=400,
            detail="Invalid blood group"
        )

    # Validate request type
    valid_request_types = [
        "critical",
        "urgent",
        "normal"
    ]

    if data.request_type not in valid_request_types:
        raise HTTPException(
            status_code=400,
            detail="Invalid request type"
        )

    # Validate units
    if data.units <= 0:
        raise HTTPException(
            status_code=400,
            detail="Units must be greater than 0"
        )

    # Create request
    await cursor.execute(
        """
        INSERT INTO blood_requests (
            user_id,
            patient_name,
            contact_number,
            blood_group,
            units,
            request_type,
            cause,
            location_detail,
            required_time,
            note
        )
        VALUES (
            %s, %s, %s, %s, %s,
            %s, %s, %s, %s, %s
        )
        """,
        (
            current_user_id,
            data.patient_name,
            data.contact_number,
            data.blood_group,
            data.units,
            data.request_type,
            data.cause,
            data.location_detail,
            data.required_time,
            data.note
        )
    )

    request_id = cursor.lastrowid

    # Get created request with user information
    await cursor.execute(
        """
        SELECT
            br.id,
            br.user_id,

            u.first_name,
            u.last_name,

            br.patient_name,
            br.contact_number,
            br.blood_group,
            br.units,
            br.request_type,
            br.status,
            br.cause,
            br.location_detail,
            br.required_time,
            br.note,
            br.created_at,
            br.updated_at,
            br.resolved_at

        FROM blood_requests br

        JOIN users u
            ON br.user_id = u.id

        WHERE br.id = %s
        """,
        (request_id,)
    )

    request = await cursor.fetchone()

    return {
        "message": "Blood request created successfully",
        "request": request
    }


async def get_all_blood_requests(db):
    connection, cursor = db

    await cursor.execute(
        """
        SELECT
            br.id,
            br.user_id,

            u.first_name,
            u.last_name,

            br.patient_name,
            br.contact_number,
            br.blood_group,
            br.units,
            br.request_type,
            br.status,
            br.cause,
            br.location_detail,
            br.required_time,
            br.note,
            br.created_at,
            br.updated_at,
            br.resolved_at

        FROM blood_requests br

        JOIN users u
            ON br.user_id = u.id

        ORDER BY
            CASE br.request_type
                WHEN 'critical' THEN 1
                WHEN 'urgent' THEN 2
                WHEN 'normal' THEN 3
            END,
            br.created_at DESC
        """
    )

    requests = await cursor.fetchall()

    return {
        "total": len(requests),
        "requests": requests
    }


async def get_my_blood_requests(
    current_user_id: int,
    db
):
    connection, cursor = db

    await cursor.execute(
        """
        SELECT
            br.id,
            br.user_id,

            u.first_name,
            u.last_name,

            br.patient_name,
            br.contact_number,
            br.blood_group,
            br.units,
            br.request_type,
            br.status,
            br.cause,
            br.location_detail,
            br.required_time,
            br.note,
            br.created_at,
            br.updated_at,
            br.resolved_at

        FROM blood_requests br

        JOIN users u
            ON br.user_id = u.id

        WHERE br.user_id = %s

        ORDER BY br.created_at DESC
        """,
        (current_user_id,)
    )

    requests = await cursor.fetchall()

    return {
        "total": len(requests),
        "requests": requests
    }


async def get_single_blood_request(
    request_id: int,
    db
):
    connection, cursor = db

    await cursor.execute(
        """
        SELECT
            br.id,
            br.user_id,

            u.first_name,
            u.last_name,

            br.patient_name,
            br.contact_number,
            br.blood_group,
            br.units,
            br.request_type,
            br.status,
            br.cause,
            br.location_detail,
            br.required_time,
            br.note,
            br.created_at,
            br.updated_at,
            br.resolved_at

        FROM blood_requests br

        JOIN users u
            ON br.user_id = u.id

        WHERE br.id = %s
        """,
        (request_id,)
    )

    request = await cursor.fetchone()

    if not request:
        raise HTTPException(
            status_code=404,
            detail="Blood request not found"
        )

    return request


async def update_blood_request(
    request_id: int,
    current_user_id: int,
    data,
    db
):
    connection, cursor = db

    # Check ownership
    await cursor.execute(
        """
        SELECT id, user_id, status
        FROM blood_requests
        WHERE id = %s
        """,
        (request_id,)
    )

    request = await cursor.fetchone()

    if not request:
        raise HTTPException(
            status_code=404,
            detail="Blood request not found"
        )

    if request["user_id"] != current_user_id:
        raise HTTPException(
            status_code=403,
            detail="You can only update your own blood request"
        )

    # Validate blood group if provided
    valid_blood_groups = [
        "A+",
        "A-",
        "B+",
        "B-",
        "AB+",
        "AB-",
        "O+",
        "O-"
    ]

    if data.blood_group is not None:
        if data.blood_group not in valid_blood_groups:
            raise HTTPException(
                status_code=400,
                detail="Invalid blood group"
            )

    # Validate request type
    valid_request_types = [
        "critical",
        "urgent",
        "normal"
    ]

    if data.request_type is not None:
        if data.request_type not in valid_request_types:
            raise HTTPException(
                status_code=400,
                detail="Invalid request type"
            )

    # Validate status
    valid_statuses = [
        "pending",
        "accepted",
        "fulfilled",
        "cancelled"
    ]

    if data.status is not None:
        if data.status not in valid_statuses:
            raise HTTPException(
                status_code=400,
                detail="Invalid status"
            )

    # Validate units
    if data.units is not None and data.units <= 0:
        raise HTTPException(
            status_code=400,
            detail="Units must be greater than 0"
        )

    # Get only fields that were actually sent
    update_data = data.model_dump(
        exclude_unset=True
    )

    if not update_data:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update"
        )

    # Build UPDATE query
    fields = []
    values = []

    for field, value in update_data.items():

        # When status becomes fulfilled/cancelled,
        # set resolved_at automatically.
        if field == "status":
            fields.append("status = %s")
            values.append(value)

            if value in ["fulfilled", "cancelled"]:
                fields.append("resolved_at = CURRENT_TIMESTAMP")

            elif value in ["pending", "accepted"]:
                fields.append("resolved_at = NULL")

        else:
            fields.append(f"{field} = %s")
            values.append(value)

    values.append(request_id)

    query = f"""
        UPDATE blood_requests
        SET {", ".join(fields)}
        WHERE id = %s
    """

    await cursor.execute(query, tuple(values))

    # Get updated request
    await cursor.execute(
        """
        SELECT
            br.id,
            br.user_id,

            u.first_name,
            u.last_name,

            br.patient_name,
            br.contact_number,
            br.blood_group,
            br.units,
            br.request_type,
            br.status,
            br.cause,
            br.location_detail,
            br.required_time,
            br.note,
            br.created_at,
            br.updated_at,
            br.resolved_at

        FROM blood_requests br

        JOIN users u
            ON br.user_id = u.id

        WHERE br.id = %s
        """,
        (request_id,)
    )

    updated_request = await cursor.fetchone()

    return {
        "message": "Blood request updated successfully",
        "request": updated_request
    }


async def delete_blood_request(
    request_id: int,
    current_user_id: int,
    db
):
    connection, cursor = db

    # Check request
    await cursor.execute(
        """
        SELECT id, user_id
        FROM blood_requests
        WHERE id = %s
        """,
        (request_id,)
    )

    request = await cursor.fetchone()

    if not request:
        raise HTTPException(
            status_code=404,
            detail="Blood request not found"
        )

    # Check ownership
    if request["user_id"] != current_user_id:
        raise HTTPException(
            status_code=403,
            detail="You can only delete your own blood request"
        )

    # Delete request
    await cursor.execute(
        """
        DELETE FROM blood_requests
        WHERE id = %s
        """,
        (request_id,)
    )

    return {
        "message": "Blood request deleted successfully"
    }