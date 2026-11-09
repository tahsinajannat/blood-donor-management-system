from fastapi import APIRouter, Depends

from src.schema.blood_request_schema import (
    BloodRequestCreate,
    BloodRequestUpdate
)

from src.controller.blood_request_controller import (
    create_blood_request,
    get_all_blood_requests,
    get_my_blood_requests,
    get_single_blood_request,
    update_blood_request,
    delete_blood_request
)

from src.db.db import get_db
from src.utils.dipendencies import get_current_user


router = APIRouter(
    prefix="/blood-requests",
    tags=["Blood Requests"]
)


# Create blood request
@router.post("/")
async def create_request(
    data: BloodRequestCreate,
    current_user_id: int = Depends(get_current_user),
    db=Depends(get_db)
):
    return await create_blood_request(
        current_user_id=current_user_id,
        data=data,
        db=db
    )


# Get all blood requests
@router.get("/")
async def get_all_requests(
    db=Depends(get_db)
):
    return await get_all_blood_requests(
        db=db
    )


# Get current user's blood requests
@router.get("/my")
async def get_my_requests(
    current_user_id: int = Depends(get_current_user),
    db=Depends(get_db)
):
    return await get_my_blood_requests(
        current_user_id=current_user_id,
        db=db
    )


# Get single blood request
@router.get("/{request_id}")
async def get_request(
    request_id: int,
    db=Depends(get_db)
):
    return await get_single_blood_request(
        request_id=request_id,
        db=db
    )


# Update blood request
@router.put("/{request_id}")
async def update_request(
    request_id: int,
    data: BloodRequestUpdate,
    current_user_id: int = Depends(get_current_user),
    db=Depends(get_db)
):
    return await update_blood_request(
        request_id=request_id,
        current_user_id=current_user_id,
        data=data,
        db=db
    )


# Delete blood request
@router.delete("/{request_id}")
async def delete_request(
    request_id: int,
    current_user_id: int = Depends(get_current_user),
    db=Depends(get_db)
):
    return await delete_blood_request(
        request_id=request_id,
        current_user_id=current_user_id,
        db=db
    )