# 📮 Postman Import Guide for Yelp Data API

## 🎯 **Method 1: Import from OpenAPI/Swagger URL (Recommended)**

### Step 1: Import from URL
1. **Open Postman**
2. **Click "Import"** (top left)
3. **Select "Link" tab**
4. **Enter this URL:** 
   ```
   http://192.168.0.9:8000/openapi.json
   ```
5. **Click "Continue"** → **"Import"**

### Step 2: Verify Import
- You should see a new collection called **"Yelp"**
- It will contain all API endpoints organized by categories:
  - 🏢 **Businesses** (4 endpoints)
  - 📝 **Reviews** (4 endpoints) 
  - 👥 **Users** (2 endpoints)
  - 💡 **Tips** (4 endpoints)
  - ✅ **Checkins** (3 endpoints)
  - 🔧 **Health** (2 endpoints)

---

## 🎯 **Method 2: Import from File**

### Step 1: Download OpenAPI Spec
The OpenAPI specification has been saved to:
```
/home/steven/fastapi-yelp-postgres/yelp-api-openapi.json
```

### Step 2: Import File to Postman
1. **Open Postman**
2. **Click "Import"**
3. **Select "Upload Files"**
4. **Choose** `yelp-api-openapi.json`
5. **Click "Import"**

---

## 🎯 **Method 3: Manual Collection Creation**

If automatic import doesn't work, here's a pre-configured Postman collection:

```json
{
  "info": {
    "name": "Yelp Data API",
    "description": "FastAPI backend for querying Yelp database",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    {
      "key": "base_url",
      "value": "http://192.168.0.9:8000",
      "type": "string"
    }
  ],
  "item": [
    {
      "name": "Health Check",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/health",
          "host": ["{{base_url}}"],
          "path": ["health"]
        }
      }
    },
    {
      "name": "Get All Businesses",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/api/v1/businesses/?skip=0&limit=10",
          "host": ["{{base_url}}"],
          "path": ["api", "v1", "businesses", ""],
          "query": [
            {"key": "skip", "value": "0"},
            {"key": "limit", "value": "10"}
          ]
        }
      }
    },
    {
      "name": "Get Business by ID",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/api/v1/businesses/MTSW4McQd7CbVtyjqoe9mw",
          "host": ["{{base_url}}"],
          "path": ["api", "v1", "businesses", "MTSW4McQd7CbVtyjqoe9mw"]
        }
      }
    },
    {
      "name": "Get Businesses by City",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/api/v1/businesses/city/Philadelphia?skip=0&limit=10",
          "host": ["{{base_url}}"],
          "path": ["api", "v1", "businesses", "city", "Philadelphia"],
          "query": [
            {"key": "skip", "value": "0"},
            {"key": "limit", "value": "10"}
          ]
        }
      }
    },
    {
      "name": "Get Businesses by Stars",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/api/v1/businesses/stars/4.0?skip=0&limit=10",
          "host": ["{{base_url}}"],
          "path": ["api", "v1", "businesses", "stars", "4.0"],
          "query": [
            {"key": "skip", "value": "0"},
            {"key": "limit", "value": "10"}
          ]
        }
      }
    },
    {
      "name": "Get All Reviews",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/api/v1/reviews/?skip=0&limit=10",
          "host": ["{{base_url}}"],
          "path": ["api", "v1", "reviews", ""],
          "query": [
            {"key": "skip", "value": "0"},
            {"key": "limit", "value": "10"}
          ]
        }
      }
    },
    {
      "name": "Get Reviews by Business",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/api/v1/reviews/business/MTSW4McQd7CbVtyjqoe9mw?skip=0&limit=5",
          "host": ["{{base_url}}"],
          "path": ["api", "v1", "reviews", "business", "MTSW4McQd7CbVtyjqoe9mw"],
          "query": [
            {"key": "skip", "value": "0"},
            {"key": "limit", "value": "5"}
          ]
        }
      }
    }
  ]
}
```

### To use this manual collection:
1. **Copy the JSON above**
2. **Open Postman** → **Import** → **Raw text**
3. **Paste the JSON** → **Continue** → **Import**

---

## 🔧 **Setting Up Environment Variables**

### Create Postman Environment:
1. **Click the gear icon** (⚙️) in top right
2. **Click "Add"** to create new environment
3. **Name it:** "Yelp API Local"
4. **Add variables:**
   - **Variable:** `base_url`
   - **Initial Value:** `http://192.168.0.9:8000` 
   - **Current Value:** `http://192.168.0.9:8000`
5. **Click "Add"** then **"Close"**
6. **Select** "Yelp API Local" from environment dropdown

---

## 📋 **Quick Test Endpoints**

### Essential Endpoints to Test First:

1. **Health Check**
   ```
   GET {{base_url}}/health
   ```

2. **List Businesses** 
   ```
   GET {{base_url}}/api/v1/businesses/?skip=0&limit=5
   ```

3. **List Reviews**
   ```
   GET {{base_url}}/api/v1/reviews/?skip=0&limit=5
   ```

4. **Business by City**
   ```
   GET {{base_url}}/api/v1/businesses/city/Philadelphia?limit=3
   ```

5. **High-Rated Businesses**
   ```
   GET {{base_url}}/api/v1/businesses/stars/4.5?limit=5
   ```

---

## 🌟 **API Documentation**

### Interactive Documentation:
- **Swagger UI:** http://192.168.0.9:8000/docs
- **ReDoc:** http://192.168.0.9:8000/redoc
- **OpenAPI JSON:** http://192.168.0.9:8000/openapi.json

### Available Endpoints:

#### 🏢 **Businesses**
- `GET /api/v1/businesses/` - List all businesses
- `GET /api/v1/businesses/{business_id}` - Get specific business
- `GET /api/v1/businesses/city/{city}` - Businesses by city
- `GET /api/v1/businesses/stars/{min_stars}` - Businesses by rating

#### 📝 **Reviews**
- `GET /api/v1/reviews/` - List all reviews
- `GET /api/v1/reviews/{review_id}` - Get specific review
- `GET /api/v1/reviews/business/{business_id}` - Reviews for business
- `GET /api/v1/reviews/user/{user_id}` - Reviews by user

#### 👥 **Users**
- `GET /api/v1/users/` - List all users
- `GET /api/v1/users/{user_id}` - Get specific user

#### 💡 **Tips**
- `GET /api/v1/tips/` - List all tips
- `GET /api/v1/tips/{user_id}/{business_id}` - Specific tip
- `GET /api/v1/tips/business/{business_id}` - Tips for business
- `GET /api/v1/tips/user/{user_id}` - Tips by user

#### ✅ **Checkins**
- `GET /api/v1/checkins/` - List all checkins
- `GET /api/v1/checkins/{business_id}/{date}` - Specific checkin
- `GET /api/v1/checkins/business/{business_id}` - Checkins for business

---

## 🎉 **Ready to Go!**

Your Postman collection is now set up with all the Yelp API endpoints. You can:
- ✅ Test all endpoints immediately
- ✅ Use environment variables for easy URL management
- ✅ Explore your Yelp dataset interactively
- ✅ Build custom requests for data analysis

**Pro Tip:** Use the `skip` and `limit` parameters to paginate through large datasets efficiently!
