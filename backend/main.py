from contextlib import asynccontextmanager

from fastapi import FastAPI

from src.db.db import connect_db, close_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await connect_db()

    yield

    # Shutdown
    await close_db()


app = FastAPI(
    title="My FastAPI Backend",
    description="FastAPI + Async MySQL API",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/")
async def root():
    return {
        "message": "FastAPI server is running!"
    }


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "database": "connected"
    }