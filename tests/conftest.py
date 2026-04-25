import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from fastapi.testclient import TestClient
from datetime import datetime

# Add src to path for imports
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from src.db.database import Base
from src.db import models
from src.api.business_routes import router as business_router
from src.api.review_routes import router as review_router
from src.api.user_routes import router as user_router
from src.api.tip_routes import router as tip_router
from src.api.checkin_routes import router as checkin_router
from fastapi import FastAPI

# Use in-memory SQLite for tests
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="function")
def db():
    """Create a fresh database for each test"""
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    yield db
    db.close()
    Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(db: Session):
    """Create test client with dependency override"""
    app = FastAPI()
    
    # Include routers
    app.include_router(business_router, prefix="/businesses", tags=["businesses"])
    app.include_router(review_router, prefix="/reviews", tags=["reviews"])
    app.include_router(user_router, prefix="/users", tags=["users"])
    app.include_router(tip_router, prefix="/tips", tags=["tips"])
    app.include_router(checkin_router, prefix="/checkins", tags=["checkins"])
    
    def override_get_db():
        try:
            yield db
        finally:
            pass
    
    # Override dependency
    from src.api.business_routes import get_db
    app.dependency_overrides[get_db] = override_get_db
    
    return TestClient(app)


@pytest.fixture
def sample_business(db: Session):
    """Create a sample business for testing"""
    business = models.Business(
        business_id="biz_001",
        name="Test Restaurant",
        address="123 Main St",
        city="Portland",
        state="OR",
        postal_code="97201",
        latitude=45.5152,
        longitude=-122.6784,
        stars=4.5,
        review_count=100,
        is_open=1,
        categories="Restaurants,Italian",
        hours='{"Monday": "10:00-22:00"}'
    )
    db.add(business)
    db.commit()
    db.refresh(business)
    return business


@pytest.fixture
def sample_user(db: Session):
    """Create a sample user for testing"""
    user = models.User(
        user_id="user_001",
        name="John Doe",
        review_count=25,
        yelping_since=datetime(2020, 1, 1),
        useful=150,
        funny=50,
        cool=30,
        fans=5,
        average_stars=4.2
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture
def sample_review(db: Session, sample_business, sample_user):
    """Create a sample review for testing"""
    review = models.Review(
        review_id="rev_001",
        user_id=sample_user.user_id,
        business_id=sample_business.business_id,
        stars=5,
        useful=10,
        funny=2,
        cool=5,
        text="Great food and service!",
        date=datetime(2023, 6, 15),
        year=2023,
        month=6
    )
    db.add(review)
    db.commit()
    db.refresh(review)
    return review


@pytest.fixture
def sample_tip(db: Session, sample_business, sample_user):
    """Create a sample tip for testing"""
    tip = models.Tip(
        user_id=sample_user.user_id,
        business_id=sample_business.business_id,
        text="Try the pasta!",
        date=datetime(2023, 6, 15),
        compliment_count=5,
        year=2023
    )
    db.add(tip)
    db.commit()
    db.refresh(tip)
    return tip


@pytest.fixture
def sample_checkin(db: Session, sample_business):
    """Create a sample checkin for testing"""
    checkin = models.Checkin(
        business_id=sample_business.business_id,
        date="2023-06-15"
    )
    db.add(checkin)
    db.commit()
    db.refresh(checkin)
    return checkin
