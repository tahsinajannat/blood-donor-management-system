from contextlib import asynccontextmanager
from src.router.user_routes import router as user_router
from src.router.conversation_routes import router as conversation_router
from src.router.message_routes import router as message_router
from src.router.blood_request_routes import router as blood_request 

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

app.include_router(user_router)
app.include_router(conversation_router)
app.include_router(message_router)
app.include_router(blood_request) 
@app.get("/health")
async def health():
    return {
        "status": "ok",
        "database": "connected"
    }

