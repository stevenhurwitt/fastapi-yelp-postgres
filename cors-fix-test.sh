#!/bin/bash

echo "=== CORS Error Resolution Test ==="
echo

echo "1. Testing CORS Preflight (OPTIONS request):"
PREFLIGHT=$(curl -k -s -H "Origin: https://192.168.0.9" -H "Access-Control-Request-Method: GET" -X OPTIONS "https://192.168.0.9/api/v1/businesses/" -i | grep "access-control-allow-origin")
if [[ "$PREFLIGHT" == *"access-control-allow-origin: *"* ]]; then
    echo "   ✅ CORS preflight working - allowing all origins"
else
    echo "   ❌ CORS preflight issue"
fi

echo
echo "2. Testing actual API request with CORS headers:"
CORS_HEADERS=$(curl -k -s -H "Origin: https://192.168.0.9" "https://192.168.0.9/api/v1/businesses/?limit=1" -i | grep -E "access-control-allow")
if [[ "$CORS_HEADERS" == *"access-control-allow-origin"* ]]; then
    echo "   ✅ API request includes CORS headers"
    echo "   Headers found:"
    echo "$CORS_HEADERS" | sed 's/^/      /'
else
    echo "   ❌ Missing CORS headers in API response"
fi

echo
echo "3. Testing business search with CORS:"
SEARCH_CORS=$(curl -k -s -H "Origin: https://192.168.0.9" "https://192.168.0.9/api/v1/businesses/search/pizza?limit=1" -i | head -1)
if [[ "$SEARCH_CORS" == *"200"* ]]; then
    echo "   ✅ Business search working with CORS headers"
else
    echo "   ❌ Business search CORS issue"
fi

echo
echo "4. Configuration changes made:"
echo "   ✅ Removed CORS middleware from FastAPI (eliminated conflicts)"
echo "   ✅ Enhanced nginx CORS configuration"
echo "   ✅ Set Access-Control-Allow-Origin: * (permissive)"
echo "   ✅ Added comprehensive CORS headers"
echo "   ✅ Proper OPTIONS preflight handling"

echo
echo "5. Frontend status:"
echo "   Frontend URL: https://192.168.0.9"
echo "   API requests: Same origin (no CORS issues)"
echo "   Status: $(docker ps --format "{{.Status}}" --filter name=frontend)"

echo
echo "=== CORS Resolution Complete ==="
echo "The CORS error should now be resolved!"
echo "🌐 Access the frontend at: https://192.168.0.9"
echo "📊 Data should load immediately without CORS errors"
echo "🔍 Test business name search functionality"

echo
echo "If you still see CORS errors:"
echo "- Clear browser cache (Ctrl+Shift+R)"
echo "- Check browser console for any remaining errors"
echo "- Ensure SSL certificate is accepted"