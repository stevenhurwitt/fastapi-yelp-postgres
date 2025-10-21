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

@router.get("/", response_model=List[schemas.Business])
def read_businesses(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all businesses with pagination"""
    businesses = crud.get_businesses(db, skip=skip, limit=limit)
    return businesses

@router.get("/{business_id}", response_model=schemas.Business)
def read_business(business_id: str, db: Session = Depends(get_db)):
    """Get a specific business by ID"""
    business = crud.get_business(db, business_id=business_id)
    if business is None:
        raise HTTPException(status_code=404, detail="Business not found")
    return business

@router.get("/city/{city}", response_model=List[schemas.Business])
def read_businesses_by_city(city: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get businesses by city"""
    businesses = crud.get_businesses_by_city(db, city=city, skip=skip, limit=limit)
    return businesses

@router.get("/stars/{min_stars}", response_model=List[schemas.Business])
def read_businesses_by_stars(min_stars: float, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get businesses with minimum star rating"""
    businesses = crud.get_businesses_by_stars(db, min_stars=min_stars, skip=skip, limit=limit)
    return businesses