# Example FastAPI routes for querying dbt analytics models
# Add this to your FastAPI application to expose analytics endpoints

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional, List
from src.db.database import get_db

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/business-analytics")
async def get_business_analytics(
    city: Optional[str] = None,
    min_rating: Optional[float] = None,
    business_tier: Optional[str] = None,
    limit: int = Query(default=100, le=1000),
    db: Session = Depends(get_db)
):
    """
    Get business analytics from dbt mart table.
    
    Query the pre-aggregated business_analytics table created by dbt.
    """
    query = """
        SELECT 
            business_id,
            business_name,
            city,
            state,
            calculated_avg_rating,
            actual_review_count,
            unique_reviewers,
            positive_reviews,
            negative_reviews,
            business_tier,
            positive_review_percentage,
            total_tips,
            total_checkins
        FROM marts.business_analytics 
        WHERE 1=1
    """
    params = {}
    
    if city:
        query += " AND city = :city"
        params['city'] = city
    
    if min_rating:
        query += " AND calculated_avg_rating >= :min_rating"
        params['min_rating'] = min_rating
    
    if business_tier:
        query += " AND business_tier = :business_tier"
        params['business_tier'] = business_tier
    
    query += " ORDER BY actual_review_count DESC LIMIT :limit"
    params['limit'] = limit
    
    result = db.execute(query, params)
    return [dict(row) for row in result]


@router.get("/user-insights")
async def get_user_insights(
    user_tier: Optional[str] = None,
    min_engagement_score: Optional[int] = None,
    limit: int = Query(default=100, le=1000),
    db: Session = Depends(get_db)
):
    """
    Get user insights from dbt mart table.
    
    Analyzes user behavior patterns and engagement levels.
    """
    query = """
        SELECT 
            user_id,
            user_name,
            user_tier,
            actual_reviews_written,
            engagement_score,
            positivity_percentage,
            is_elite,
            years_yelping,
            unique_businesses_reviewed
        FROM marts.user_insights
        WHERE 1=1
    """
    params = {}
    
    if user_tier:
        query += " AND user_tier = :user_tier"
        params['user_tier'] = user_tier
    
    if min_engagement_score:
        query += " AND engagement_score >= :min_engagement_score"
        params['min_engagement_score'] = min_engagement_score
    
    query += " ORDER BY engagement_score DESC LIMIT :limit"
    params['limit'] = limit
    
    result = db.execute(query, params)
    return [dict(row) for row in result]


@router.get("/review-trends")
async def get_review_trends(
    city: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Get review trends over time from dbt mart table.
    
    Time-series analysis of review patterns.
    """
    query = """
        SELECT 
            month,
            city,
            state,
            review_count,
            avg_stars,
            positive_count,
            neutral_count,
            negative_count,
            avg_votes_per_review
        FROM marts.review_trends
        WHERE 1=1
    """
    params = {}
    
    if city:
        query += " AND city = :city"
        params['city'] = city
    
    if start_date:
        query += " AND month >= :start_date"
        params['start_date'] = start_date
    
    if end_date:
        query += " AND month <= :end_date"
        params['end_date'] = end_date
    
    query += " ORDER BY month DESC, review_count DESC"
    
    result = db.execute(query, params)
    return [dict(row) for row in result]


@router.get("/category-analytics")
async def get_category_analytics(
    category: Optional[str] = None,
    city: Optional[str] = None,
    min_businesses: int = Query(default=0),
    limit: int = Query(default=100, le=1000),
    db: Session = Depends(get_db)
):
    """
    Get category performance analytics from dbt mart table.
    
    Shows which business categories perform best.
    """
    query = """
        SELECT 
            category,
            city,
            state,
            businesses_in_category,
            open_businesses,
            avg_category_rating,
            total_reviews,
            avg_reviews_per_business,
            avg_positive_percentage
        FROM marts.category_analytics
        WHERE businesses_in_category >= :min_businesses
    """
    params = {'min_businesses': min_businesses}
    
    if category:
        query += " AND category ILIKE :category"
        params['category'] = f"%{category}%"
    
    if city:
        query += " AND city = :city"
        params['city'] = city
    
    query += " ORDER BY total_reviews DESC LIMIT :limit"
    params['limit'] = limit
    
    result = db.execute(query, params)
    return [dict(row) for row in result]


@router.get("/top-businesses")
async def get_top_businesses(
    city: str,
    category: Optional[str] = None,
    limit: int = Query(default=10, le=50),
    db: Session = Depends(get_db)
):
    """
    Get top-rated businesses in a city.
    
    Convenience endpoint for common query pattern.
    """
    query = """
        SELECT 
            business_name,
            calculated_avg_rating,
            actual_review_count,
            positive_review_percentage,
            categories,
            address
        FROM marts.business_analytics
        WHERE city = :city
          AND business_tier = 'High Rated'
          AND actual_review_count >= 20
    """
    params = {'city': city}
    
    if category:
        query += " AND :category = ANY(category_array)"
        params['category'] = category
    
    query += " ORDER BY calculated_avg_rating DESC, actual_review_count DESC LIMIT :limit"
    params['limit'] = limit
    
    result = db.execute(query, params)
    return [dict(row) for row in result]


# To use these routes, add to your main.py:
# from src.api import analytics_routes
# app.include_router(analytics_routes.router)
