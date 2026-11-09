from datetime import datetime
from pydantic import BaseModel
from typing import Optional


class BloodRequestCreate(BaseModel):
    patient_name: str
    contact_number: Optional[str] = None
    blood_group: str
    units: int
    request_type: str
    cause: str
    location_detail: str
    required_time: datetime
    note: Optional[str] = None


class BloodRequestUpdate(BaseModel):
    patient_name: Optional[str] = None
    contact_number: Optional[str] = None
    blood_group: Optional[str] = None
    units: Optional[int] = None
    request_type: Optional[str] = None
    status: Optional[str] = None
    cause: Optional[str] = None
    location_detail: Optional[str] = None
    required_time: Optional[datetime] = None
    note: Optional[str] = None