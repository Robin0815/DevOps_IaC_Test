#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC}  $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

echo -e "${CYAN}🚀 Setting up workflows for Task Scheduling Tools Suite${NC}"
echo "======================================================="

# Check if services are running
print_info "Checking if services are running..."

if ! docker ps | grep -q "prefect-server"; then
    print_error "Services are not running. Please start services first with ./start-all.sh"
    exit 1
fi

print_status "Services are running"

echo ""
print_header "📋 Workflow Setup Status:"
echo "=========================="

# 1. Airflow - DAGs are automatically detected
print_header "🌪️ Apache Airflow"
if [ -d "airflow/dags" ]; then
    print_status "DAGs automatically detected from dags/ folder"
    echo "   - data_processing_workflow.py"
    echo "   - hello_world.py"
else
    print_warning "Airflow dags directory not found"
fi

# 2. Prefect - Create deployments with dependencies
print_header "🔮 Prefect"
print_info "Setting up Prefect deployments with flow dependencies..."

cd prefect
export PREFECT_API_URL="http://localhost:4200/api"

# Create multiple deployments
docker-compose exec prefect-server python -c "
import sys
sys.path.append('/opt/prefect/flows')

try:
    from prefect.deployments import Deployment
    from prefect.server.schemas.schedules import IntervalSchedule, CronSchedule
    from datetime import timedelta
    
    # Import flows
    from data_processing_flow import data_processing_workflow
    from upstream_flow import upstream_flow
    from downstream_flow import downstream_flow
    from orchestrator_flow import orchestrator_flow
    
    deployments_created = []
    
    # Create upstream deployment
    upstream_deployment = Deployment.build_from_flow(
        flow=upstream_flow,
        name='upstream-data-preparation',
        schedule=IntervalSchedule(interval=timedelta(hours=2)),
        tags=['upstream', 'data-prep', 'etl']
    )
    upstream_deployment.apply()
    deployments_created.append('upstream-data-preparation')
    
    # Create main data processing deployment
    data_deployment = Deployment.build_from_flow(
        flow=data_processing_workflow,
        name='data-processing-hourly',
        schedule=IntervalSchedule(interval=timedelta(hours=1)),
        tags=['etl', 'data-processing', 'core']
    )
    data_deployment.apply()
    deployments_created.append('data-processing-hourly')
    
    # Create downstream deployment (no schedule - triggered by upstream)
    downstream_deployment = Deployment.build_from_flow(
        flow=downstream_flow,
        name='downstream-processing',
        schedule=None,
        tags=['downstream', 'dependent', 'processing']
    )
    downstream_deployment.apply()
    deployments_created.append('downstream-processing')
    
    # Create orchestrator deployment (daily)
    orchestrator_deployment = Deployment.build_from_flow(
        flow=orchestrator_flow,
        name='daily-orchestration',
        schedule=CronSchedule(cron='0 2 * * *'),
        tags=['orchestrator', 'daily', 'coordination']
    )
    orchestrator_deployment.apply()
    deployments_created.append('daily-orchestration')
    
    print(f'✅ Created {len(deployments_created)} Prefect deployments:')
    for deployment in deployments_created:
        print(f'   - {deployment}')
        
except Exception as e:
    print(f'⚠️ Prefect setup error: {str(e)}')
" 2>/dev/null

if [ $? -eq 0 ]; then
    print_status "Prefect deployments created with flow dependencies"
else
    print_warning "Prefect deployment creation had issues"
fi

cd ..

# 3. StackStorm - Workflow Engine
print_header "⚡ StackStorm Workflow Engine"
if [ -d "stackstorm/workflows" ]; then
    print_status "Workflow engine ready with conditional workflows"
    echo "   - primary_data_processing.yml"
    echo "   - dependent_cleanup.yml"
    echo "   - conditional_workflow_chain.yml"
    echo "   - system_health_check.yml"
    echo "   - data_backup.yml"
    echo "   - api_health_check.yml"
else
    print_warning "StackStorm workflows directory not found"
fi

# 4. Jenkins - Pipeline setup
print_header "🏗️ Jenkins"
if [ -d "jenkins/jobs" ]; then
    print_status "Pipeline script ready"
    echo "   - DataProcessingPipeline.groovy"
    print_info "Manual setup required:"
    echo "   1. Open http://localhost:8081"
    echo "   2. Create new Pipeline job"
    echo "   3. Copy content from jenkins/jobs/DataProcessingPipeline.groovy"
else
    print_warning "Jenkins jobs directory not found"
fi

# 5. SaltStack - Configuration management
print_header "🧂 SaltStack"
if [ -d "saltstack" ]; then
    print_status "State files ready"
    echo "   - Configuration management states available"
else
    print_warning "SaltStack directory not found"
fi

echo ""
print_header "🎉 Workflow Setup Completed!"
echo "============================="

echo ""
print_header "📊 Access Your Tools:"
echo "======================"
echo -e "${CYAN}• Airflow:${NC}           http://localhost:8080"
echo -e "  ${YELLOW}Credentials:${NC}       airflow / airflow"
echo ""
echo -e "${CYAN}• Prefect:${NC}           http://localhost:4200"
echo -e "  ${YELLOW}Features:${NC}          Flow dependencies, orchestration, monitoring"
echo ""
echo -e "${CYAN}• StackStorm Engine:${NC} http://localhost:8090"
echo -e "  ${YELLOW}Features:${NC}          Conditional workflows, automation engine"
echo ""
echo -e "${CYAN}• Jenkins:${NC}           http://localhost:8081"
echo -e "  ${YELLOW}Admin Password:${NC}    Run: docker-compose -f jenkins/docker-compose.yml exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
echo -e "${CYAN}• SaltStack:${NC}         http://localhost:3333"
echo ""

print_header "🔧 Quick Test Commands:"
echo "========================"

echo -e "${CYAN}# Test Prefect Flow Dependencies:${NC}"
echo "docker-compose -f prefect/docker-compose.yml exec prefect-server python /opt/prefect/flows/orchestrator_flow.py"
echo ""

echo -e "${CYAN}# Test StackStorm Conditional Workflows:${NC}"
echo "cd stackstorm && ./demo_conditional_workflows.sh"
echo ""

echo -e "${CYAN}# Test Airflow DAG:${NC}"
echo "curl -X POST 'http://localhost:8080/api/v1/dags/data_processing_workflow/dagRuns' \\"
echo "  -H 'Content-Type: application/json' -u 'airflow:airflow' \\"
echo "  -d '{\"dag_run_id\": \"manual_test\"}'"
echo ""

echo -e "${CYAN}# Test SaltStack State:${NC}"
echo "docker-compose -f saltstack/docker-compose.yml exec salt-master salt '*' state.apply data_processing"
echo ""

print_header "📋 Advanced Features:"
echo "======================"
echo -e "${CYAN}• Flow Dependencies:${NC}     Prefect flows can trigger and wait for each other"
echo -e "${CYAN}• Conditional Workflows:${NC} StackStorm workflows with prerequisites"
echo -e "${CYAN}• State Monitoring:${NC}      Real-time workflow execution tracking"
echo -e "${CYAN}• Error Handling:${NC}        Retries, timeouts, and failure recovery"
echo -e "${CYAN}• Orchestration:${NC}         Multi-flow coordination and management"

echo ""
print_status "All workflows are ready for testing!"
print_info "Check individual service documentation for detailed usage instructions."