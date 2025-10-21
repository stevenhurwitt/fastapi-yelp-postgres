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
    return db.query(models.Review).offset(skip).limit(limit).all()

def get_review(db: Session, review_id: str) -> Optional[models.Review]:
    return db.query(models.Review).filter(models.Review.review_id == review_id).first()

def get_reviews_by_business(db: Session, business_id: str, skip: int = 0, limit: int = 100) -> List[models.Review]:
    return db.query(models.Review).filter(models.Review.business_id == business_id).offset(skip).limit(limit).all()

def get_reviews_by_user(db: Session, user_id: str, skip: int = 0, limit: int = 100) -> List[models.Review]:
    return db.query(models.Review).filter(models.Review.user_id == user_id).offset(skip).limit(limit).all()

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