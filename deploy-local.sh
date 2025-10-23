#!/bin/bash

# Raspberry Pi Local Deployment Script
echo "🍓 Starting FastAPI Yelp App on Raspberry Pi..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
    echo "✅ Environment variables loaded"
else
    echo "❌ .env file not found!"
    exit 1
fi

# Activate virtual environment if it exists
if [ -d ".venv" ]; then
    source .venv/bin/activate
    echo "✅ Virtual environment activated"
else
    echo "⚠️  No virtual environment found, using system Python"
fi

# Install/update dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Test database connection
echo "🔌 Testing database connection..."
python -c "
import os
import sys
sys.path.append('src')
from db.database import get_database_url, engine
from sqlalchemy import text

try:
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1'))
        print('✅ Database connection successful!')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    exit(1)
"

# Start the application
echo "🚀 Starting FastAPI application..."
echo "📱 API will be available at: http://${API_HOST}:${API_PORT}"
echo "📚 Documentation at: http://${API_HOST}:${API_PORT}/docs"
echo ""
echo "Press Ctrl+C to stop the server"

# Start with uvicorn
uvicorn src.main:app --host ${API_HOST:-0.0.0.0} --port ${API_PORT:-8000} --reload
