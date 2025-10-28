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

@router.get("/", response_model=List[schemas.ReviewWithNames])
def read_reviews(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all reviews with pagination, including user and business names"""
    reviews = crud.get_reviews_with_names(db, skip=skip, limit=limit)
    return [
        schemas.ReviewWithNames(
            review_id=r.review_id,
            user_id=r.user_id,
            business_id=r.business_id,
            stars=r.stars,
            useful=r.useful,
            funny=r.funny,
            cool=r.cool,
            text=r.text,
            date=r.date,
            year=r.year,
            month=r.month,
            user_name=r.user_name,
            business_name=r.business_name
        ) for r in reviews
    ]

@router.get("/{review_id}", response_model=schemas.ReviewWithNames)
def read_review(review_id: str, db: Session = Depends(get_db)):
    """Get a specific review by ID, including user and business names"""
    review = crud.get_review_with_names(db, review_id=review_id)
    if review is None:
        raise HTTPException(status_code=404, detail="Review not found")
    return schemas.ReviewWithNames(
        review_id=review.review_id,
        user_id=review.user_id,
        business_id=review.business_id,
        stars=review.stars,
        useful=review.useful,
        funny=review.funny,
        cool=review.cool,
        text=review.text,
        date=review.date,
        year=review.year,
        month=review.month,
        user_name=review.user_name,
        business_name=review.business_name
    )

@router.get("/business/{business_id}", response_model=List[schemas.ReviewWithNames])
def read_reviews_by_business(business_id: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get reviews for a specific business, including user and business names"""
    reviews = crud.get_reviews_by_business_with_names(db, business_id=business_id, skip=skip, limit=limit)
    return [
        schemas.ReviewWithNames(
            review_id=r.review_id,
            user_id=r.user_id,
            business_id=r.business_id,
            stars=r.stars,
            useful=r.useful,
            funny=r.funny,
            cool=r.cool,
            text=r.text,
            date=r.date,
            year=r.year,
            month=r.month,
            user_name=r.user_name,
            business_name=r.business_name
        ) for r in reviews
    ]

@router.get("/user/{user_id}", response_model=List[schemas.ReviewWithNames])
def read_reviews_by_user(user_id: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get reviews by a specific user, including user and business names"""
    reviews = crud.get_reviews_by_user_with_names(db, user_id=user_id, skip=skip, limit=limit)
    return [
        schemas.ReviewWithNames(
            review_id=r.review_id,
            user_id=r.user_id,
            business_id=r.business_id,
            stars=r.stars,
            useful=r.useful,
            funny=r.funny,
            cool=r.cool,
            text=r.text,
            date=r.date,
            year=r.year,
            month=r.month,
            user_name=r.user_name,
            business_name=r.business_name
        ) for r in reviews
    ]