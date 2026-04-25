from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from ..db.database import SessionLocal
from ..crud import crud
from ..schemas import schemas

router = APIRouter()

# Dependency to get the database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/", response_model=List[schemas.Checkin])
def read_checkins(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all checkins with pagination"""
    checkins = crud.get_checkins(db, skip=skip, limit=limit)
    return checkins

@router.get("/{business_id}/{date}", response_model=schemas.Checkin)
def read_checkin(business_id: str, date: str, db: Session = Depends(get_db)):
    """Get a specific checkin by business ID and date"""
    checkin = crud.get_checkin(db, business_id=business_id, date=date)
    if checkin is None:
        raise HTTPException(status_code=404, detail="Checkin not found")
    return checkin

@router.get("/business/{business_id}", response_model=List[schemas.Checkin])
def read_checkins_by_business(business_id: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get checkins for a specific business"""
    checkins = crud.get_checkins_by_business(db, business_id=business_id, skip=skip, limit=limit)
    return checkins
