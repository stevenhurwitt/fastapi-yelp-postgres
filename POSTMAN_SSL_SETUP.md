# 🔐 Postman SSL Setup Guide for Self-Signed Certificate

## Quick Setup (Most Important Steps)

### Step 1: Disable SSL Certificate Verification
1. Open **Postman**
2. Go to **File** → **Settings** (or **Postman** → **Preferences** on Mac)
3. Click on **General** tab
4. Find **SSL certificate verification**
5. **Turn OFF** the toggle switch
6. Click **Save**

### Step 2: Increase Request Timeout
1. In the same **Settings** → **General** tab
2. Find **Request timeout in ms**
3. Change from default (5000) to **30000** (30 seconds)
4. Click **Save**

### Step 3: Test Connection
**Use this exact URL in Postman:**
```
https://192.168.0.9/health
```

**Expected Result:**
```json
{"status":"healthy"}
```

---

## 🚀 Complete Postman Collection Setup

### Import Pre-configured Collection
1. Download the collection file: `yelp-api-postman-collection.json`
2. In Postman: **Import** → **File** → Select the JSON file
3. The collection includes all endpoints with correct SSL settings

### Manual Setup Instructions

#### **Environment Variables** (Optional but Recommended)
1. Click **Environments** (left sidebar)
2. Click **+** to create new environment
3. Name it "Yelp API Local"
4. Add variables:
   ```
   Variable: base_url
   Initial Value: https://192.168.0.9
   Current Value: https://192.168.0.9
   ```

#### **Create New Request**
1. Click **New** → **HTTP Request**
2. Set method to **GET**
3. Enter URL: `https://192.168.0.9/api/v1/businesses/?limit=5`
4. In **Headers** tab, add:
   ```
   Accept: application/json
   Content-Type: application/json
   ```

---

## 🔧 SSL Certificate Options

### Option 1: Disable SSL Verification (Recommended for Local Development)
✅ **Pros**: Quick setup, works immediately
⚠️ **Cons**: Less secure for production

**Steps**: Already covered in Step 1 above

### Option 2: Add Certificate to Postman (Advanced)
1. **Export certificate** from browser:
   - Visit `https://192.168.0.9` in browser
   - Click lock icon → Certificate → Details → Copy to File
   - Save as `yelp-api.crt`

2. **Import to Postman**:
   - Settings → Certificates → Client Certificates → Add Certificate
   - Host: `192.168.0.9`
   - Port: `443`
   - CRT file: Select the exported certificate

### Option 3: Use HTTP Endpoint (Fallback)
If HTTPS still doesn't work, use direct HTTP:
```
http://192.168.0.9:8000/api/v1/businesses/?limit=5
```

---

## 📋 Test Endpoints

### 1. Health Check (Start Here)
```
GET https://192.168.0.9/health
```
**Expected**: `{"status":"healthy"}`

### 2. Business List (Basic Test)
```
GET https://192.168.0.9/api/v1/businesses/?limit=5
```
**Expected**: Array of 5 business objects

### 3. Business Search (New Feature)
```
GET https://192.168.0.9/api/v1/businesses/search/pizza?limit=3
```
**Expected**: Array of businesses with "pizza" in name

### 4. Business by City
```
GET https://192.168.0.9/api/v1/businesses/city/Phoenix?limit=5
```
**Expected**: Array of businesses in Phoenix

### 5. Reviews
```
GET https://192.168.0.9/api/v1/reviews/?limit=5
```
**Expected**: Array of 5 review objects

---

## 🐛 Troubleshooting Common Issues

### Issue: "SSL Handshake Failed"
**Solution**: Ensure SSL certificate verification is OFF

### Issue: "Request Timeout"
**Solutions**:
1. Increase timeout to 30 seconds
2. Use HTTP endpoint: `http://192.168.0.9:8000/api/v1/...`

### Issue: "Connection Refused"
**Check**:
1. Services are running: `docker-compose -f docker-compose.local.yml ps`
2. Network connectivity: `ping 192.168.0.9`

### Issue: "Certificate Verification Error"
**Solutions**:
1. Turn OFF SSL verification (recommended)
2. Or add certificate to Postman (advanced)

---

## 🎯 Quick Start Checklist

- [ ] SSL certificate verification **OFF**
- [ ] Request timeout set to **30 seconds**
- [ ] Test URL: `https://192.168.0.9/health`
- [ ] Headers: `Accept: application/json`
- [ ] Response received in **< 1 second**

---

## 🔍 Advanced Configuration

### Custom Headers for All Requests
In Collection settings, add default headers:
```
Accept: application/json
Content-Type: application/json
User-Agent: Postman-YelpAPI-Client
```

### Request/Response Logging
1. Enable **Postman Console**: View → Show Postman Console
2. Monitor requests for debugging

### Performance Monitoring
Expected response times:
- Health check: < 50ms
- Business list (5 items): < 100ms
- Search queries: < 200ms

---

## 📞 Need Help?

If you're still having issues:
1. Check the comprehensive troubleshooting guide: `POSTMAN_TROUBLESHOOTING.md`
2. Test with curl first: `curl -k https://192.168.0.9/health`
3. Try the HTTP fallback: `http://192.168.0.9:8000/api/v1/businesses/?limit=5`

The API server is fully operational - any issues are client-side SSL configuration!