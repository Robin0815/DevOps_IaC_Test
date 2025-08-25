#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
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

echo -e "${CYAN}🚀 Starting Task Scheduling Tools Suite${NC}"
echo "========================================"

# Check if Docker is running
print_info "Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop first."
    exit 1
fi
print_status "Docker is running"

# Function to start service with error handling
start_service() {
    local service_name=$1
    local service_dir=$2
    local service_emoji=$3
    local init_command=$4
    
    print_header "${service_emoji} Starting ${service_name}..."
    
    if [ ! -d "$service_dir" ]; then
        print_warning "Directory $service_dir not found, skipping $service_name"
        return
    fi
    
    cd "$service_dir"
    
    # Run initialization command if provided
    if [ ! -z "$init_command" ]; then
        print_info "Initializing $service_name..."
        eval "$init_command"
    fi
    
    # Start the service
    if docker-compose up -d; then
        print_status "$service_name started successfully"
    else
        print_error "Failed to start $service_name"
    fi
    
    cd ..
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1
    
    print_info "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            print_status "$service_name is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_warning "$service_name may not be fully ready yet"
    return 1
}

# Start services in order
start_service "Apache Airflow" "airflow" "🌪️" "docker-compose up airflow-init"
start_service "Prefect" "prefect" "🔮" ""
start_service "StackStorm (Workflow Engine)" "stackstorm" "⚡" ""
start_service "Jenkins" "jenkins" "🏗️" ""
start_service "SaltStack" "saltstack" "🧂" ""
start_service "DolphinScheduler" "dolphinscheduler" "🐬" ""

echo ""
print_header "🎉 All services started!"
echo ""

# Wait for key services to be ready
print_info "Checking service readiness..."
wait_for_service "Prefect" "http://localhost:4200"
wait_for_service "StackStorm Workflow Engine" "http://localhost:8090"
wait_for_service "DolphinScheduler" "http://localhost:12346"

echo ""
print_header "📊 Access Your Tools:"
echo "=============================="
echo -e "${CYAN}• Airflow:${NC}           http://localhost:8080"
echo -e "  ${YELLOW}Credentials:${NC}       airflow / airflow"
echo ""
echo -e "${CYAN}• Prefect:${NC}           http://localhost:4200"
echo -e "  ${YELLOW}Features:${NC}          Flow orchestration, dependencies, monitoring"
echo ""
echo -e "${CYAN}• StackStorm Engine:${NC} http://localhost:8090"
echo -e "  ${YELLOW}Features:${NC}          Workflow automation, conditional execution"
echo ""
echo -e "${CYAN}• Jenkins:${NC}           http://localhost:8081"
echo -e "  ${YELLOW}Admin Password:${NC}    Run: docker-compose -f jenkins/docker-compose.yml exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
echo -e "${CYAN}• SaltStack:${NC}         http://localhost:3333 (Web UI) | http://localhost:8000 (API)"
echo -e "${CYAN}• DolphinScheduler:${NC}  http://localhost:12346 (admin/dolphinscheduler123)"
echo ""

print_header "🔧 Quick Actions:"
echo "=================="
echo -e "${CYAN}• Check status:${NC}      docker ps"
echo -e "${CYAN}• View logs:${NC}         docker-compose -f <service>/docker-compose.yml logs -f"
echo -e "${CYAN}• Stop all:${NC}          ./stop-all.sh"
echo -e "${CYAN}• Setup workflows:${NC}   ./setup-workflows.sh"
echo ""

print_header "📋 Demo Commands:"
echo "=================="
echo -e "${CYAN}• Test Prefect dependencies:${NC}"
echo "  docker-compose -f prefect/docker-compose.yml exec prefect-server python /opt/prefect/flows/orchestrator_flow.py"
echo ""
echo -e "${CYAN}• Test StackStorm workflows:${NC}"
echo "  cd stackstorm && ./demo_conditional_workflows.sh"
echo ""
echo -e "${CYAN}• Trigger Jenkins pipeline:${NC}"
echo "  Visit Jenkins UI and run 'DataProcessingPipeline'"
echo ""

print_status "Task Scheduling Tools Suite is ready!"
print_info "Check the documentation in each service directory for detailed usage instructions."