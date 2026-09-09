from fastapi import APIRouter, Depends, Query
from src.controller.user_controller import get_user_profile, search_donors, update_user_profile
from src.db.db import get_db
from src.utils.dipendencies import get_current_user


from src.controller.user_controller import (
    register_user,
    login_user,
)
from src.schema.user_schema import (
    UserProfileUpdate,
    UserRegister,
    UserLogin,
)


router = APIRouter(
    prefix="/api/users",
    tags=["Users"]
)


@router.post("/register")
async def register(user: UserRegister):

    return await register_user(user)


@router.post("/login")
async def login(user: UserLogin):

    return await login_user(user)



@router.get("/profile")
async def profile(
    current_user_id: int = Depends(get_current_user),
    db=Depends(get_db)
):

    return await get_user_profile(
        current_user_id,
        db
    )
@router.put("/profile")
async def update_profile(
    user: UserProfileUpdate,
    current_user_id: int = Depends(get_current_user),
    db=Depends(get_db)
):

    return await update_user_profile(
        current_user_id,
        user,
        db
    )

@router.get("/donors")
async def get_donors(
    blood_group: str | None = Query(
        default=None
    ),

    area: str | None = Query(
        default=None
    ),

    city: str | None = Query(
        default=None
    ),

    page: int = Query(
        default=1,
        ge=1
    ),

    items_per_page: int = Query(
        default=10,
        ge=1,
        le=100
    ),

    db=Depends(get_db)
):

    return await search_donors(
        blood_group=blood_group,
        area=area,
        city=city,
        page=page,
        items_per_page=items_per_page,
        db=db
    )