#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC}  $1"
}

echo -e "${CYAN}📊 Task Scheduling Tools Status${NC}"
echo "================================="

# Function to check service status
check_service() {
    local service_name=$1
    local service_dir=$2
    local port=$3
    local endpoint=$4
    
    echo ""
    print_header "🔍 $service_name"
    echo "------------------------"
    
    if [ ! -d "$service_dir" ]; then
        print_error "Directory $service_dir not found"
        return
    fi
    
    cd "$service_dir"
    
    # Check if containers are running
    local running_containers=$(docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l)
    local total_containers=$(docker-compose ps --services 2>/dev/null | wc -l)
    
    if [ "$running_containers" -gt 0 ]; then
        print_status "$running_containers/$total_containers containers running"
        
        # Check if service is responding
        if [ ! -z "$port" ] && [ ! -z "$endpoint" ]; then
            if curl -s "http://localhost:$port$endpoint" > /dev/null 2>&1; then
                print_status "Service responding on port $port"
            else
                print_error "Service not responding on port $port"
            fi
        fi
        
        # Show container details
        echo "Containers:"
        docker-compose ps --format "table {{.Name}}\t{{.State}}\t{{.Ports}}" 2>/dev/null | tail -n +2 | sed 's/^/  /'
        
    else
        print_error "No containers running"
    fi
    
    cd ..
}

# Check each service
check_service "Apache Airflow" "airflow" "8080" "/health"
check_service "Prefect" "prefect" "4200" "/api/health"
check_service "StackStorm (Workflow Engine)" "stackstorm" "8090" "/api/workflows"
check_service "Jenkins" "jenkins" "8081" "/login"
check_service "SaltStack" "saltstack" "3333" "/"
check_service "DolphinScheduler" "dolphinscheduler" "12345" "/dolphinscheduler/actuator/health"

echo ""
print_header "🌐 Service URLs"
echo "==============="
echo -e "${CYAN}• Airflow:${NC}           http://localhost:8080"
echo -e "${CYAN}• Prefect:${NC}           http://localhost:4200"
echo -e "${CYAN}• StackStorm Engine:${NC} http://localhost:8090"
echo -e "${CYAN}• Jenkins:${NC}           http://localhost:8081"
echo -e "${CYAN}• SaltStack:${NC}         http://localhost:3333"
echo -e "${CYAN}• DolphinScheduler:${NC}  http://localhost:12345/dolphinscheduler/ui"

echo ""
print_header "💾 Docker Resources"
echo "==================="
docker system df 2>/dev/null || print_error "Failed to get Docker disk usage"

echo ""
print_header "🔧 Management Commands"
echo "======================"
echo -e "${CYAN}• Start all services:${NC}    ./start-all.sh"
echo -e "${CYAN}• Stop all services:${NC}     ./stop-all.sh"
echo -e "${CYAN}• View service logs:${NC}     docker-compose -f <service>/docker-compose.yml logs -f"
echo -e "${CYAN}• Restart service:${NC}       cd <service> && docker-compose restart"
echo -e "${CYAN}• Update status:${NC}         ./status.sh"