#!/bin/bash

# Test script for Songs API with Auth0
echo "🎵 Testing Songs API with Auth0 OAuth2..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get a fresh token
echo "🔑 Getting Auth0 token..."
TOKEN=$(ruby get_token.rb 2>/dev/null | grep "📋 Full token:" -A1 | tail -1)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ Failed to get token${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Token obtained${NC}"

# Test 1: Public endpoint (should work without auth)
echo
echo "🧪 Test 1: GET /songs (public endpoint)"
RESPONSE=$(curl -s -w "%{http_code}" http://localhost:4567/songs)
HTTP_CODE=${RESPONSE: -3}
BODY=${RESPONSE%???}

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Public endpoint accessible${NC}"
    echo "📋 Response: $BODY"
else
    echo -e "${RED}❌ Public endpoint failed (HTTP $HTTP_CODE)${NC}"
    echo "📋 Response: $BODY"
fi

# Test 2: Protected endpoint without auth (should fail)
echo
echo "🧪 Test 2: POST /songs without authentication"
RESPONSE=$(curl -s -w "%{http_code}" -X POST http://localhost:4567/songs \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Song","url":"https://example.com/test"}')
HTTP_CODE=${RESPONSE: -3}
BODY=${RESPONSE%???}

if [ "$HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✅ Authentication required (as expected)${NC}"
    echo "📋 Response: $BODY"
else
    echo -e "${RED}❌ Should require authentication (HTTP $HTTP_CODE)${NC}"
    echo "📋 Response: $BODY"
fi

# Test 3: Protected endpoint with valid token (should work)
echo
echo "🧪 Test 3: POST /songs with valid Auth0 token"
RESPONSE=$(curl -s -w "%{http_code}" -X POST http://localhost:4567/songs \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"name":"Test Song from API","url":"https://example.com/test-api"}')
HTTP_CODE=${RESPONSE: -3}
BODY=${RESPONSE%???}

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo -e "${GREEN}✅ Song created successfully${NC}"
    echo "📋 Response: $BODY"
else
    echo -e "${RED}❌ Song creation failed (HTTP $HTTP_CODE)${NC}"
    echo "📋 Response: $BODY"
fi

# Test 4: Verify the song was added
echo
echo "🧪 Test 4: GET /songs (verify new song added)"
RESPONSE=$(curl -s -w "%{http_code}" http://localhost:4567/songs)
HTTP_CODE=${RESPONSE: -3}
BODY=${RESPONSE%???}

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Songs list retrieved${NC}"
    echo "📋 Response: $BODY"
    
    # Check if our test song appears in the list
    if [[ $BODY == *"Test Song from API"* ]]; then
        echo -e "${GREEN}🎉 Test song found in the list!${NC}"
    else
        echo -e "${YELLOW}⚠️ Test song not found in the list${NC}"
    fi
else
    echo -e "${RED}❌ Failed to retrieve songs list (HTTP $HTTP_CODE)${NC}"
fi

# Test 5: Test /me endpoint
echo
echo "🧪 Test 5: GET /me (user info with token)"
RESPONSE=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:4567/me)
HTTP_CODE=${RESPONSE: -3}
BODY=${RESPONSE%???}

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ User info retrieved${NC}"
    echo "📋 Response: $BODY"
else
    echo -e "${RED}❌ User info failed (HTTP $HTTP_CODE)${NC}"
    echo "📋 Response: $BODY"
fi

echo
echo "🎵 Songs API testing complete!"
