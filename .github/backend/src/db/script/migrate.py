import asyncio
import os
from pathlib import Path

import asyncpg
from dotenv import load_dotenv


load_dotenv()


DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "blood_donation_db")


BASE_DIR = Path(__file__).resolve().parent.parent
MIGRATIONS_DIR = BASE_DIR / "migrations"


async def get_connection():
    return await asyncpg.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
    )


async def create_migration_table(connection):
    sql = (MIGRATIONS_DIR / "000_migration_table.sql").read_text(
        encoding="utf-8"
    )

    await connection.execute(sql)


async def run_migrations():
    connection = await get_connection()

    try:
        await create_migration_table(connection)

        completed = {
            row["migration"]
            for row in await connection.fetch(
                "SELECT migration FROM migrations"
            )
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

            # Each migration file runs in its own transaction.
            # The whole file is sent at once, so function bodies
            # containing ";" are not split apart.
            async with connection.transaction():
                await connection.execute(sql)

                await connection.execute(
                    """
                    INSERT INTO migrations (migration)
                    VALUES ($1)
                    """,
                    migration_name
                )

            print(f"DONE  {migration_name}")

        print("\nAll migrations completed.")

    finally:
        await connection.close()


if __name__ == "__main__":
    asyncio.run(run_migrations())
