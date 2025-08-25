# Task Scheduling and Automation Tools

This directory contains Docker setups for five popular task scheduling, orchestration, and automation tools:

## Quick Start

```bash
# Make scripts executable
chmod +x start-all.sh stop-all.sh setup-workflows.sh

# Start all services
./start-all.sh

# Setup example workflows
./setup-workflows.sh

# Stop all services
./stop-all.sh
```

## Example Workflows

Each tool includes a data processing workflow example:

- **Airflow**: `airflow/dags/data_processing_workflow.py` - ETL pipeline with task dependencies
- **Prefect**: `prefect/data_processing_flow.py` - Modern Python workflow with decorators
- **StackStorm**: `stackstorm/packs/data_processing/` - Event-driven workflow pack
- **Jenkins**: `jenkins/jobs/DataProcessingPipeline.groovy` - CI/CD pipeline script
- **SaltStack**: `saltstack/salt-config/data_processing.sls` - Infrastructure state management

### Quick Test Commands

```bash
# Test Airflow DAG
curl -X POST 'http://localhost:8080/api/v1/dags/data_processing_workflow/dagRuns' \
  -H 'Content-Type: application/json' -u 'airflow:airflow' \
  -d '{"dag_run_id": "manual_test"}'

# Test Prefect Flow (requires local Python setup)
cd prefect && python data_processing_flow.py

# Test SaltStack State
docker-compose -f saltstack/docker-compose.yml exec salt-master \
  salt '*' state.apply data_processing
```

## Individual Service Management

Each service now has dedicated start/stop scripts with health checks and colored output:

### Start Individual Services
```bash
cd airflow && ./start.sh       # 🌪️  Apache Airflow
cd prefect && ./start.sh       # 🔮 Prefect  
cd stackstorm && ./start.sh    # ⚡ StackStorm
cd jenkins && ./start.sh       # 🏗️  Jenkins
cd saltstack && ./start.sh     # 🧂 SaltStack
cd dolphinscheduler && ./start.sh # 🐬 DolphinScheduler
```

### Stop Individual Services
```bash
cd <service> && ./stop.sh              # Clean stop
cd <service> && ./stop.sh -v           # Stop and clean volumes
cd <service> && ./stop.sh --force      # Force cleanup without prompts
```

### Service Access Information

| Service | Web UI | Credentials | Port |
|---------|--------|-------------|------|
| **Airflow** | http://localhost:8080 | airflow/airflow | 8080 |
| **Prefect** | http://localhost:4200 | No auth required | 4200 |
| **StackStorm** | http://localhost:8090 | No auth required | 8090 |
| **Jenkins** | http://localhost:8081 | See initial setup | 8081 |
| **SaltStack** | http://localhost:3333 | No auth required | 3333 |
| **DolphinScheduler** | http://localhost:12345/dolphinscheduler/ui | admin/dolphinscheduler123 | 12345 |

### Advanced Management
```bash
# Global management (from main directory)
./start-all.sh              # Start all services with health checks
./stop-all.sh               # Stop all services
./status.sh                 # Check status of all services
./logs.sh <service> -f      # Follow logs for specific service
./restart.sh <service>      # Restart specific service
```

## Monitoring

```bash
# Check running containers
docker ps

# View logs
docker-compose logs -f [service-name]

# Monitor resources
docker stats
```