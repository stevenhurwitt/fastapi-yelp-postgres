#!/bin/bash

echo "=== Data Loading Issue Resolution Test ==="
echo

echo "1. Testing API endpoints:"
echo "   Direct backend (port 8000):"
time curl -s "http://localhost:8000/api/v1/businesses/?limit=1" > /dev/null
echo "   Status: $(curl -s -o /dev/null -w '%{http_code}' "http://localhost:8000/api/v1/businesses/?limit=1")"

echo
echo "   Through nginx proxy (HTTPS):"
time curl -k -s "https://192.168.0.9/api/v1/businesses/?limit=1" > /dev/null
echo "   Status: $(curl -k -s -o /dev/null -w '%{http_code}' "https://192.168.0.9/api/v1/businesses/?limit=1")"

echo
echo "2. Frontend configuration:"
echo "   Frontend URL: https://192.168.0.9 (through nginx)"
echo "   API Base URL: https://192.168.0.9 (same origin - no CORS)"
echo "   Proxy: nginx -> backend:8000"

echo
echo "3. Testing business search functionality:"
SEARCH_TEST=$(curl -k -s "https://192.168.0.9/api/v1/businesses/search/pizza?limit=1")
if [[ "$SEARCH_TEST" == *"business_id"* ]]; then
    echo "   ✅ Business search working through proxy"
    echo "   Sample: $(echo "$SEARCH_TEST" | jq -r '.[0].name' 2>/dev/null || echo "Pizza business found")"
else
    echo "   ❌ Business search issue: $SEARCH_TEST"
fi

echo
echo "4. SSL Certificate status:"
echo "   ⚠️  Using self-signed certificate"
echo "   🔒 Browser must accept certificate to load data"
echo "   💡 In browser: Click 'Advanced' -> 'Proceed to 192.168.0.9'"

echo
echo "5. Container status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(frontend|web)"

echo
echo "=== Next Steps ==="
echo "1. Open browser to: https://192.168.0.9"
echo "2. Accept the SSL certificate warning"
echo "3. Data should now load properly"
echo "4. Test the business name search functionality"

echo
echo "If data still doesn't load:"
echo "- Check browser console (F12 -> Console tab)"
echo "- Look for network errors or CORS issues"
echo "- Verify certificate was accepted"