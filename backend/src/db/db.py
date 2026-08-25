import os

import aiomysql
from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv("DB_HOST", "")
DB_PORT = int(os.getenv("DB_PORT", ""))
DB_USER = os.getenv("DB_USER", "")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "")

pool = None


async def connect_db():
    global pool

    pool = await aiomysql.create_pool(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        db=DB_NAME,
        minsize=1,
        maxsize=10,
        autocommit=True,
    )

    print("MySQL database connected successfully!")


async def close_db():
    global pool

    if pool:
        pool.close()
        await pool.wait_closed()
        print("MySQL connection closed.")


async def get_db():
    async with pool.acquire() as connection:
        async with connection.cursor(aiomysql.DictCursor) as cursor:
            yield connection, cursor