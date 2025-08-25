#!/bin/bash

echo "🏗️  Starting Jenkins..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

# Start Jenkins
docker-compose up -d

echo "✅ Jenkins started!"
echo ""
echo "📊 Access Jenkins:"
echo "• Web UI: http://localhost:8081"
echo ""
echo "🔑 Get initial admin password:"
echo "docker-compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
echo "📋 Check logs: docker-compose logs -f jenkins"
echo "🛑 Stop: docker-compose down"