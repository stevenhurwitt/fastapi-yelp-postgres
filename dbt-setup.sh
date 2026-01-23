#!/bin/bash
# Quick setup script for dbt

set -e

echo "🚀 Setting up dbt for Yelp Analytics..."

# Check if virtual environment is activated
if [[ -z "$VIRTUAL_ENV" ]]; then
    echo "⚠️  Virtual environment not detected. Activating..."
    source .venv/bin/activate
fi

# Install dbt if not already installed
echo "📦 Installing dbt packages..."
pip install -q dbt-core dbt-postgres

# Create .dbt directory in home if it doesn't exist
mkdir -p ~/.dbt

# Check if profiles.yml exists
if [ ! -f ~/.dbt/profiles.yml ]; then
    echo "📝 Copying profiles.yml to ~/.dbt/"
    cp dbt/profiles.yml ~/.dbt/profiles.yml
    echo "⚠️  Please edit ~/.dbt/profiles.yml with your database credentials"
else
    echo "✓ profiles.yml already exists in ~/.dbt/"
fi

# Test dbt connection
echo ""
echo "🔍 Testing dbt connection..."
cd dbt
if dbt debug; then
    echo ""
    echo "✅ DBT setup successful!"
    echo ""
    echo "Next steps:"
    echo "  1. Review/update database credentials in ~/.dbt/profiles.yml"
    echo "  2. Run: cd dbt && dbt run"
    echo "  3. Test: dbt test"
    echo "  4. Generate docs: dbt docs generate && dbt docs serve"
else
    echo ""
    echo "❌ Connection test failed. Please configure ~/.dbt/profiles.yml"
    echo "   You can use environment variables:"
    echo "   export DB_USER=your_user"
    echo "   export DB_PASSWORD=your_password"
    echo "   export DB_NAME=yelp"
fi
