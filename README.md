# Yelp Data Full-Stack Application

A complete full-stack application with FastAPI backend and React frontend for querying real Yelp data from PostgreSQL database.

## 🌟 Features

### Backend (FastAPI)
- **Businesses**: Query 150K+ businesses with filtering by city and star rating
- **Reviews**: Access 6.9M+ reviews with filtering by business and user
- **Users**: Browse 1.9M+ user profiles
- **Tips**: Query tips with filtering by business and user
- **Checkins**: Access check-in data by business
- **RESTful API**: Complete CRUD operations with automatic documentation

### Frontend (React + TypeScript)
- **Business Search**: Search and filter businesses with modern UI
- **Review Browser**: Browse reviews with pagination and filtering
- **Responsive Design**: Mobile-friendly interface
- **Real-time Data**: Connected to live backend API

## 🚀 Quick Start

### Local Development
```bash
# Backend
source yelp-fastapi/bin/activate
uvicorn src.main:app --host 192.168.0.123 --port 8000 --reload

# Frontend  
cd frontend
yarn start
```

### AWS Deployment (Production)
```bash
# One-command deployment
./deploy-complete.sh
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React App     │    │   FastAPI       │    │   PostgreSQL    │
│   (Frontend)    │───▶│   (Backend)     │───▶│   (Database)    │
│   S3/CloudFront │    │   Fargate/ECS   │    │   RDS           │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 💰 Hosting Costs

| Option | Monthly Cost | Features |
|--------|-------------|----------|
| **AWS Standard** | $25-35 | Full production setup with ALB |
| **AWS Budget** | $15-25 | Direct Fargate access |
| **AWS Ultra-Budget** | $8-15 | Lambda + RDS (serverless) |

## 📚 Documentation

- [Complete AWS Deployment Guide](AWS_DEPLOYMENT_GUIDE.md)
- [API Documentation](http://localhost:8000/docs) (when running locally)
- [Frontend Demo](http://localhost:3000) (when running locally)

## Project Structure

```
├── src/                    # FastAPI Backend
│   ├── main.py                 # Main FastAPI application
│   ├── api/                    # API route handlers
│   │   ├── business_routes.py  # Business endpoints
│   │   ├── review_routes.py    # Review endpoints
│   │   ├── user_routes.py      # User endpoints
│   │   ├── tip_routes.py       # Tip endpoints
│   │   └── checkin_routes.py   # Checkin endpoints
│   ├── core/
│   │   └── config.py          # Application configuration
│   ├── crud/
│   │   └── crud.py            # Database operations
│   ├── db/
│   │   ├── database.py        # Database connection
│   │   └── models.py          # SQLAlchemy models
│   └── schemas/
│       └── schemas.py         # Pydantic schemas
├── frontend/               # React Frontend
│   ├── src/
│   │   ├── components/         # React components
│   │   ├── services/           # API service layer
│   │   ├── types/              # TypeScript definitions
│   │   └── App.tsx             # Main app component
│   ├── public/
│   └── package.json
└── requirements.txt        # Python dependencies
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

3. **Run the backend:**
```bash
# Using uvicorn directly
uvicorn src.main:app --reload --host 192.168.0.123 --port 8000

# Or using the run script
python run.py
```

4. **Run the frontend (optional):**
```bash
cd frontend
npm install
npm start
```

The frontend will be available at `http://localhost:3000`

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

## Frontend Features

The React frontend provides:
- **Business Explorer**: Search and filter businesses by city and rating
- **Review Browser**: Browse reviews with engagement metrics
- **Responsive Design**: Works on desktop and mobile
- **Real-time Data**: Live connection to the FastAPI backend
- **Modern UI**: Clean, intuitive interface with loading states

### Frontend Screenshots
- Business grid with search filters
- Review cards with star ratings and engagement
- Responsive mobile design
- Interactive pagination

## Interactive Documentation

Once the server is running, visit:
- **API Documentation**: http://192.168.0.123:8000/docs
- **Alternative Docs**: http://192.168.0.123:8000/redoc
- **Frontend App**: http://localhost:3000 (when running frontend)

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
