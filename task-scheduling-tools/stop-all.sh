#!/bin/bash

echo "🛑 Stopping Task Scheduling Tools..."

# Stop Airflow
echo "Stopping Airflow..."
cd airflow
docker-compose down
cd ..

# Stop Prefect
echo "Stopping Prefect..."
cd prefect
docker-compose down
cd ..

# Stop StackStorm
echo "Stopping StackStorm..."
cd stackstorm
docker-compose down
cd ..

# Stop Jenkins
echo "Stopping Jenkins..."
cd jenkins
docker-compose down
cd ..

# Stop SaltStack
echo "Stopping SaltStack..."
cd saltstack
docker-compose down
cd ..

echo "✅ All services stopped!"