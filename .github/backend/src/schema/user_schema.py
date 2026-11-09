from datetime import date

from pydantic import BaseModel, EmailStr


class UserRegister(BaseModel):
    first_name: str
    last_name: str

    area: str | None = None
    road: str | None = None
    city: str | None = None

    phone: str
    email: EmailStr

    blood_group: str
    date_of_birth: date | None = None

    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int

    first_name: str
    last_name: str

    area: str | None
    road: str | None
    city: str | None

    phone: str
    email: str
    blood_group: str

    date_of_birth: date | None

    is_verified: bool
    is_active_donor: bool

    last_donation_date: date | None
class UserProfileUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None

    area: str | None = None
    road: str | None = None
    city: str | None = None

    phone: str | None = None
    email: EmailStr | None = None

    blood_group: str | None = None
    date_of_birth: date | None = None

    last_donation_date: date | None = None
    is_active_donor: bool | None = None