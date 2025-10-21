# Yelp Data FastAPI Backend

A FastAPI backend for querying data from five tables in a Yelp PostgreSQL database.

## Features

- **Businesses**: Query business data with filtering by city and star rating
- **Reviews**: Get reviews with filtering by business and user
- **Users**: Access user information
- **Tips**: Query tips with filtering by business and user
- **Checkins**: Access check-in data by business

## Project Structure

```
src/
├── main.py                 # Main FastAPI application
├── api/                    # API route handlers
│   ├── business_routes.py  # Business endpoints
│   ├── review_routes.py    # Review endpoints
│   ├── user_routes.py      # User endpoints
│   ├── tip_routes.py       # Tip endpoints
│   └── checkin_routes.py   # Checkin endpoints
├── core/
│   └── config.py          # Application configuration
├── crud/
│   └── crud.py            # Database operations
├── db/
│   ├── database.py        # Database connection
│   └── models.py          # SQLAlchemy models
└── schemas/
    └── schemas.py         # Pydantic schemas
```

## Setup

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Configure environment variables:**
```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your database credentials
DATABASE_HOST=localhost
DATABASE_PORT=5433
DATABASE_USER=your_username
DATABASE_PASSWORD=your_password
DATABASE_NAME=your_database
```

3. **Run the application:**
```bash
# Using uvicorn directly
uvicorn src.main:app --reload

# Or using the run script
python run.py
```

## API Endpoints

### Businesses
- `GET /api/v1/businesses/` - List all businesses
- `GET /api/v1/businesses/{business_id}` - Get specific business
- `GET /api/v1/businesses/city/{city}` - Get businesses by city
- `GET /api/v1/businesses/stars/{min_stars}` - Get businesses with minimum star rating

### Reviews
- `GET /api/v1/reviews/` - List all reviews
- `GET /api/v1/reviews/{review_id}` - Get specific review
- `GET /api/v1/reviews/business/{business_id}` - Get reviews for a business
- `GET /api/v1/reviews/user/{user_id}` - Get reviews by a user

### Users
- `GET /api/v1/users/` - List all users
- `GET /api/v1/users/{user_id}` - Get specific user

### Tips
- `GET /api/v1/tips/` - List all tips
- `GET /api/v1/tips/{tip_id}` - Get specific tip
- `GET /api/v1/tips/business/{business_id}` - Get tips for a business
- `GET /api/v1/tips/user/{user_id}` - Get tips by a user

### Checkins
- `GET /api/v1/checkins/` - List all checkins
- `GET /api/v1/checkins/{checkin_id}` - Get specific checkin
- `GET /api/v1/checkins/business/{business_id}` - Get checkins for a business

## Query Parameters

Most list endpoints support pagination:
- `skip`: Number of records to skip (default: 0)
- `limit`: Maximum number of records to return (default: 100)

Example: `GET /api/v1/businesses/?skip=0&limit=50`

## Interactive Documentation

Once the server is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Environment Variables

The application uses the following environment variables (defined in `.env` file):

### Database Configuration
- `DATABASE_HOST`: Database host (default: localhost)
- `DATABASE_PORT`: Database port (default: 5432)
- `DATABASE_USER`: Database username
- `DATABASE_PASSWORD`: Database password
- `DATABASE_NAME`: Database name

### Server Configuration
- `API_HOST`: API server host (default: 127.0.0.1)
- `API_PORT`: API server port (default: 8000)
- `DEBUG`: Debug mode (default: false)

### API Information
- `API_TITLE`: API title (default: Yelp Data API)
- `API_DESCRIPTION`: API description
- `API_VERSION`: API version (default: 1.0.0)

## Database Schema

The application uses the following PostgreSQL tables:
- `business` (business_id, name, address, city, state, postal_code, latitude, longitude, stars, review_count, is_open, attributes, categories, hours)
- `reviews` (review_id, user_id, business_id, stars, useful, funny, cool, text, date, year, month)
- `yelp_users` (user_id, name, review_count, yelping_since, friends, useful, funny, cool, fans, elite, average_stars, compliment_*)
- `tips` (user_id, business_id, text, date, compliment_count, year)
- `checkins` (business_id, date)
