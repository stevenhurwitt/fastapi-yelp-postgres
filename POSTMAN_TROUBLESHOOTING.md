# 🔧 Postman API Timeout Troubleshooting Guide

## Issue: Postman requests timing out to https://192.168.0.9

### Quick Status Check ✅
- **API Server**: Running and responding in <0.05 seconds
- **SSL Certificate**: Working (self-signed)
- **Network**: Accessible from command line
- **Problem**: Postman-specific configuration issue

---

## 🚀 **SOLUTION STEPS**

### 1. **Disable SSL Certificate Verification**
```
Postman Settings → General → SSL certificate verification → OFF
```
**Why**: Your Raspberry Pi uses a self-signed SSL certificate that Postman doesn't trust by default.

### 2. **Increase Timeout Settings**
```
Postman Settings → General → Request timeout in ms → 30000 (30 seconds)
```
**Default is often too low for initial SSL handshake with self-signed certificates.**

### 3. **Test URLs (in order of preference)**

#### **Primary (HTTPS with nginx proxy)**:
```
https://192.168.0.9/api/v1/businesses/?limit=5
```

#### **Backup (Direct HTTP to backend)**:
```
http://192.168.0.9:8000/api/v1/businesses/?limit=5
```

### 4. **Required Headers**
```
Accept: application/json
Content-Type: application/json
```

### 5. **Test Endpoints**

#### **Health Check** (fastest):
```
GET https://192.168.0.9/health
Expected: {"status":"healthy"}
```

#### **Business List** (small dataset):
```
GET https://192.168.0.9/api/v1/businesses/?limit=5
Expected: JSON array of 5 businesses
```

#### **Business Search** (new feature):
```
GET https://192.168.0.9/api/v1/businesses/search/pizza?limit=3
Expected: JSON array of pizza businesses
```

---

## 🐛 **TROUBLESHOOTING CHECKLIST**

### If Still Timing Out:

1. **Check Network Connection**
   ```bash
   ping 192.168.0.9
   ```

2. **Test with curl** (should work):
   ```bash
   curl -k "https://192.168.0.9/health"
   ```

3. **Use HTTP instead** (bypass SSL):
   ```
   http://192.168.0.9:8000/api/v1/businesses/?limit=5
   ```

4. **Check Postman Console** (View → Show Postman Console):
   - Look for SSL handshake errors
   - Check for certificate validation failures
   - Monitor actual request/response timing

5. **Try Different Request Method**:
   - Change from GET to POST (if applicable)
   - Add explicit headers
   - Use raw JSON body format

---

## ⚡ **PERFORMANCE EXPECTATIONS**

- **Health endpoint**: ~20ms
- **Business list (5 items)**: ~50ms  
- **Business search**: ~60ms
- **Large datasets (20+ items)**: ~100ms

**If responses take >1 second, there may be a database performance issue.**

---

## 🔍 **ADVANCED DEBUGGING**

### Enable Postman Logging:
1. Help → View logs in file explorer
2. Monitor `requests.log` for detailed error messages

### Network Analysis:
```bash
# Test from Raspberry Pi itself
curl -k -w "Connect: %{time_connect}s\nSSL: %{time_appconnect}s\nTotal: %{time_total}s\n" "https://192.168.0.9/health"
```

### Alternative Testing Tools:
- **Insomnia**: Often handles self-signed certificates better
- **Browser DevTools**: F12 → Network tab
- **HTTPie**: `http --verify=no https://192.168.0.9/health`

---

## 📞 **QUICK FIXES**

### **Most Common Solution**: 
**Disable SSL verification in Postman settings** ⚙️ → SSL certificate verification → OFF

### **If Postman still fails**:
Use the HTTP endpoint directly: `http://192.168.0.9:8000/api/v1/businesses/?limit=5`

### **For Production**:
Replace self-signed certificate with Let's Encrypt certificate using the provided scripts.

---

## 🎉 Expected Results

After following these steps, you should see:
- **Fast responses** (<100ms)
- **Proper JSON data** from all endpoints  
- **No timeout errors** in Postman
- **Business search functionality** working

The API is fully operational - this is purely a Postman SSL certificate configuration issue!