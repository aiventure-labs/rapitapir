#!/bin/bash
TOKEN=""

echo "🧪 Testing OAuth2 API with real Auth0 token..."

echo "1. Testing public endpoint (GET /tasks):"
curl -s http://localhost:4567/tasks | jq .

echo -e "\n2. Testing protected endpoint without token:"
curl -s -X POST http://localhost:4567/tasks -H "Content-Type: application/json" -d '{"title":"Test"}' | jq .

echo -e "\n3. Testing protected endpoint WITH valid token:"
curl -s -X POST http://localhost:4567/tasks -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"title":"Auth0 Success!","completed":false}' | jq .

echo -e "\n4. Testing tasks list after creation:"
curl -s http://localhost:4567/tasks | jq .
