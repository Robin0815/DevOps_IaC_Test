#!/bin/bash

echo "🧂 Starting SaltStack..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

# Start SaltStack
docker-compose up -d

echo "✅ SaltStack started!"
echo ""
echo "📊 Access SaltStack:"
echo "• Web UI: http://localhost:3333"
echo "• Salt API: http://localhost:8000"
echo ""
echo "🔧 Useful commands:"
echo "# Test minion connection:"
echo "docker-compose exec salt-master salt '*' test.ping"
echo ""
echo "# Apply states:"
echo "docker-compose exec salt-master salt '*' state.apply"
echo ""
echo "# Run command on minions:"
echo "docker-compose exec salt-master salt '*' cmd.run 'date'"
echo ""
echo "📋 Check logs: docker-compose logs -f"
echo "🛑 Stop: docker-compose down"