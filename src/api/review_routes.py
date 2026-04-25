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

@router.get("/debug/user/{user_id}")
def debug_user_reviews(user_id: str, db: Session = Depends(get_db)):
    """Debug endpoint to analyze review count discrepancies"""
    from ..db import models
    
    # Get user's stated review count
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    user_review_count = user.review_count if user else 0
    
    # Count total reviews for this user
    total_reviews = db.query(models.Review).filter(models.Review.user_id == user_id).count()
    
    # Count reviews with valid business_id
    reviews_with_business = db.query(models.Review).filter(
        models.Review.user_id == user_id,
        models.Review.business_id.isnot(None)
    ).count()
    
    # Count reviews that pass the JOIN (what API returns)
    join_count = db.query(models.Review).join(
        models.User, models.Review.user_id == models.User.user_id, isouter=True
    ).join(
        models.Business, models.Review.business_id == models.Business.business_id, isouter=True
    ).filter(models.Review.user_id == user_id).count()
    
    # Find orphaned reviews (business_id that doesn't exist in business table)
    orphaned_reviews = db.query(models.Review).filter(
        models.Review.user_id == user_id
    ).outerjoin(models.Business, models.Review.business_id == models.Business.business_id).filter(
        models.Business.business_id.is_(None),
        models.Review.business_id.isnot(None)
    ).all()
    
    return {
        "user_id": user_id,
        "user_stated_review_count": user_review_count,
        "total_reviews_in_db": total_reviews,
        "reviews_with_business_id": reviews_with_business,
        "reviews_passing_join": join_count,
        "orphaned_reviews": len(orphaned_reviews),
        "orphaned_review_details": [
            {
                "review_id": r.review_id,
                "business_id": r.business_id,
                "text_snippet": r.text[:100] if r.text else None
            } for r in orphaned_reviews[:5]  # First 5 only
        ]
    }

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