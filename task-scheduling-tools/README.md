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

## Individual Services

### Airflow
```bash
cd airflow
docker-compose up -d
```
- Web UI: http://localhost:8080
- Username: `airflow`
- Password: `airflow`

### Prefect
```bash
cd prefect
docker-compose up -d
```
- Web UI: http://localhost:4200

### StackStorm
```bash
cd stackstorm
docker-compose up -d
```
- Web UI: https://localhost
- Username: `st2admin`
- Password: `Ch@ngeMe`

### Jenkins
```bash
cd jenkins
docker-compose up -d
```
- Web UI: http://localhost:8081
- Get initial password: `docker-compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`

### SaltStack
```bash
cd saltstack
docker-compose up -d
```
- Web UI: http://localhost:3333
- Salt API: http://localhost:8000
- Master CLI: `docker-compose exec salt-master salt --help`

## Monitoring

```bash
# Check running containers
docker ps

# View logs
docker-compose logs -f [service-name]

# Monitor resources
docker stats
```