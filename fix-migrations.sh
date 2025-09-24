#!/bin/bash

set -e

echo "🗄️ Fixing Database Migrations"
echo "============================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please don't run as root. Run as regular user."
    exit 1
fi

# Check current status
echo "🔍 Checking current status..."
docker-compose ps

# Wait for postgres to be ready
echo "⏳ Waiting for postgres to be ready..."
docker-compose exec postgres pg_isready -U postgres

# Create initial migration
echo "📝 Creating initial migration..."
docker-compose exec backend npx prisma migrate dev --name init --create-only

# Mark migration as applied (baseline)
echo "🏷️ Marking migration as applied (baseline)..."
docker-compose exec backend npx prisma migrate resolve --applied init

# Generate Prisma client
echo "🔧 Generating Prisma client..."
docker-compose exec backend npx prisma generate

# Create admin user
echo "👤 Creating admin user..."
docker-compose exec backend npx tsx src/scripts/create-admin.js

# Test the API
echo "🧪 Testing API endpoints..."
curl -f http://localhost:3001/health > /dev/null && echo "✅ Backend API is working" || echo "❌ Backend API failed"
curl -f http://localhost:3001/api/test > /dev/null && echo "✅ API test endpoint working" || echo "❌ API test endpoint failed"

# Test admin dashboard
echo "🧪 Testing admin dashboard..."
curl -f http://localhost:3001/api/admin/dashboard > /dev/null && echo "✅ Admin dashboard API working" || echo "❌ Admin dashboard API failed"

# Show final status
echo "📊 Final status:"
docker-compose ps

echo ""
echo "🎉 Database migrations fixed!"
echo "============================"
echo "Backend API: http://localhost:3001/health"
echo "Admin API: http://localhost:3001/api/admin/dashboard"
echo "Frontend: http://localhost:3000"
echo "Admin Panel: http://localhost:3000/admin"
