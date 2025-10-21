#!/usr/bin/env python3
"""
Check actual database schema
"""
import sys
import os

# Add the src directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from src.db.database import engine
from sqlalchemy import text

def check_schema():
    """Check actual database schema"""
    try:
        with engine.connect() as connection:
            # Check what tables exist
            tables_result = connection.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
                ORDER BY table_name;
            """))
            
            print("📋 Tables in database:")
            tables = []
            for row in tables_result:
                table_name = row[0]
                tables.append(table_name)
                print(f"   - {table_name}")
            
            print("\n" + "="*60)
            
            # Check columns for each table
            for table in tables:
                print(f"\n📊 Columns in '{table}' table:")
                columns_result = connection.execute(text(f"""
                    SELECT column_name, data_type, is_nullable
                    FROM information_schema.columns 
                    WHERE table_name = '{table}' 
                    AND table_schema = 'public'
                    ORDER BY ordinal_position;
                """))
                
                for row in columns_result:
                    col_name, data_type, nullable = row
                    print(f"   - {col_name}: {data_type} ({'nullable' if nullable == 'YES' else 'not null'})")
                    
                # Check row count
                count_result = connection.execute(text(f"SELECT COUNT(*) FROM {table};"))
                count = count_result.fetchone()[0]
                print(f"   📈 Rows: {count:,}")
                    
    except Exception as e:
        print(f"❌ Error checking schema: {e}")

if __name__ == "__main__":
    print("🔍 Checking actual database schema...")
    print("=" * 60)
    check_schema()
