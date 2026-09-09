import asyncio
import os
from pathlib import Path

import aiomysql
from dotenv import load_dotenv


load_dotenv()


DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "blood_donation_db")


BASE_DIR = Path(__file__).resolve().parent.parent
MIGRATIONS_DIR = BASE_DIR / "migrations"


async def get_connection():
    return await aiomysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        db=DB_NAME,
        autocommit=False,
    )


async def create_migration_table(cursor):
    await cursor.execute("""
        CREATE TABLE IF NOT EXISTS migrations (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            migration VARCHAR(255) NOT NULL UNIQUE,
            executed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    """)


async def run_migrations():
    connection = await get_connection()

    try:
        async with connection.cursor() as cursor:

            await create_migration_table(cursor)

            await cursor.execute(
                "SELECT migration FROM migrations"
            )

            completed = {
                row[0]
                for row in await cursor.fetchall()
            }

            migration_files = sorted(
                MIGRATIONS_DIR.glob("*.sql")
            )

            for migration_file in migration_files:

                migration_name = migration_file.name

                if migration_name == "000_migration_table.sql":
                    continue

                if migration_name in completed:
                    print(f"SKIP  {migration_name}")
                    continue

                print(f"RUN   {migration_name}")

                sql = migration_file.read_text(
                    encoding="utf-8"
                )

                statements = [
                    statement.strip()
                    for statement in sql.split(";")
                    if statement.strip()
                ]

                for statement in statements:
                    await cursor.execute(statement)

                await cursor.execute(
                    """
                    INSERT INTO migrations (migration)
                    VALUES (%s)
                    """,
                    (migration_name,)
                )

                await connection.commit()

                print(f"DONE  {migration_name}")

        print("\nAll migrations completed.")

    except Exception:
        await connection.rollback()
        raise

    finally:
        connection.close()


if __name__ == "__main__":
    asyncio.run(run_migrations())