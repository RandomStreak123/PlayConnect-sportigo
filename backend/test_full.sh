#!/bin/bash
echo "=== Testing CORS preflight (OPTIONS) ==="
curl -sk -X OPTIONS https://playconnect-backend.ddev.site/api/login \
  -H "Origin: http://localhost:5174" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,Authorization" \
  -D - -o /dev/null 2>&1 | head -20

echo ""
echo "=== Testing login API ==="
curl -sk -X POST https://playconnect-backend.ddev.site/api/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:5174" \
  -d '{"username":"Devan","password":"24681000"}' | python3 -m json.tool 2>/dev/null

echo ""
echo "=== Testing Saina login ==="
curl -sk -X POST https://playconnect-backend.ddev.site/api/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:5174" \
  -d '{"username":"saina","password":"24681000"}' | python3 -m json.tool 2>/dev/null

echo ""
echo "=== Testing Ajith login ==="
curl -sk -X POST https://playconnect-backend.ddev.site/api/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:5174" \
  -d '{"username":"Ajith","password":"24681000"}' | python3 -m json.tool 2>/dev/null

echo ""
echo "=== Testing registration ==="
curl -sk -X POST https://playconnect-backend.ddev.site/api/register \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:5174" \
  -d '{"name":"TestUser","username":"testuser123","password":"testpass123","gender":"male"}' | python3 -m json.tool 2>/dev/null

echo ""
echo "=== Login with new user ==="
curl -sk -X POST https://playconnect-backend.ddev.site/api/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:5174" \
  -d '{"username":"testuser123","password":"testpass123"}' | python3 -m json.tool 2>/dev/null
