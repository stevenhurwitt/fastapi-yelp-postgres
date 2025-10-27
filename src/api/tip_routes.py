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

@router.get("/", response_model=List[schemas.TipWithNames])
def read_tips(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all tips with pagination, including user and business names"""
    tips = crud.get_tips_with_names(db, skip=skip, limit=limit)
    return [
        schemas.TipWithNames(
            user_id=t.user_id,
            business_id=t.business_id,
            text=t.text,
            date=t.date,
            compliment_count=t.compliment_count,
            year=t.year,
            user_name=t.user_name,
            business_name=t.business_name
        ) for t in tips
    ]

@router.get("/{user_id}/{business_id}", response_model=schemas.Tip)
def read_tip(user_id: str, business_id: str, db: Session = Depends(get_db)):
    """Get a specific tip by user and business ID"""
    tip = crud.get_tip(db, user_id=user_id, business_id=business_id)
    if tip is None:
        raise HTTPException(status_code=404, detail="Tip not found")
    return tip

@router.get("/business/{business_id}", response_model=List[schemas.TipWithNames])
def read_tips_by_business(business_id: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get tips for a specific business, including user and business names"""
    tips = crud.get_tips_by_business_with_names(db, business_id=business_id, skip=skip, limit=limit)
    return [
        schemas.TipWithNames(
            user_id=t.user_id,
            business_id=t.business_id,
            text=t.text,
            date=t.date,
            compliment_count=t.compliment_count,
            year=t.year,
            user_name=t.user_name,
            business_name=t.business_name
        ) for t in tips
    ]

@router.get("/user/{user_id}", response_model=List[schemas.TipWithNames])
def read_tips_by_user(user_id: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get tips by a specific user, including user and business names"""
    tips = crud.get_tips_by_user_with_names(db, user_id=user_id, skip=skip, limit=limit)
    return [
        schemas.TipWithNames(
            user_id=t.user_id,
            business_id=t.business_id,
            text=t.text,
            date=t.date,
            compliment_count=t.compliment_count,
            year=t.year,
            user_name=t.user_name,
            business_name=t.business_name
        ) for t in tips
    ]
