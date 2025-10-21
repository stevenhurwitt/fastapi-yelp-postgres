from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from db.database import SessionLocal, init_db
from db.models import Business, Review, User, Tip, Checkin

app = FastAPI()

# Dependency to get the database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.on_event("startup")
def startup_event():
    init_db()

@app.get("/businesses/")
def read_businesses(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    return db.query(Business).offset(skip).limit(limit).all()

@app.get("/reviews/")
def read_reviews(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    return db.query(Review).offset(skip).limit(limit).all()

@app.get("/users/")
def read_users(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    return db.query(User).offset(skip).limit(limit).all()

@app.get("/tips/")
def read_tips(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    return db.query(Tip).offset(skip).limit(limit).all()

@app.get("/checkins/")
def read_checkins(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    return db.query(Checkin).offset(skip).limit(limit).all()
