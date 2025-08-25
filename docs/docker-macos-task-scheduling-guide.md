# Docker on macOS: Task Scheduling Tools Setup Guide

This guide walks you through installing Docker on macOS and setting up popular task scheduling and automation tools like Apache Airflow, Prefect, StackStorm, Jenkins, and SaltStack with web interfaces accessible from your host browser.

## Prerequisites

- macOS 10.15 or later
- At least 4GB RAM (8GB+ recommended for running multiple containers)
- Administrator access to install software

## Installing Docker on macOS

### Option 1: Docker Desktop (Recommended)

1. **Download Docker Desktop**
   ```bash
   # Visit https://www.docker.com/products/docker-desktop/ or use Homebrew
   brew install --cask docker
   ```

2. **Launch Docker Desktop**
   - Open Docker Desktop from Applications
   - Follow the setup wizard
   - Sign in or create a Docker account (optional but recommended)

3. **Verify Installation**
   ```bash
   docker --version
   docker-compose --version
   ```

### Option 2: Homebrew Installation

```bash
# Install Docker and Docker Compose
brew install docker docker-compose

# Install Docker Desktop or use Colima as Docker runtime
brew install colima
colima start
```

## Task Scheduling and Automation Tools Setup

### 1. Apache Airflow

Apache Airflow is a platform for developing, scheduling, and monitoring workflows.

**Quick Setup with Docker Compose:**

```bash
# Create airflow directory
mkdir airflow-docker && cd airflow-docker

# Download docker-compose file
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.8.0/docker-compose.yaml'

# Create required directories
mkdir -p ./dags ./logs ./plugins ./config

# Set Airflow UID
echo -e "AIRFLOW_UID=$(id -u)" > .env

# Initialize database
docker-compose up airflow-init

# Start Airflow
docker-compose up -d
```

**Access Airflow Web UI:**
- URL: http://localhost:8080
- Username: `airflow`
- Password: `airflow`

**Test DAG Example:**Cr
eate a simple test DAG in `./dags/hello_world.py`:

```python
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    'owner': 'admin',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'hello_world',
    default_args=default_args,
    description='A simple hello world DAG',
    schedule_interval=timedelta(days=1),
    catchup=False,
)

hello_task = BashOperator(
    task_id='hello_world_task',
    bash_command='echo "Hello World from Airflow!"',
    dag=dag,
)
```

### 2. Prefect

Prefect is a modern workflow orchestration tool with a user-friendly interface.

**Setup with Docker:**

```bash
# Create prefect directory
mkdir prefect-docker && cd prefect-docker

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  prefect-server:
    image: prefecthq/prefect:2.14-python3.11
    ports:
      - "4200:4200"
    environment:
      - PREFECT_UI_URL=http://127.0.0.1:4200/api
      - PREFECT_API_URL=http://127.0.0.1:4200/api
      - PREFECT_SERVER_API_HOST=0.0.0.0
    command: prefect server start --host 0.0.0.0
    volumes:
      - prefect-data:/root/.prefect
    restart: unless-stopped

volumes:
  prefect-data:
EOF

# Start Prefect server
docker-compose up -d
```

**Access Prefect Web UI:**
- URL: http://localhost:4200

**Test Flow Example:**

Create `test_flow.py`:

```python
from prefect import flow, task
import time

@task
def hello_task(name: str):
    print(f"Hello {name}!")
    time.sleep(2)
    return f"Hello {name}!"

@flow
def hello_flow(name: str = "World"):
    result = hello_task(name)
    print(f"Flow completed: {result}")

if __name__ == "__main__":
    hello_flow("Prefect")
```

Run the flow:
```bash
# Install Prefect locally to run flows
pip install prefect
python test_flow.py
```

### 3. StackStorm

StackStorm is an event-driven automation platform for integration and orchestration.

**Setup with Docker:**

```bash
# Create stackstorm directory
mkdir stackstorm-docker && cd stackstorm-docker

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  stackstorm:
    image: stackstorm/stackstorm:latest
    ports:
      - "443:443"
      - "80:80"
    environment:
      - ST2_USER=st2admin
      - ST2_PASSWORD=Ch@ngeMe
    volumes:
      - stackstorm-data:/opt/stackstorm
      - stackstorm-packs:/opt/stackstorm/packs
    restart: unless-stopped

volumes:
  stackstorm-data:
  stackstorm-packs:
EOF

# Start StackStorm
docker-compose up -d
```

**Access StackStorm Web UI:**
- URL: https://localhost (accept self-signed certificate)
- Username: `st2admin`
- Password: `Ch@ngeMe`

### 4. Jenkins

Jenkins is a popular CI/CD automation server that can also be used for task scheduling and workflow automation.

**Setup with Docker:**

```bash
# Create jenkins directory
mkdir jenkins-docker && cd jenkins-docker

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  jenkins:
    image: jenkins/jenkins:lts
    ports:
      - "8080:8080"
      - "50000:50000"
    environment:
      - JENKINS_OPTS=--httpPort=8080
    volumes:
      - jenkins-data:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
    user: root

volumes:
  jenkins-data:
EOF

# Start Jenkins
docker-compose up -d
```

**Access Jenkins Web UI:**
- URL: http://localhost:8080
- Get initial admin password: `docker-compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`

**Sample Pipeline Example:**

Create a simple pipeline job with this Jenkinsfile:

```groovy
pipeline {
    agent any
    
    stages {
        stage('Hello') {
            steps {
                echo 'Hello World from Jenkins!'
                sh 'date'
            }
        }
        
        stage('Environment Info') {
            steps {
                sh 'uname -a'
                sh 'docker --version'
            }
        }
    }
    
    triggers {
        cron('H/15 * * * *') // Run every 15 minutes
    }
}
```

### 5. SaltStack

SaltStack is a configuration management and remote execution system that can handle task scheduling and automation.

**Setup with Docker:**

```bash
# Create saltstack directory
mkdir saltstack-docker && cd saltstack-docker

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  salt-master:
    image: saltstack/salt:latest
    ports:
      - "4505:4505"
      - "4506:4506"
      - "8080:8080"
    environment:
      - SALT_USE=master
    volumes:
      - salt-master-data:/etc/salt
      - salt-master-cache:/var/cache/salt
      - salt-master-logs:/var/log/salt
    restart: unless-stopped
    command: salt-master -l debug

  salt-api:
    image: saltstack/salt:latest
    ports:
      - "8000:8000"
    environment:
      - SALT_USE=api
    volumes:
      - salt-master-data:/etc/salt
    depends_on:
      - salt-master
    restart: unless-stopped
    command: salt-api -l debug

volumes:
  salt-master-data:
  salt-master-cache:
  salt-master-logs:
EOF

# Start SaltStack
docker-compose up -d
```

**Access SaltStack:**
- Web UI: http://localhost:3333
- Salt API: http://localhost:8000
- Master logs: `docker-compose logs salt-master`

**Sample Salt State Example:**

Create `/srv/salt/hello.sls`:

```yaml
hello_world:
  cmd.run:
    - name: echo "Hello World from SaltStack!"

scheduled_task:
  schedule.present:
    - function: cmd.run
    - job_args:
      - echo "Scheduled task executed at $(date)"
    - seconds: 300  # Run every 5 minutes
```

## Testing Your Setup

### 1. Verify All Services

```bash
# Check running containers
docker ps

# Check service health
curl -f http://localhost:8080/health  # Airflow
curl -f http://localhost:4200/api/health  # Prefect
curl -k https://localhost/api/v1/actions  # StackStorm
curl -f http://localhost:8081/login  # Jenkins
curl -f http://localhost:3333  # SaltStack UI
curl -f http://localhost:8000  # SaltStack API
```

### 2. Resource Monitoring

```bash
# Monitor container resource usage
docker stats

# Check Docker Desktop resources in the GUI
# Recommended: 4GB+ RAM, 2+ CPUs for all services
```

### 3. Port Summary

| Service | Port | URL |
|---------|------|-----|
| Airflow | 8080 | http://localhost:8080 |
| Prefect | 4200 | http://localhost:4200 |
| StackStorm | 80/443 | https://localhost |
| Jenkins | 8081 | http://localhost:8081 |
| SaltStack UI | 3333 | http://localhost:3333 |
| SaltStack API | 8000 | http://localhost:8000 |

**Note:** Jenkins has been configured to use port 8081 to avoid conflicts with Airflow (port 8080).

## Common Commands

### Docker Management
```bash
# Stop all services
docker-compose down

# View logs
docker-compose logs -f [service-name]

# Restart services
docker-compose restart

# Clean up unused containers/images
docker system prune -a
```

### Service-Specific Commands

**Airflow:**
```bash
# Access Airflow CLI
docker-compose exec airflow-webserver airflow --help

# List DAGs
docker-compose exec airflow-webserver airflow dags list
```

**Prefect:**
```bash
# Set API URL for local client
export PREFECT_API_URL="http://localhost:4200/api"

# List flows
prefect flow ls
```

**StackStorm:**
```bash
# Access StackStorm CLI
docker-compose exec stackstorm st2 --help

# List actions
docker-compose exec stackstorm st2 action list
```

**Jenkins:**
```bash
# Access Jenkins CLI (after setup)
docker-compose exec jenkins java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ help

# View logs
docker-compose logs jenkins
```

**SaltStack:**
```bash
# Access Salt Master CLI
docker-compose exec salt-master salt --help

# List connected minions
docker-compose exec salt-master salt '*' test.ping

# Run commands on minions
docker-compose exec salt-master salt '*' cmd.run 'date'
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```bash
   # Check what's using a port
   lsof -i :8080
   
   # Kill process using port
   kill -9 $(lsof -t -i:8080)
   ```

2. **Memory Issues**
   - Increase Docker Desktop memory allocation (Settings > Resources)
   - Close unnecessary applications
   - Consider running one service at a time for testing

3. **Permission Issues**
   ```bash
   # Fix Airflow permissions
   sudo chown -R $(id -u):$(id -g) ./dags ./logs ./plugins
   ```

4. **Service Won't Start**
   ```bash
   # Check logs for specific service
   docker-compose logs [service-name]
   
   # Restart Docker Desktop
   # Or restart Docker daemon
   sudo systemctl restart docker  # Linux
   ```

## Example Workflows Comparison

To help you understand the differences between these tools, here's the same data processing workflow implemented in each platform:

### Workflow Overview
Our example workflow performs a simple ETL (Extract, Transform, Load) process:
1. **Extract**: Get sample data from a source
2. **Transform**: Add grade calculations based on scores
3. **Validate**: Check data integrity
4. **Load**: Save processed data to destination
5. **Cleanup**: Remove temporary files

### 1. Airflow Workflow

**File**: `task-scheduling-tools/airflow/dags/data_processing_workflow.py`

**Key Features:**
- Python-based DAG definition
- Task dependencies with `>>`
- XCom for data passing between tasks
- Built-in retry and error handling
- Web UI for monitoring and manual triggers

**How to Register:**
```bash
# File is automatically detected in the dags/ folder
# Check in Airflow UI: http://localhost:8080
```

**How to Run:**
1. Open Airflow UI: http://localhost:8080
2. Find "data_processing_workflow" DAG
3. Toggle it ON
4. Click "Trigger DAG" for manual run
5. View execution in Graph or Gantt view

**Scheduling**: Configured to run every hour with `schedule_interval=timedelta(hours=1)`

### 2. Prefect Workflow

**File**: `task-scheduling-tools/prefect/data_processing_flow.py`

**Key Features:**
- Decorator-based task definition
- Automatic data passing between tasks
- Built-in retry mechanisms
- Modern Python async support
- Clean, readable code structure

**How to Register:**
```bash
cd task-scheduling-tools/prefect
# Set Prefect API URL
export PREFECT_API_URL="http://localhost:4200/api"

# Create deployment
python -c "
from data_processing_flow import data_processing_workflow
from prefect.deployments import Deployment
from prefect.server.schemas.schedules import IntervalSchedule
from datetime import timedelta

deployment = Deployment.build_from_flow(
    flow=data_processing_workflow,
    name='data-processing-hourly',
    schedule=IntervalSchedule(interval=timedelta(hours=1))
)
deployment.apply()
"
```

**How to Run:**
1. Register the deployment (see above)
2. Open Prefect UI: http://localhost:4200
3. Go to Deployments → data-processing-hourly
4. Click "Quick Run" for manual execution
5. Monitor in Flow Runs section

**Alternative - Direct Run:**
```bash
python data_processing_flow.py
```

### 3. StackStorm Workflow

**Files**: 
- `task-scheduling-tools/stackstorm/packs/data_processing/`
- Workflow: `workflows/data_processing_workflow.yaml`
- Rule: `rules/scheduled_data_processing.yaml`

**Key Features:**
- YAML-based workflow definition
- Event-driven architecture
- Built-in action library
- Rule-based automation
- REST API integration

**How to Register:**
```bash
# Copy pack to StackStorm container
docker-compose exec stackstorm cp -r /opt/stackstorm/packs/data_processing /opt/stackstorm/packs/

# Register the pack
docker-compose exec stackstorm st2ctl reload --register-all

# Enable the rule
docker-compose exec stackstorm st2 rule enable data_processing.scheduled_data_processing
```

**How to Run:**
1. Manual execution:
```bash
docker-compose exec stackstorm st2 execution run data_processing.data_processing_workflow source="demo" destination="output"
```
2. Automatic: Rule triggers every hour
3. Monitor in StackStorm UI: https://localhost

### 4. Jenkins Workflow

**File**: `task-scheduling-tools/jenkins/jobs/DataProcessingPipeline.groovy`

**Key Features:**
- Groovy-based pipeline script
- Built-in SCM integration
- Extensive plugin ecosystem
- Parameterized builds
- Artifact archiving

**How to Register:**
1. Open Jenkins UI: http://localhost:8081
2. Get admin password: `docker-compose -f jenkins/docker-compose.yml exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
3. Complete setup wizard
4. Create New Item → Pipeline
5. Name: "DataProcessingPipeline"
6. Copy content from `DataProcessingPipeline.groovy` to Pipeline Script
7. Save

**How to Run:**
1. Go to Jenkins dashboard
2. Click "DataProcessingPipeline"
3. Click "Build with Parameters"
4. Set Environment and Batch Size
5. Click "Build"
6. Monitor in Build History

**Scheduling**: Configured with `cron('0 * * * *')` for hourly runs

### 5. SaltStack Workflow

**File**: `task-scheduling-tools/saltstack/salt-config/data_processing.sls`

**Key Features:**
- YAML-based state definition
- Declarative configuration management
- Built-in scheduling
- Remote execution capabilities
- Infrastructure as Code approach

**How to Register:**
```bash
# File is automatically available in /srv/salt
# No explicit registration needed
```

**How to Run:**
1. Manual execution:
```bash
docker-compose exec salt-master salt '*' state.apply data_processing
```
2. Via Web UI: http://localhost:3333
   - Use "Custom Command" section
   - Target: `*`
   - Module: `state.apply`
   - Arguments: `data_processing`
3. Automatic: Scheduled every hour via `schedule.present`

## Tool Comparison Matrix

| Feature | Airflow | Prefect | StackStorm | Jenkins | SaltStack |
|---------|---------|---------|------------|---------|-----------|
| **Language** | Python | Python | YAML/Python | Groovy/Java | YAML/Python |
| **Learning Curve** | Medium | Easy | Medium | Hard | Medium |
| **Web UI Quality** | Excellent | Excellent | Good | Good | Basic |
| **Scheduling** | Cron/Interval | Interval/Cron | Event/Timer | Cron/SCM | Cron/Event |
| **Error Handling** | Built-in | Built-in | Manual | Built-in | Manual |
| **Data Passing** | XCom | Automatic | Manual | Files/Env | Files/Grains |
| **Scalability** | High | High | Medium | High | High |
| **Best For** | Data Pipelines | Modern Workflows | Event Automation | CI/CD | Config Mgmt |

## Running All Workflows

To test all workflows simultaneously:

```bash
# 1. Trigger Airflow DAG
curl -X POST "http://localhost:8080/api/v1/dags/data_processing_workflow/dagRuns" \
  -H "Content-Type: application/json" \
  -u "airflow:airflow" \
  -d '{"dag_run_id": "manual_'$(date +%s)'"}'

# 2. Run Prefect Flow
cd task-scheduling-tools/prefect && python data_processing_flow.py

# 3. Execute StackStorm Workflow
docker-compose -f task-scheduling-tools/stackstorm/docker-compose.yml exec stackstorm \
  st2 execution run data_processing.data_processing_workflow source="demo" destination="output"

# 4. Trigger Jenkins Pipeline (via UI or API)
curl -X POST "http://localhost:8081/job/DataProcessingPipeline/build" \
  --user admin:$(docker-compose -f task-scheduling-tools/jenkins/docker-compose.yml exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)

# 5. Apply SaltStack State
docker-compose -f task-scheduling-tools/saltstack/docker-compose.yml exec salt-master \
  salt '*' state.apply data_processing
```

## Next Steps

1. **Explore Documentation:**
   - [Airflow Documentation](https://airflow.apache.org/docs/)
   - [Prefect Documentation](https://docs.prefect.io/)
   - [StackStorm Documentation](https://docs.stackstorm.com/)
   - [Jenkins Documentation](https://www.jenkins.io/doc/)
   - [SaltStack Documentation](https://docs.saltproject.io/)

2. **Experiment with Workflows:**
   - Modify the example workflows
   - Add error handling and notifications
   - Integrate with external services
   - Test different scheduling patterns

3. **Choose Your Tool:**
   - **Airflow**: Complex data pipelines, batch processing
   - **Prefect**: Modern Python workflows, real-time processing
   - **StackStorm**: Event-driven automation, infrastructure management
   - **Jenkins**: CI/CD pipelines, build automation
   - **SaltStack**: Configuration management, infrastructure automation

## Security Notes

- Change default passwords in production
- Use environment variables for sensitive data
- Consider using Docker secrets for production deployments
- Enable SSL/TLS for production environments

Happy orchestrating! 🚀