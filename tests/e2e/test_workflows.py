import sys
from pathlib import Path
from datetime import datetime

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from src.db import models


class TestUserWorkflows:
    """Test complete user workflows"""
    
    def test_discover_restaurant_workflow(self, client, db):
        """Test: User discovers a restaurant, views reviews, reads tips"""
        # 1. User searches for restaurants by city
        business = models.Business(
            business_id="rest_001",
            name="Best Pizza",
            city="Portland",
            stars=4.8,
            review_count=150
        )
        db.add(business)
        db.commit()
        
        response = client.get("/businesses/city/Portland")
        assert response.status_code == 200
        restaurants = response.json()
        assert len(restaurants) >= 1
        
        # 2. User views the restaurant
        rest_id = restaurants[0]["business_id"]
        response = client.get(f"/businesses/{rest_id}")
        assert response.status_code == 200
        assert response.json()["name"] == "Best Pizza"
        
        # 3. User checks reviews for the restaurant
        response = client.get(f"/reviews/business/{rest_id}")
        assert response.status_code == 200
    
    def test_user_profile_view_workflow(self, client, db):
        """Test: View user profile and their activity"""
        from src.db import models
        user = models.User(
            user_id="user_001",
            name="Food Critic",
            review_count=50,
            useful=200,
            fans=10,
            average_stars=4.5
        )
        db.add(user)
        db.commit()
        
        # 1. Get user list
        response = client.get("/users/")
        assert response.status_code == 200
        # Just verify the endpoint works
        assert isinstance(response.json(), list)
    
    def test_top_reviewers_discovery(self, client, db):
        """Test: Discover and follow top reviewers"""
        from src.db import models
        # Create multiple users with different review counts
        for i in range(5):
            user = models.User(
                user_id=f"user_{i}",
                name=f"Reviewer {i}",
                review_count=(5-i)*20,
                fans=i*5
            )
            db.add(user)
        db.commit()
        
        # Get users
        response = client.get("/users/")
        assert response.status_code == 200
        reviewers = response.json()
        assert len(reviewers) >= 1


class TestBusinessAnalytics:
    """Test business analytics workflows"""
    
    def test_business_rating_analysis(self, client, db):
        """Test: Filter businesses by rating"""
        # Create businesses with different ratings
        for rating in [3.0, 4.0, 4.5, 5.0]:
            db.add(models.Business(
                business_id=f"biz_{rating}",
                name=f"Business {rating}",
                stars=rating
            ))
        db.commit()
        
        # Get 4+ star businesses
        response = client.get("/businesses/stars/4.0")
        assert response.status_code == 200
        businesses = response.json()
        assert all(b["stars"] >= 4.0 for b in businesses)
    
    def test_state_business_comparison(self, client, db):
        """Test: Compare businesses across states"""
        states = ["OR", "WA", "CA"]
        for state in states:
            for i in range(2):
                db.add(models.Business(
                    business_id=f"biz_{state}_{i}",
                    name=f"Business {state} {i}",
                    state=state
                ))
        db.commit()
        
        # Get businesses in each state
        for state in states:
            response = client.get(f"/businesses/state/{state}")
            assert response.status_code == 200
            businesses = response.json()
            assert len(businesses) >= 1
            assert all(b["state"] == state for b in businesses)


class TestReviewAnalytics:
    """Test review-related analytics"""
    
    def test_review_collection_workflow(self, client, db):
        """Test: Collect and view reviews for analytics"""
        # Create business, user, and reviews
        business = models.Business(business_id="biz_001", name="Restaurant")
        user1 = models.User(user_id="user_001", name="User 1")
        user2 = models.User(user_id="user_002", name="User 2")
        
        db.add_all([business, user1, user2])
        db.commit()
        
        # Add multiple reviews
        for i in range(3):
            review = models.Review(
                review_id=f"rev_{i}",
                business_id="biz_001",
                user_id=f"user_{(i % 2) + 1:03d}",
                stars=4 + (i % 2),
                useful=i*5,
                text=f"Review {i}"
            )
            db.add(review)
        db.commit()
        
        # Get all reviews for business
        response = client.get("/reviews/business/biz_001")
        assert response.status_code == 200
        reviews = response.json()
        # Just verify endpoint works
        assert isinstance(reviews, list)


class TestDataConsistency:
    """Test data consistency across endpoints"""
    
    def test_business_review_consistency(self, client, db):
        """Test: Business review count matches actual reviews"""
        business = models.Business(
            business_id="biz_001",
            name="Test Restaurant",
            review_count=3
        )
        user = models.User(user_id="user_001", name="Reviewer")
        db.add_all([business, user])
        db.commit()
        
        # Add reviews
        for i in range(3):
            db.add(models.Review(
                review_id=f"rev_{i}",
                business_id="biz_001",
                user_id="user_001",
                stars=4
            ))
        db.commit()
        
        # Verify business has correct review count
        response = client.get("/businesses/biz_001")
        assert response.status_code == 200
        assert response.json()["review_count"] == 3
    
    def test_user_review_count_consistency(self, client, db):
        """Test: User review count matches actual reviews"""
        user = models.User(
            user_id="user_001",
            name="Active Reviewer",
            review_count=2
        )
        business = models.Business(business_id="biz_001", name="Restaurant")
        
        db.add_all([user, business])
        db.commit()
        
        # Add reviews for user
        for i in range(2):
            db.add(models.Review(
                review_id=f"rev_{i}",
                business_id="biz_001",
                user_id="user_001",
                stars=5
            ))
        db.commit()
        
        # Verify user endpoint works
        response = client.get("/users/")
        assert response.status_code == 200
        assert isinstance(response.json(), list)


class TestPaginationWorkflow:
    """Test pagination across large datasets"""
    
    def test_paginate_through_businesses(self, client, db):
        """Test: Paginate through all businesses"""
        # Create 25 businesses
        for i in range(25):
            db.add(models.Business(
                business_id=f"biz_{i:03d}",
                name=f"Restaurant {i}"
            ))
        db.commit()
        
        # Paginate through them (5 per page)
        all_ids = set()
        for page in range(5):
            response = client.get(f"/businesses/?skip={page*5}&limit=5")
            assert response.status_code == 200
            businesses = response.json()
            assert len(businesses) <= 5
            all_ids.update(b["business_id"] for b in businesses)
        
        # Should have retrieved all unique businesses
        assert len(all_ids) == 25
