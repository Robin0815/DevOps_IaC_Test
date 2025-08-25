#!/bin/bash

echo "🚀 Starting Task Scheduling Tools..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

echo "✅ Docker is running"

# Start Airflow
echo "🌪️  Starting Apache Airflow..."
cd airflow
echo "Initializing Airflow database..."
docker-compose up airflow-init
echo "Starting Airflow services..."
docker-compose up -d
cd ..

# Start Prefect
echo "🔮 Starting Prefect..."
cd prefect
docker-compose up -d
cd ..

# Start StackStorm
echo "⚡ Starting StackStorm..."
cd stackstorm
docker-compose up -d
cd ..

# Start Jenkins
echo "🏗️  Starting Jenkins..."
cd jenkins
docker-compose up -d
cd ..

# Start SaltStack
echo "🧂 Starting SaltStack..."
cd saltstack
docker-compose up -d
cd ..

echo ""
echo "🎉 All services started!"
echo ""
echo "📊 Access your tools:"
echo "• Airflow:    http://localhost:8080 (airflow/airflow)"
echo "• Prefect:    http://localhost:4200"
echo "• StackStorm: https://localhost (st2admin/Ch@ngeMe)"
echo "• Jenkins:    http://localhost:8081 (get password with: docker-compose -f jenkins/docker-compose.yml exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword bba9e054e6a545efbef166cfc5cdf689)"
echo "• SaltStack:  http://localhost:3333 (Web UI) | http://localhost:8000 (API)"
echo ""
echo "📋 Check status with: docker ps"
echo "🛑 Stop all with: ./stop-all.sh"