#!/usr/bin/env python3
"""
Test database connection and check table contents
"""
import sys
import os

# Add the src directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from src.db.database import SessionLocal, engine
from src.db.models import Business, Review, User, Tip, Checkin
from sqlalchemy import text

def test_connection():
    """Test database connection and table contents"""
    try:
        # Test basic connection
        with engine.connect() as connection:
            result = connection.execute(text("SELECT version();"))
            version = result.fetchone()[0]
            print(f"✅ Database connection successful!")
            print(f"PostgreSQL version: {version}")
            
        # Test table existence and row counts
        db = SessionLocal()
        try:
            # Check each table
            tables = [
                ("businesses", Business),
                ("reviews", Review), 
                ("users", User),
                ("tips", Tip),
                ("checkins", Checkin)
            ]
            
            for table_name, model in tables:
                try:
                    count = db.query(model).count()
                    print(f"📊 {table_name}: {count} records")
                    
                    # Show first few records if any exist
                    if count > 0:
                        first_records = db.query(model).limit(3).all()
                        print(f"   Sample records from {table_name}:")
                        for i, record in enumerate(first_records, 1):
                            print(f"   {i}. {record.__dict__}")
                    else:
                        print(f"   ⚠️  {table_name} table is empty")
                        
                except Exception as e:
                    print(f"❌ Error querying {table_name}: {e}")
                    
        finally:
            db.close()
            
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False
    
    return True

if __name__ == "__main__":
    print("🔍 Testing database connection and table contents...")
    print("=" * 60)
    test_connection()
