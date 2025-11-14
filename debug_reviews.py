#!/usr/bin/env python3
"""
Debug script to investigate review count discrepancies
"""
import os
import sys
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from core.config import DATABASE_URL
from db import models

def debug_user_reviews():
    # Connect to database
    engine = create_engine(DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    try:
        # Test user with known discrepancy
        test_user_id = 'wVuIwsYDsCE9eWe5HDBGeg'  # Julie
        
        print("=== DEBUGGING REVIEW COUNT DISCREPANCY ===")
        print(f"User ID: {test_user_id}")
        
        # 1. Check user's review_count field
        user = db.query(models.User).filter(models.User.user_id == test_user_id).first()
        if user:
            print(f"User review_count field: {user.review_count}")
        
        # 2. Count ALL reviews for this user (including orphaned ones)
        total_reviews = db.query(models.Review).filter(models.Review.user_id == test_user_id).count()
        print(f"Total reviews in DB for user: {total_reviews}")
        
        # 3. Count reviews that have valid business relationships
        reviews_with_business = db.query(models.Review).filter(
            models.Review.user_id == test_user_id,
            models.Review.business_id.isnot(None)
        ).count()
        print(f"Reviews with business_id: {reviews_with_business}")
        
        # 4. Count reviews that pass the JOIN query (what the API returns)
        join_query_count = db.query(models.Review).join(
            models.User, models.Review.user_id == models.User.user_id, isouter=True
        ).join(
            models.Business, models.Review.business_id == models.Business.business_id, isouter=True
        ).filter(models.Review.user_id == test_user_id).count()
        print(f"Reviews passing JOIN query: {join_query_count}")
        
        # 5. Find orphaned reviews (reviews with business_id that don't exist in business table)
        orphaned_reviews = db.execute(text("""
            SELECT r.review_id, r.business_id, r.text[:50] as text_snippet
            FROM reviews r 
            LEFT JOIN businesses b ON r.business_id = b.business_id
            WHERE r.user_id = :user_id AND b.business_id IS NULL
        """), {"user_id": test_user_id}).fetchall()
        
        print(f"\nOrphaned reviews (business_id not in businesses table): {len(orphaned_reviews)}")
        for review in orphaned_reviews:
            print(f"  - Review ID: {review.review_id}")
            print(f"    Business ID: {review.business_id}")
            print(f"    Text: {review.text_snippet}...")
            print()
        
        # 6. Check if there are NULL business_id reviews
        null_business_reviews = db.query(models.Review).filter(
            models.Review.user_id == test_user_id,
            models.Review.business_id.is_(None)
        ).count()
        print(f"Reviews with NULL business_id: {null_business_reviews}")
        
    finally:
        db.close()

if __name__ == "__main__":
    debug_user_reviews()