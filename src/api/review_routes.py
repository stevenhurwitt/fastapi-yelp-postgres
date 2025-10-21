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

@router.get("/", response_model=List[schemas.Review])
def read_reviews(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all reviews with pagination"""
    reviews = crud.get_reviews(db, skip=skip, limit=limit)
    return reviews

@router.get("/{review_id}", response_model=schemas.Review)
def read_review(review_id: str, db: Session = Depends(get_db)):
    """Get a specific review by ID"""
    review = crud.get_review(db, review_id=review_id)
    if review is None:
        raise HTTPException(status_code=404, detail="Review not found")
    return review

@router.get("/business/{business_id}", response_model=List[schemas.Review])
def read_reviews_by_business(business_id: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get reviews for a specific business"""
    reviews = crud.get_reviews_by_business(db, business_id=business_id, skip=skip, limit=limit)
    return reviews

@router.get("/user/{user_id}", response_model=List[schemas.Review])
def read_reviews_by_user(user_id: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get reviews by a specific user"""
    reviews = crud.get_reviews_by_user(db, user_id=user_id, skip=skip, limit=limit)
    return reviews