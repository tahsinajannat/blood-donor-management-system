import os
import re
from contextlib import asynccontextmanager
from datetime import datetime

import asyncpg
from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "")

pool = None


class Cursor:
    """
    Small cursor-style wrapper around an asyncpg connection,
    so controllers can keep using execute()/fetchone()/fetchall()
    with %s placeholders. Rows are returned as dicts.
    """

    def __init__(self, connection):
        self._connection = connection
        self._rows = []

    async def execute(self, query, params=()):
        # asyncpg uses $1, $2, ... instead of %s
        counter = iter(range(1, len(params) + 1))
        query = re.sub(r"%s", lambda _: f"${next(counter)}", query)

        # Columns are TIMESTAMP (no time zone), like MySQL DATETIME:
        # store the wall-clock value and drop any tz offset.
        params = [
            value.replace(tzinfo=None)
            if isinstance(value, datetime) else value
            for value in params
        ]

        records = await self._connection.fetch(query, *params)
        self._rows = [dict(record) for record in records]

    async def fetchone(self):
        return self._rows[0] if self._rows else None

    async def fetchall(self):
        return self._rows


class Connection:
    def __init__(self, connection):
        self.raw = connection

    async def commit(self):
        # asyncpg runs each statement in autocommit mode
        pass


async def connect_db():
    global pool

    pool = await asyncpg.create_pool(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        min_size=1,
        max_size=10,
    )

    print("PostgreSQL database connected successfully!")


async def close_db():
    global pool

    if pool:
        await pool.close()
        print("PostgreSQL connection closed.")


@asynccontextmanager
async def db_session():
    async with pool.acquire() as connection:
        yield Connection(connection), Cursor(connection)


async def get_db():
    async with db_session() as session:
        yield session
