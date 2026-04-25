# DBT Integration for Yelp Analytics

This directory contains dbt (data build tool) models for transforming and analyzing the Yelp dataset.

## 📊 Overview

DBT provides a SQL-based transformation layer on top of your raw Yelp data, creating analytics-ready tables and views.

### Project Structure

```
dbt/
├── dbt_project.yml          # DBT project configuration
├── profiles.yml             # Database connection settings (copy to ~/.dbt/)
├── models/
│   ├── staging/            # Clean, standardized views of raw data
│   │   ├── stg_businesses.sql
│   │   ├── stg_reviews.sql
│   │   ├── stg_users.sql
│   │   ├── stg_tips.sql
│   │   ├── stg_checkins.sql
│   │   └── schema.yml      # Tests and documentation
│   ├── intermediate/       # Business logic transformations
│   └── marts/              # Analytics-ready tables
│       ├── business_analytics.sql    # Comprehensive business metrics
│       ├── user_insights.sql         # User behavior analysis
│       ├── review_trends.sql         # Time-series review patterns
│       ├── category_analytics.sql    # Category performance
│       └── schema.yml
├── tests/                  # Custom data quality tests
│   ├── review_count_consistency.sql
│   ├── orphaned_reviews.sql
│   └── orphaned_tips.sql
└── macros/                 # Reusable SQL macros
    ├── generate_date_spine.sql
    └── safe_divide.sql
```

## 🚀 Quick Start

### 1. Install DBT

```bash
# Activate your virtual environment
source .venv/bin/activate

# Install dbt
pip install -r requirements.txt
```

### 2. Configure Database Connection

Copy the profiles.yml to your home directory:

```bash
mkdir -p ~/.dbt
cp dbt/profiles.yml ~/.dbt/profiles.yml
```

Edit `~/.dbt/profiles.yml` with your database credentials:

```yaml
yelp_analytics:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: your_db_user
      password: your_db_password
      port: 5432
      dbname: yelp
      schema: public
      threads: 4
```

Or use environment variables:

```bash
export DB_USER=steven
export DB_PASSWORD="Secret\!1234"
export DB_NAME=steven
```

### 3. Test Connection

```bash
cd dbt
dbt debug
```

### 4. Run DBT Models

```bash
# Run all models
dbt run

# Run only staging models
dbt run --select staging

# Run only marts
dbt run --select marts

# Run a specific model
dbt run --select business_analytics
```

### 5. Test Data Quality

```bash
# Run all tests
dbt test

# Run tests for specific model
dbt test --select business_analytics
```

### 6. Generate Documentation

```bash
# Generate and serve documentation
dbt docs generate
dbt docs serve
```

This will open a browser with interactive documentation and data lineage diagrams.

## 📈 Analytics Models

### Business Analytics
**Table:** `marts.business_analytics`

Comprehensive business metrics combining reviews, tips, and checkins:
- Total reviews, tips, and checkins
- Calculated average ratings
- Sentiment analysis (positive/neutral/negative)
- Business tier classification
- Engagement metrics

**Example Query:**
```sql
SELECT 
    business_name,
    city,
    calculated_avg_rating,
    total_reviews,
    business_tier,
    positive_review_percentage
FROM marts.business_analytics
WHERE city = 'Philadelphia'
  AND business_tier = 'High Rated'
ORDER BY total_reviews DESC
LIMIT 10;
```

### User Insights
**Table:** `marts.user_insights`

User behavior and engagement analysis:
- Review activity patterns
- Engagement scores
- User tier classification (Elite Power User, Power User, etc.)
- Sentiment tendencies
- Positivity percentage

**Example Query:**
```sql
SELECT 
    user_name,
    user_tier,
    actual_reviews_written,
    engagement_score,
    positivity_percentage
FROM marts.user_insights
WHERE user_tier IN ('Elite Power User', 'Power User')
ORDER BY engagement_score DESC
LIMIT 20;
```

### Review Trends
**Table:** `marts.review_trends`

Time-series analysis by month and location:
- Monthly review volumes
- Average ratings over time
- Sentiment trends
- Engagement patterns

**Example Query:**
```sql
SELECT 
    month,
    city,
    review_count,
    avg_stars,
    positive_count,
    negative_count
FROM marts.review_trends
WHERE city = 'Las Vegas'
  AND month >= '2020-01-01'
ORDER BY month DESC;
```

### Category Analytics
**Table:** `marts.category_analytics`

Performance metrics by business category:
- Businesses per category
- Average ratings by category
- Review volumes
- Category trends by location

**Example Query:**
```sql
SELECT 
    category,
    city,
    businesses_in_category,
    avg_category_rating,
    total_reviews,
    avg_positive_percentage
FROM marts.category_analytics
WHERE city = 'Phoenix'
ORDER BY total_reviews DESC
LIMIT 20;
```

## 🔍 Data Quality Tests

DBT includes automated data quality tests:

- **Uniqueness:** Ensures primary keys are unique
- **Not Null:** Validates required fields
- **Referential Integrity:** Checks for orphaned records
- **Value Ranges:** Validates stars are between 0-5
- **Custom Tests:** Review count consistency, orphaned data detection

## 🔄 Integration with FastAPI

You can query dbt-generated tables from your FastAPI endpoints:

```python
# Example: Add to src/api/analytics_routes.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from src.db.database import get_db

router = APIRouter(prefix="/analytics", tags=["analytics"])

@router.get("/business-analytics")
async def get_business_analytics(
    city: str = None,
    min_rating: float = None,
    db: Session = Depends(get_db)
):
    query = "SELECT * FROM marts.business_analytics WHERE 1=1"
    params = {}
    
    if city:
        query += " AND city = :city"
        params['city'] = city
    
    if min_rating:
        query += " AND calculated_avg_rating >= :min_rating"
        params['min_rating'] = min_rating
    
    result = db.execute(query, params)
    return result.fetchall()
```

## 📅 Scheduling

For production, schedule dbt runs to refresh analytics:

### Using cron:
```bash
# Run daily at 2 AM
0 2 * * * cd /home/steven/fastapi-yelp-postgres/dbt && dbt run
```

### Using systemd timer:
Create `/etc/systemd/system/dbt-yelp.service` and corresponding timer.

### Using AWS:
- Use AWS EventBridge to trigger Lambda
- Lambda executes dbt via ECS task or Fargate

## 🛠️ Development Workflow

1. **Make changes to models:** Edit SQL files in `models/`
2. **Test locally:** `dbt run --select <model_name>`
3. **Validate:** `dbt test`
4. **Document:** Update schema.yml files
5. **Commit:** Git commit your changes
6. **Deploy:** Run in production environment

## 📊 Common Commands

```bash
# Full refresh (drop and recreate all tables)
dbt run --full-refresh

# Run specific model and downstream dependencies
dbt run --select business_analytics+

# Run upstream dependencies
dbt run --select +business_analytics

# Dry run to see what would execute
dbt run --select business_analytics --dry-run

# Compile SQL without running
dbt compile
```

## 🎯 Best Practices

1. **Incremental Models:** For large datasets, consider making models incremental
2. **Partitioning:** Use date partitioning for time-series data
3. **Indexes:** Marts include indexes for common query patterns
4. **Documentation:** Keep schema.yml files updated
5. **Testing:** Add tests for critical business logic
6. **Version Control:** Track all dbt code in git

## 🔗 Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [dbt Postgres Adapter](https://docs.getdbt.com/reference/warehouse-setups/postgres-setup)

## 🆘 Troubleshooting

**Connection Issues:**
```bash
dbt debug  # Check connection and configuration
```

**Model Failures:**
```bash
dbt run --select <model_name> --debug
```

**Clear Cache:**
```bash
dbt clean
dbt deps
```

**View Compiled SQL:**
Check the `target/compiled/` directory to see the actual SQL that dbt generates.
