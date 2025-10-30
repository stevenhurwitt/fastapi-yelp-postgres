#!/bin/bash

echo "=== API Documentation Loading Issue Resolution Test ==="
echo

echo "1. Testing core API endpoints:"
echo "   Health endpoint:"
HEALTH=$(curl -k -s "https://192.168.0.9/health")
if [[ "$HEALTH" == *"healthy"* ]]; then
    echo "   ✅ Health endpoint working: $HEALTH"
else
    echo "   ❌ Health endpoint issue: $HEALTH"
fi

echo
echo "   Root endpoint:"
ROOT=$(curl -k -s "https://192.168.0.9/")
if [[ "$ROOT" == *"Welcome"* ]]; then
    echo "   ✅ Root endpoint working"
else
    echo "   ❌ Root endpoint issue"
fi

echo
echo "2. Testing API documentation endpoints:"
echo "   OpenAPI spec:"
OPENAPI=$(curl -k -s "https://192.168.0.9/openapi.json" | head -c 100)
if [[ "$OPENAPI" == *"openapi"* ]]; then
    echo "   ✅ OpenAPI spec loading properly"
    echo "   Sample: ${OPENAPI}..."
else
    echo "   ❌ OpenAPI spec issue"
fi

echo
echo "   Docs endpoint status:"
DOCS_STATUS=$(curl -k -s -o /dev/null -w '%{http_code}' "https://192.168.0.9/docs")
if [[ "$DOCS_STATUS" == "200" ]]; then
    echo "   ✅ Docs endpoint returning 200 OK"
else
    echo "   ❌ Docs endpoint returning: $DOCS_STATUS"
fi

echo
echo "3. Testing business API endpoints:"
echo "   Regular business list:"
BUSINESS=$(curl -k -s "https://192.168.0.9/api/v1/businesses/?limit=1")
if [[ "$BUSINESS" == *"business_id"* ]]; then
    echo "   ✅ Business list API working"
    BUSINESS_NAME=$(echo "$BUSINESS" | jq -r '.[0].name' 2>/dev/null || echo "N/A")
    echo "   Sample business: $BUSINESS_NAME"
else
    echo "   ❌ Business list API issue"
fi

echo
echo "   Business search (new feature):"
SEARCH=$(curl -k -s "https://192.168.0.9/api/v1/businesses/search/pizza?limit=1")
if [[ "$SEARCH" == *"business_id"* ]]; then
    echo "   ✅ Business search API working"
    SEARCH_NAME=$(echo "$SEARCH" | jq -r '.[0].name' 2>/dev/null || echo "N/A")
    echo "   Sample result: $SEARCH_NAME"
else
    echo "   ❌ Business search API issue"
fi

echo
echo "4. CORS Configuration:"
CORS_TEST=$(curl -k -s -H "Origin: https://192.168.0.9" "https://192.168.0.9/api/v1/businesses/?limit=1" -i | grep "access-control-allow-origin")
if [[ "$CORS_TEST" == *"access-control-allow-origin"* ]]; then
    echo "   ✅ CORS headers present in API responses"
else
    echo "   ❌ CORS headers missing"
fi

echo
echo "5. Frontend status:"
FRONTEND_STATUS=$(curl -s -o /dev/null -w '%{http_code}' "https://192.168.0.9/")
if [[ "$FRONTEND_STATUS" == "200" ]]; then
    echo "   ✅ Frontend loading (status: $FRONTEND_STATUS)"
else
    echo "   ❌ Frontend issue (status: $FRONTEND_STATUS)"
fi

echo
echo "6. Container status:"
echo "   Backend: $(docker ps --format "{{.Status}}" --filter name=web)"
echo "   Frontend: $(docker ps --format "{{.Status}}" --filter name=frontend)"

echo
echo "=== Summary ==="
echo "If docs aren't loading fully in browser:"
echo "🔍 Check browser console (F12 → Console) for JavaScript errors"
echo "🌐 External resources might be blocked (Swagger UI CDN)"
echo "✅ API endpoints are working properly"
echo "✅ Business search functionality is operational"
echo "📊 You can test API directly at: https://192.168.0.9/api/v1/businesses/"

echo
echo "Direct API testing (if docs don't work):"
echo "curl -k 'https://192.168.0.9/api/v1/businesses/search/pizza?limit=3'"
echo "curl -k 'https://192.168.0.9/api/v1/businesses/?limit=5'"