#!/usr/bin/env python3
"""
Script to fix review_count discrepancies in the users table
"""

import sys
import os
import asyncio
from pathlib import Path

# Add src to path
sys.path.append(str(Path(__file__).parent / 'src'))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from core.config import Settings

def fix_review_counts():
    """Update all user review_count fields to match actual review counts"""
    
    settings = Settings()
    
    # Create database connection
    DATABASE_URL = f"postgresql://{settings.database_user}:{settings.database_password}@{settings.database_host}:{settings.database_port}/{settings.database_name}"
    engine = create_engine(DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    db = SessionLocal()
    
    try:
        print("🔧 Starting bulk review_count fix...")
        
        # First, show sample of current discrepancies
        sample_result = db.execute(text("""
            SELECT 
                u.user_id,
                u.name,
                u.review_count as stated_count,
                COALESCE(r.actual_count, 0) as actual_count,
                (u.review_count - COALESCE(r.actual_count, 0)) as discrepancy
            FROM yelp_users u
            LEFT JOIN (
                SELECT user_id, COUNT(*) as actual_count
                FROM reviews 
                GROUP BY user_id
            ) r ON u.user_id = r.user_id
            WHERE u.review_count != COALESCE(r.actual_count, 0)
            ORDER BY ABS(u.review_count - COALESCE(r.actual_count, 0)) DESC
            LIMIT 10
        """))
        
        sample_discrepancies = sample_result.fetchall()
        
        print("Sample of worst discrepancies:")
        print("=" * 80)
        for row in sample_discrepancies:
            name = row.name[:20] if row.name else "Unknown"
            print(f"{name:<20} | Stated: {row.stated_count:>6} | Actual: {row.actual_count:>6} | Diff: {row.discrepancy:>+7}")
        
        # Count total discrepancies before fix
        count_result = db.execute(text("""
            SELECT COUNT(*) as total_discrepancies
            FROM yelp_users u
            LEFT JOIN (
                SELECT user_id, COUNT(*) as actual_count
                FROM reviews 
                GROUP BY user_id
            ) r ON u.user_id = r.user_id
            WHERE u.review_count != COALESCE(r.actual_count, 0)
        """))
        
        total_before = count_result.fetchone().total_discrepancies
        print(f"\nTotal users with incorrect review_count: {total_before:,}")
        
        print("\n🔄 Performing bulk update...")
        
        # Bulk update all review counts
        update_result = db.execute(text("""
            UPDATE yelp_users 
            SET review_count = COALESCE(actual_counts.actual_count, 0)
            FROM (
                SELECT user_id, COUNT(*) as actual_count
                FROM reviews 
                GROUP BY user_id
            ) actual_counts
            WHERE yelp_users.user_id = actual_counts.user_id
            AND yelp_users.review_count != actual_counts.actual_count
        """))
        
        rows_updated = update_result.rowcount
        
        # Also update users with 0 reviews
        zero_update_result = db.execute(text("""
            UPDATE yelp_users 
            SET review_count = 0
            WHERE user_id NOT IN (SELECT DISTINCT user_id FROM reviews)
            AND review_count != 0
        """))
        
        zero_rows_updated = zero_update_result.rowcount
        
        # Commit all changes
        db.commit()
        
        total_updated = rows_updated + zero_rows_updated
        
        print(f"✅ Successfully updated {total_updated:,} user review counts!")
        print(f"   - {rows_updated:,} users with reviews updated")
        print(f"   - {zero_rows_updated:,} users with zero reviews updated")
        
        # Verify the fix
        print("\n🔍 Verification - checking remaining discrepancies...")
        verify_result = db.execute(text("""
            SELECT COUNT(*) as remaining_discrepancies
            FROM yelp_users u
            LEFT JOIN (
                SELECT user_id, COUNT(*) as actual_count
                FROM reviews 
                GROUP BY user_id
            ) r ON u.user_id = r.user_id
            WHERE u.review_count != COALESCE(r.actual_count, 0)
        """))
        
        remaining = verify_result.fetchone().remaining_discrepancies
        
        if remaining == 0:
            print("✅ All review counts are now accurate!")
        else:
            print(f"⚠️  {remaining:,} discrepancies still remain")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    fix_review_counts()