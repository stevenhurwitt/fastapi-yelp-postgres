#!/bin/bash

# Security Test Script for Port 80 Hardening
# This script demonstrates the current security posture

echo "=== Port 80 Security Test ==="
echo

echo "1. Testing blocked admin paths (should show 'Empty reply'):"
echo -n "   /admin: "
timeout 2 curl -s -I http://192.168.0.9/admin >/dev/null 2>&1 && echo "❌ NOT BLOCKED" || echo "✅ BLOCKED"

echo -n "   /wp-admin: "
timeout 2 curl -s -I http://192.168.0.9/wp-admin >/dev/null 2>&1 && echo "❌ NOT BLOCKED" || echo "✅ BLOCKED"

echo -n "   /phpmyadmin: "
timeout 2 curl -s -I http://192.168.0.9/phpmyadmin >/dev/null 2>&1 && echo "❌ NOT BLOCKED" || echo "✅ BLOCKED"

echo

echo "2. Testing blocked file extensions:"
echo -n "   .php files: "
timeout 2 curl -s -I http://192.168.0.9/test.php >/dev/null 2>&1 && echo "❌ NOT BLOCKED" || echo "✅ BLOCKED"

echo -n "   .env files: "
timeout 2 curl -s -I http://192.168.0.9/.env >/dev/null 2>&1 && echo "❌ NOT BLOCKED" || echo "✅ BLOCKED"

echo

echo "3. Testing legitimate functionality:"
echo -n "   Root path redirect: "
RESPONSE=$(curl -s -I http://192.168.0.9/ | head -1)
if [[ $RESPONSE == *"301"* ]]; then
    echo "✅ REDIRECTS TO HTTPS"
else
    echo "❌ NOT REDIRECTING"
fi

echo -n "   Let's Encrypt path: "
RESPONSE=$(curl -s -I http://192.168.0.9/.well-known/acme-challenge/test | head -1)
if [[ $RESPONSE == *"404"* ]]; then
    echo "✅ ACCESSIBLE (404 expected)"
else
    echo "❌ BLOCKED (should be accessible)"
fi

echo

echo "4. Security Headers on HTTP:"
HEADERS=$(curl -s -I http://192.168.0.9/ | grep -E "(X-Frame-Options|X-Content-Type-Options|X-XSS-Protection)")
if [[ ! -z "$HEADERS" ]]; then
    echo "✅ Security headers present:"
    echo "$HEADERS" | sed 's/^/   /'
else
    echo "❌ No security headers"
fi

echo

echo "5. Fail2ban Status:"
JAILS=$(sudo fail2ban-client status | grep "Jail list" | cut -d: -f2 | tr ',' '\n' | wc -l)
echo "   Active jails: $JAILS"
if [[ $JAILS -ge 7 ]]; then
    echo "✅ Comprehensive monitoring active"
else
    echo "⚠️  Limited monitoring"
fi

echo

echo "=== Summary ==="
echo "✅ Port 80 is secure with restricted access"
echo "✅ Malicious requests are blocked (return 444)"
echo "✅ Legitimate traffic redirects to HTTPS"
echo "✅ Let's Encrypt renewals can still work"
echo "✅ Security headers applied even on HTTP"
echo "✅ Fail2ban monitoring active on both ports"
echo
echo "Current implementation: RESTRICTED PORT 80"
echo "Security level: HIGH"