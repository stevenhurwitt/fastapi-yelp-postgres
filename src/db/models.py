from sqlalchemy import Column, Integer, String, Float, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from .database import Base

class Business(Base):
    __tablename__ = 'business'

    business_id = Column(String, primary_key=True)
    name = Column(String)
    address = Column(String)
    city = Column(String)
    state = Column(String)
    postal_code = Column(String)
    latitude = Column(Float)
    longitude = Column(Float)
    stars = Column(Float)
    review_count = Column(Integer)
    is_open = Column(Integer)
    attributes = Column(String)
    categories = Column(String)
    hours = Column(String)

class Review(Base):
    __tablename__ = 'reviews'

    review_id = Column(String, primary_key=True)
    user_id = Column(String)
    business_id = Column(String)
    stars = Column(Float)
    useful = Column(Integer)
    funny = Column(Integer)
    cool = Column(Integer)
    text = Column(Text)
    date = Column(DateTime)
    year = Column(Integer)
    month = Column(Integer)

class User(Base):
    __tablename__ = 'yelp_users'

    user_id = Column(String, primary_key=True)
    name = Column(String)
    review_count = Column(Integer)
    yelping_since = Column(DateTime)
    friends = Column(String)
    useful = Column(Integer)
    funny = Column(Integer)
    cool = Column(Integer)
    fans = Column(Integer)
    elite = Column(String)
    average_stars = Column(Float)
    compliment_hot = Column(Integer)
    compliment_more = Column(Integer)
    compliment_profile = Column(Integer)
    compliment_cute = Column(Integer)
    compliment_list = Column(Integer)
    compliment_note = Column(Integer)
    compliment_plain = Column(Integer)
    compliment_cool = Column(Integer)
    compliment_funny = Column(Integer)
    compliment_writer = Column(Integer)
    compliment_photos = Column(Integer)

class Tip(Base):
    __tablename__ = 'tips'

    user_id = Column(String, primary_key=True)
    business_id = Column(String, primary_key=True)
    text = Column(Text)
    date = Column(DateTime)
    compliment_count = Column(Integer)
    year = Column(Integer)

class Checkin(Base):
    __tablename__ = 'checkins'

    business_id = Column(String, primary_key=True)
    date = Column(String, primary_key=True)  # Note: date is stored as text in your DB