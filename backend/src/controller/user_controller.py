from fastapi import HTTPException, status

from src.db import db

from src.schema.user_schema import (
    UserProfileUpdate,
    UserRegister,
    UserLogin,
)
from src.utils.auth import (
    hash_password,
    verify_password,
    create_access_token,
)


async def register_user(user: UserRegister):

    async with db.pool.acquire() as connection:

        async with connection.cursor() as cursor:

            # Check email
            await cursor.execute(
                """
                SELECT id
                FROM users
                WHERE email = %s
                """,
                (user.email,)
            )

            existing_email = await cursor.fetchone()

            if existing_email:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Email already registered"
                )

            # Check phone
            await cursor.execute(
                """
                SELECT id
                FROM users
                WHERE phone = %s
                """,
                (user.phone,)
            )

            existing_phone = await cursor.fetchone()

            if existing_phone:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Phone number already registered"
                )

            # Hash password
            password_hash = hash_password(user.password)

            # Insert user
            await cursor.execute(
                """
                INSERT INTO users (
                    first_name,
                    last_name,
                    area,
                    road,
                    city,
                    phone,
                    email,
                    blood_group,
                    date_of_birth,
                    password_hash
                )
                VALUES (
                    %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s
                )
                """,
                (
                    user.first_name,
                    user.last_name,
                    user.area,
                    user.road,
                    user.city,
                    user.phone,
                    user.email,
                    user.blood_group,
                    user.date_of_birth,
                    password_hash,
                )
            )

            await connection.commit()

            user_id = cursor.lastrowid

            return {
                "message": "User registered successfully",
                "user_id": user_id
            }


async def login_user(user: UserLogin):

    async with db.pool.acquire() as connection:

        async with connection.cursor() as cursor:

            await cursor.execute(
                """
                SELECT
                    id,
                    email,
                    password_hash,
                    is_verified,
                    is_active_donor
                FROM users
                WHERE email = %s
                """,
                (user.email,)
            )

            db_user = await cursor.fetchone()

            if not db_user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid email or password"
                )

            (
                user_id,
                email,
                password_hash,
                is_verified,
                is_active_donor,
            ) = db_user

            # Verify password
            if not verify_password(
                user.password,
                password_hash
            ):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid email or password"
                )

            # Create JWT
            access_token = create_access_token(
                user_id
            )

            return {
                "message": "Login successful",
                "access_token": access_token,
                "token_type": "bearer",
                "user": {
                    "id": user_id,
                    "email": email,
                    "is_verified": is_verified,
                    "is_active_donor": is_active_donor,
                }
            }


async def get_user_profile(user_id: int, db):

    connection, cursor = db

    await cursor.execute(
        """
        SELECT
            id,
            first_name,
            last_name,
            area,
            road,
            city,
            phone,
            email,
            blood_group,
            date_of_birth,
            last_donation_date,
            is_verified,
            is_active_donor,
            created_at,
            updated_at
        FROM users
        WHERE id = %s
        """,
        (user_id,)
    )

    user = await cursor.fetchone()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user


async def update_user_profile(
    user_id: int,
    user: UserProfileUpdate,
    db
):

    connection, cursor = db

    # Check if user exists
    await cursor.execute(
        """
        SELECT id
        FROM users
        WHERE id = %s
        """,
        (user_id,)
    )

    existing_user = await cursor.fetchone()

    if not existing_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Check duplicate email
    if user.email is not None:

        await cursor.execute(
            """
            SELECT id
            FROM users
            WHERE email = %s
            AND id != %s
            """,
            (user.email, user_id)
        )

        email_exists = await cursor.fetchone()

        if email_exists:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered"
            )

    # Check duplicate phone
    if user.phone is not None:

        await cursor.execute(
            """
            SELECT id
            FROM users
            WHERE phone = %s
            AND id != %s
            """,
            (user.phone, user_id)
        )

        phone_exists = await cursor.fetchone()

        if phone_exists:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Phone number already registered"
            )

    # Get only fields sent by the user
    update_data = user.model_dump(
        exclude_unset=True
    )

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No data provided for update"
        )

    fields = []
    values = []

    for field, value in update_data.items():

        fields.append(f"{field} = %s")
        values.append(value)

    values.append(user_id)

    query = f"""
        UPDATE users
        SET {", ".join(fields)}
        WHERE id = %s
    """

    await cursor.execute(query, tuple(values))

    await connection.commit()

    # Get updated profile
    await cursor.execute(
        """
        SELECT
            id,
            first_name,
            last_name,
            area,
            road,
            city,
            phone,
            email,
            blood_group,
            date_of_birth,
            last_donation_date,
            is_verified,
            is_active_donor,
            created_at,
            updated_at
        FROM users
        WHERE id = %s
        """,
        (user_id,)
    )

    updated_user = await cursor.fetchone()

    return {
        "message": "Profile updated successfully",
        "user": updated_user
    }


async def search_donors(
    blood_group: str | None,
    area: str | None,
    city: str | None,
    page: int,
    items_per_page: int,
    db
):

    connection, cursor = db

    # -------------------------------------------------
    # Calculate OFFSET
    # -------------------------------------------------

    offset = (page - 1) * items_per_page


    # -------------------------------------------------
    # Build WHERE conditions
    # -------------------------------------------------

    conditions = [
        "is_active_donor = TRUE",

        # Must have donated at least 4 months ago
        # OR never donated
        """
        (
            last_donation_date IS NULL
            OR last_donation_date <= DATE_SUB(
                CURDATE(),
                INTERVAL 4 MONTH
            )
        )
        """,

        # Age greater than 15
        """
        date_of_birth IS NOT NULL
        AND date_of_birth < DATE_SUB(
            CURDATE(),
            INTERVAL 15 YEAR
        )
        """
    ]

    params = []


    # -------------------------------------------------
    # Blood group filter
    # -------------------------------------------------

    if blood_group:

        conditions.append(
            "blood_group = %s"
        )

        params.append(blood_group)


    # -------------------------------------------------
    # Area search
    # -------------------------------------------------

    if area:

        conditions.append(
            "area LIKE %s"
        )

        params.append(f"%{area}%")


    # -------------------------------------------------
    # City search
    # -------------------------------------------------

    if city:

        conditions.append(
            "city LIKE %s"
        )

        params.append(f"%{city}%")


    where_clause = " AND ".join(
        conditions
    )


    # -------------------------------------------------
    # Count total matching donors
    # -------------------------------------------------

    count_query = f"""
        SELECT COUNT(*) AS total
        FROM users
        WHERE {where_clause}
    """

    await cursor.execute(
        count_query,
        tuple(params)
    )

    count_result = await cursor.fetchone()

    total = count_result["total"]


    # -------------------------------------------------
    # Get donors
    # -------------------------------------------------

    query = f"""
        SELECT
            id,
            first_name,
            last_name,
            area,
            road,
            city,
            phone,
            email,
            blood_group,
            date_of_birth,
            last_donation_date,
            is_verified,
            is_active_donor
        FROM users
        WHERE {where_clause}

        ORDER BY
            last_donation_date ASC

        LIMIT %s OFFSET %s
    """

    query_params = params + [
        items_per_page,
        offset
    ]

    await cursor.execute(
        query,
        tuple(query_params)
    )

    donors = await cursor.fetchall()


    # -------------------------------------------------
    # Pagination information
    # -------------------------------------------------

    total_pages = (
        (total + items_per_page - 1)
        // items_per_page
    )


    return {
        "data": donors,

        "pagination": {
            "page": page,
            "items_per_page": items_per_page,
            "total_items": total,
            "total_pages": total_pages,

            "has_next": page < total_pages,
            "has_previous": page > 1
        }
    }