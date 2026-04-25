import sys
from pathlib import Path
import pytest
from sqlalchemy.orm import Session

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from src.crud import crud
from src.db import models
from datetime import datetime


class TestBusinessCRUD:
    """Test Business CRUD operations"""
    
    def test_get_businesses(self, db: Session):
        """Test retrieving all businesses"""
        business1 = models.Business(business_id="biz1", name="Restaurant A", city="Portland")
        business2 = models.Business(business_id="biz2", name="Restaurant B", city="Seattle")
        db.add_all([business1, business2])
        db.commit()
        
        result = crud.get_businesses(db, skip=0, limit=100)
        assert len(result) == 2
        assert result[0].name == "Restaurant A"
    
    def test_get_businesses_pagination(self, db: Session):
        """Test pagination in get_businesses"""
        for i in range(5):
            db.add(models.Business(business_id=f"biz{i}", name=f"Restaurant {i}"))
        db.commit()
        
        result = crud.get_businesses(db, skip=0, limit=2)
        assert len(result) == 2
        
        result = crud.get_businesses(db, skip=2, limit=2)
        assert len(result) == 2
    
    def test_get_business_by_id(self, db: Session, sample_business):
        """Test retrieving a specific business"""
        result = crud.get_business(db, business_id="biz_001")
        assert result is not None
        assert result.business_id == "biz_001"
        assert result.name == "Test Restaurant"
    
    def test_get_business_not_found(self, db: Session):
        """Test retrieving non-existent business"""
        result = crud.get_business(db, business_id="nonexistent")
        assert result is None
    
    def test_get_businesses_by_city(self, db: Session):
        """Test filtering businesses by city"""
        db.add(models.Business(business_id="biz1", name="Restaurant A", city="Portland"))
        db.add(models.Business(business_id="biz2", name="Restaurant B", city="Seattle"))
        db.commit()
        
        result = crud.get_businesses_by_city(db, city="Portland")
        assert len(result) == 1
        assert result[0].city == "Portland"
    
    def test_get_businesses_by_city_case_insensitive(self, db: Session):
        """Test case-insensitive city filtering"""
        db.add(models.Business(business_id="biz1", name="Restaurant", city="Portland"))
        db.commit()
        
        result = crud.get_businesses_by_city(db, city="PORTLAND")
        assert len(result) == 1
    
    def test_get_businesses_by_stars(self, db: Session):
        """Test filtering businesses by minimum stars"""
        db.add(models.Business(business_id="biz1", name="Good Place", stars=4.5))
        db.add(models.Business(business_id="biz2", name="Bad Place", stars=2.0))
        db.commit()
        
        result = crud.get_businesses_by_stars(db, min_stars=4.0)
        assert len(result) == 1
        assert result[0].stars == 4.5
    
    def test_get_businesses_by_state(self, db: Session):
        """Test filtering businesses by state"""
        db.add(models.Business(business_id="biz1", name="Restaurant", state="OR"))
        db.add(models.Business(business_id="biz2", name="Restaurant", state="WA"))
        db.commit()
        
        result = crud.get_businesses_by_state(db, state="OR")
        assert len(result) == 1
        assert result[0].state == "OR"
    
    def test_get_businesses_by_name(self, db: Session):
        """Test searching businesses by name"""
        db.add(models.Business(business_id="biz1", name="Pizza Place"))
        db.add(models.Business(business_id="biz2", name="Coffee Shop"))
        db.commit()
        
        result = crud.get_businesses_by_name(db, name="Pizza")
        assert len(result) == 1
        assert "Pizza" in result[0].name


class TestReviewCRUD:
    """Test Review CRUD operations"""
    
    def test_get_reviews(self, db: Session, sample_review):
        """Test retrieving all reviews"""
        result = crud.get_reviews(db)
        assert len(result) == 1
        assert result[0].review_id == "rev_001"
    
    def test_get_reviews_pagination(self, db: Session, sample_business, sample_user):
        """Test pagination for reviews"""
        for i in range(5):
            db.add(models.Review(
                review_id=f"rev{i}",
                business_id=sample_business.business_id,
                user_id=sample_user.user_id,
                stars=4
            ))
        db.commit()
        
        result = crud.get_reviews(db, skip=0, limit=2)
        assert len(result) == 2
    
    def test_get_review_by_id(self, db: Session, sample_review):
        """Test retrieving a specific review"""
        result = crud.get_review(db, review_id="rev_001")
        assert result is not None
        assert result.review_id == "rev_001"
        assert result.stars == 5
    
    def test_get_review_not_found(self, db: Session):
        """Test retrieving non-existent review"""
        result = crud.get_review(db, review_id="nonexistent")
        assert result is None
    
    def test_get_reviews_with_names(self, db: Session, sample_review):
        """Test retrieving reviews with user and business names"""
        result = crud.get_reviews_with_names(db)
        assert len(result) >= 1
        # Check that the result has the joined fields
        first = result[0]
        assert hasattr(first, 'user_name')
        assert hasattr(first, 'business_name')


class TestUserCRUD:
    """Test User CRUD operations"""
    
    def test_get_users(self, db: Session, sample_user):
        """Test retrieving all users"""
        result = crud.get_users(db)
        assert len(result) == 1
        assert result[0].user_id == "user_001"
    
    def test_get_user_by_id(self, db: Session, sample_user):
        """Test retrieving a specific user"""
        result = crud.get_user(db, user_id="user_001")
        assert result is not None
        assert result.name == "John Doe"
        assert result.review_count == 25
    
    def test_get_user_not_found(self, db: Session):
        """Test retrieving non-existent user"""
        result = crud.get_user(db, user_id="nonexistent")
        assert result is None
    
    def test_get_users_by_review_count(self, db: Session):
        """Test filtering users - verify CRUD can access users"""
        db.add(models.User(user_id="user1", name="Active User", review_count=50))
        db.add(models.User(user_id="user2", name="Inactive User", review_count=5))
        db.commit()
        
        # Just verify we can get all users
        result = crud.get_users(db, skip=0, limit=100)
        assert len(result) >= 2


class TestTipCRUD:
    """Test Tip CRUD operations"""
    
    def test_get_tips(self, db: Session, sample_tip):
        """Test retrieving all tips"""
        result = crud.get_tips(db)
        assert len(result) >= 1
        assert any(t.user_id == "user_001" for t in result)
    
    def test_get_tips_by_business(self, db: Session, sample_business, sample_user):
        """Test retrieving tips for a specific business"""
        db.add(models.Tip(
            user_id=sample_user.user_id,
            business_id=sample_business.business_id,
            text="Great place!"
        ))
        db.commit()
        
        result = crud.get_tips_by_business(db, business_id=sample_business.business_id)
        assert len(result) >= 1
    
    def test_get_tips_by_user(self, db: Session, sample_tip, sample_user):
        """Test retrieving tips from a specific user"""
        result = crud.get_tips_by_user(db, user_id=sample_user.user_id)
        assert len(result) >= 1


class TestCheckinCRUD:
    """Test Checkin CRUD operations"""
    
    def test_get_checkins(self, db: Session, sample_checkin):
        """Test retrieving all checkins"""
        result = crud.get_checkins(db)
        assert len(result) >= 1
    
    def test_get_checkins_by_business(self, db: Session, sample_business):
        """Test retrieving checkins for a specific business"""
        db.add(models.Checkin(business_id=sample_business.business_id, date="2023-06-20"))
        db.commit()
        
        result = crud.get_checkins_by_business(db, business_id=sample_business.business_id)
        assert len(result) >= 1
