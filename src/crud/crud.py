from sqlalchemy.orm import Session
from typing import List, Optional
from ..db import models
from ..schemas import schemas

# Business CRUD operations
def get_businesses(db: Session, skip: int = 0, limit: int = 100) -> List[models.Business]:
    return db.query(models.Business).offset(skip).limit(limit).all()

def get_business(db: Session, business_id: str) -> Optional[models.Business]:
    return db.query(models.Business).filter(models.Business.business_id == business_id).first()

def get_businesses_by_city(db: Session, city: str, skip: int = 0, limit: int = 100) -> List[models.Business]:
    return db.query(models.Business).filter(models.Business.city == city).offset(skip).limit(limit).all()

def get_businesses_by_stars(db: Session, min_stars: float, skip: int = 0, limit: int = 100) -> List[models.Business]:
    return db.query(models.Business).filter(models.Business.stars >= min_stars).offset(skip).limit(limit).all()

# Review CRUD operations
def get_reviews(db: Session, skip: int = 0, limit: int = 100) -> List[models.Review]:
    # Use a conservative limit for large datasets
    safe_limit = min(limit, 20)
    return db.query(models.Review).order_by(models.Review.date.desc()).offset(skip).limit(safe_limit).all()

def get_reviews_simple_with_names(db: Session, skip: int = 0, limit: int = 100):
    """Fallback function - get reviews with minimal joins for performance"""
    safe_limit = min(limit, 5)  # Very small limit for testing
    
    return db.query(
        models.Review.review_id,
        models.Review.user_id, 
        models.Review.business_id,
        models.Review.stars,
        models.Review.text,
        models.Review.date
    ).order_by(models.Review.date.desc()).offset(skip).limit(safe_limit).all()

def get_reviews_with_names(db: Session, skip: int = 0, limit: int = 100):
    """Get reviews with user and business names - ultra-optimized for large datasets"""
    # Very conservative limit to prevent memory issues
    safe_limit = min(limit, 10)  # Reduced to 10 for large datasets
    
    # Use subquery to limit before joining to reduce memory usage
    review_subquery = db.query(models.Review).order_by(
        models.Review.date.desc()
    ).offset(skip).limit(safe_limit).subquery()
    
    return db.query(
        review_subquery.c.review_id,
        review_subquery.c.user_id,
        review_subquery.c.business_id,
        review_subquery.c.stars,
        review_subquery.c.useful,
        review_subquery.c.funny,
        review_subquery.c.cool,
        review_subquery.c.text,
        review_subquery.c.date,
        review_subquery.c.year,
        review_subquery.c.month,
        models.User.name.label('user_name'),
        models.Business.name.label('business_name')
    ).select_from(review_subquery).join(
        models.User, review_subquery.c.user_id == models.User.user_id, isouter=True
    ).join(
        models.Business, review_subquery.c.business_id == models.Business.business_id, isouter=True
    ).all()

def get_review(db: Session, review_id: str) -> Optional[models.Review]:
    return db.query(models.Review).filter(models.Review.review_id == review_id).first()

def get_review_with_names(db: Session, review_id: str):
    """Get a specific review with user and business names"""
    return db.query(
        models.Review.review_id,
        models.Review.user_id,
        models.Review.business_id,
        models.Review.stars,
        models.Review.useful,
        models.Review.funny,
        models.Review.cool,
        models.Review.text,
        models.Review.date,
        models.Review.year,
        models.Review.month,
        models.User.name.label('user_name'),
        models.Business.name.label('business_name')
    ).join(
        models.User, models.Review.user_id == models.User.user_id, isouter=True
    ).join(
        models.Business, models.Review.business_id == models.Business.business_id, isouter=True
    ).filter(models.Review.review_id == review_id).first()

def get_reviews_by_business(db: Session, business_id: str, skip: int = 0, limit: int = 100) -> List[models.Review]:
    return db.query(models.Review).filter(models.Review.business_id == business_id).offset(skip).limit(limit).all()

def get_reviews_by_business_with_names(db: Session, business_id: str, skip: int = 0, limit: int = 100):
    """Get reviews for a business with user and business names - ultra-optimized"""
    safe_limit = min(limit, 10)  # Very conservative limit
    
    # Filter first, then join to minimize data processing
    review_subquery = db.query(models.Review).filter(
        models.Review.business_id == business_id
    ).order_by(models.Review.date.desc()).offset(skip).limit(safe_limit).subquery()
    
    return db.query(
        review_subquery.c.review_id,
        review_subquery.c.user_id,
        review_subquery.c.business_id,
        review_subquery.c.stars,
        review_subquery.c.useful,
        review_subquery.c.funny,
        review_subquery.c.cool,
        review_subquery.c.text,
        review_subquery.c.date,
        review_subquery.c.year,
        review_subquery.c.month,
        models.User.name.label('user_name'),
        models.Business.name.label('business_name')
    ).select_from(review_subquery).join(
        models.User, review_subquery.c.user_id == models.User.user_id, isouter=True
    ).join(
        models.Business, review_subquery.c.business_id == models.Business.business_id, isouter=True
    ).all()

def get_reviews_by_user(db: Session, user_id: str, skip: int = 0, limit: int = 100) -> List[models.Review]:
    return db.query(models.Review).filter(models.Review.user_id == user_id).offset(skip).limit(limit).all()

def get_reviews_by_user_with_names(db: Session, user_id: str, skip: int = 0, limit: int = 100):
    """Get reviews by a user with user and business names - ultra-optimized"""
    safe_limit = min(limit, 10)  # Very conservative limit
    
    # Filter first, then join to minimize data processing
    review_subquery = db.query(models.Review).filter(
        models.Review.user_id == user_id
    ).order_by(models.Review.date.desc()).offset(skip).limit(safe_limit).subquery()
    
    return db.query(
        review_subquery.c.review_id,
        review_subquery.c.user_id,
        review_subquery.c.business_id,
        review_subquery.c.stars,
        review_subquery.c.useful,
        review_subquery.c.funny,
        review_subquery.c.cool,
        review_subquery.c.text,
        review_subquery.c.date,
        review_subquery.c.year,
        review_subquery.c.month,
        models.User.name.label('user_name'),
        models.Business.name.label('business_name')
    ).select_from(review_subquery).join(
        models.User, review_subquery.c.user_id == models.User.user_id, isouter=True
    ).join(
        models.Business, review_subquery.c.business_id == models.Business.business_id, isouter=True
    ).all()

# User CRUD operations
def get_users(db: Session, skip: int = 0, limit: int = 100) -> List[models.User]:
    return db.query(models.User).offset(skip).limit(limit).all()

def get_user(db: Session, user_id: str) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.user_id == user_id).first()

# Tip CRUD operations
def get_tips(db: Session, skip: int = 0, limit: int = 100) -> List[models.Tip]:
    return db.query(models.Tip).offset(skip).limit(limit).all()

def get_tip(db: Session, user_id: str, business_id: str) -> Optional[models.Tip]:
    return db.query(models.Tip).filter(
        models.Tip.user_id == user_id, 
        models.Tip.business_id == business_id
    ).first()

def get_tips_by_business(db: Session, business_id: str, skip: int = 0, limit: int = 100) -> List[models.Tip]:
    return db.query(models.Tip).filter(models.Tip.business_id == business_id).offset(skip).limit(limit).all()

def get_tips_by_user(db: Session, user_id: str, skip: int = 0, limit: int = 100) -> List[models.Tip]:
    return db.query(models.Tip).filter(models.Tip.user_id == user_id).offset(skip).limit(limit).all()

# Checkin CRUD operations
def get_checkins(db: Session, skip: int = 0, limit: int = 100) -> List[models.Checkin]:
    return db.query(models.Checkin).offset(skip).limit(limit).all()

def get_checkin(db: Session, business_id: str, date: str) -> Optional[models.Checkin]:
    return db.query(models.Checkin).filter(
        models.Checkin.business_id == business_id,
        models.Checkin.date == date
    ).first()

def get_checkins_by_business(db: Session, business_id: str, skip: int = 0, limit: int = 100) -> List[models.Checkin]:
    return db.query(models.Checkin).filter(models.Checkin.business_id == business_id).offset(skip).limit(limit).all()