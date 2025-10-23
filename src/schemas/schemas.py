from pydantic import BaseModel
from datetime import datetime
from typing import Optional

# Business schemas
class BusinessBase(BaseModel):
    business_id: str
    name: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    postal_code: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    stars: Optional[float] = None
    review_count: Optional[int] = None
    is_open: Optional[int] = None
    attributes: Optional[str] = None
    categories: Optional[str] = None
    hours: Optional[str] = None

class Business(BusinessBase):
    class Config:
        from_attributes = True

# Review schemas
class ReviewBase(BaseModel):
    review_id: str
    user_id: Optional[str] = None
    business_id: Optional[str] = None
    stars: Optional[float] = None
    useful: Optional[int] = None
    funny: Optional[int] = None
    cool: Optional[int] = None
    text: Optional[str] = None
    date: Optional[datetime] = None
    year: Optional[int] = None
    month: Optional[int] = None

class Review(ReviewBase):
    class Config:
        from_attributes = True

class ReviewWithNames(ReviewBase):
    user_name: Optional[str] = None
    business_name: Optional[str] = None
    
    class Config:
        from_attributes = True

# User schemas
class UserBase(BaseModel):
    user_id: str
    name: Optional[str] = None
    review_count: Optional[int] = None
    yelping_since: Optional[datetime] = None
    friends: Optional[str] = None
    useful: Optional[int] = None
    funny: Optional[int] = None
    cool: Optional[int] = None
    fans: Optional[int] = None
    elite: Optional[str] = None
    average_stars: Optional[float] = None
    compliment_hot: Optional[int] = None
    compliment_more: Optional[int] = None
    compliment_profile: Optional[int] = None
    compliment_cute: Optional[int] = None
    compliment_list: Optional[int] = None
    compliment_note: Optional[int] = None
    compliment_plain: Optional[int] = None
    compliment_cool: Optional[int] = None
    compliment_funny: Optional[int] = None
    compliment_writer: Optional[int] = None
    compliment_photos: Optional[int] = None

class User(UserBase):
    class Config:
        from_attributes = True

# Tip schemas
class TipBase(BaseModel):
    user_id: str
    business_id: str
    text: Optional[str] = None
    date: Optional[datetime] = None
    compliment_count: Optional[int] = None
    year: Optional[int] = None

class Tip(TipBase):
    class Config:
        from_attributes = True

# Checkin schemas
class CheckinBase(BaseModel):
    business_id: str
    date: str  # Note: stored as text in your database

class Checkin(CheckinBase):
    class Config:
        from_attributes = True