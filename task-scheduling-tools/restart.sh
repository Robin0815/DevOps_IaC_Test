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

print_warning() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

# Function to show usage
show_usage() {
    echo -e "${CYAN}🔄 Task Scheduling Tools - Service Restart${NC}"
    echo "==========================================="
    echo ""
    echo "Usage: $0 [SERVICE] [OPTIONS]"
    echo ""
    echo "Services:"
    echo "  airflow     - Restart Apache Airflow"
    echo "  prefect     - Restart Prefect server"
    echo "  stackstorm  - Restart StackStorm workflow engine"
    echo "  jenkins     - Restart Jenkins CI/CD"
    echo "  saltstack   - Restart SaltStack configuration management"
    echo "  all         - Restart all services"
    echo ""
    echo "Options:"
    echo "  --rebuild   - Rebuild containers before restarting"
    echo "  --force     - Force restart (stop and start instead of restart)"
    echo "  -h, --help  - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 prefect                       # Restart Prefect service"
    echo "  $0 stackstorm --rebuild          # Rebuild and restart StackStorm"
    echo "  $0 all --force                   # Force restart all services"
}

# Parse arguments
SERVICE=""
REBUILD=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        airflow|prefect|stackstorm|jenkins|saltstack|all)
            SERVICE=$1
            shift
            ;;
        --rebuild)
            REBUILD=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

if [ -z "$SERVICE" ]; then
    show_usage
    exit 1
fi

# Function to restart a service
restart_service() {
    local service_name=$1
    local service_dir=$2
    local service_emoji=$3
    
    print_header "${service_emoji} Restarting ${service_name}..."
    
    if [ ! -d "$service_dir" ]; then
        print_error "Directory $service_dir not found"
        return 1
    fi
    
    cd "$service_dir"
    
    if [ "$REBUILD" = true ]; then
        print_info "Rebuilding containers..."
        if docker-compose build; then
            print_status "Build completed"
        else
            print_error "Build failed"
            cd ..
            return 1
        fi
    fi
    
    if [ "$FORCE" = true ]; then
        print_info "Force restarting (stop and start)..."
        docker-compose down
        if docker-compose up -d; then
            print_status "$service_name restarted successfully"
        else
            print_error "Failed to restart $service_name"
            cd ..
            return 1
        fi
    else
        print_info "Restarting containers..."
        if docker-compose restart; then
            print_status "$service_name restarted successfully"
        else
            print_error "Failed to restart $service_name"
            cd ..
            return 1
        fi
    fi
    
    cd ..
    return 0
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local url=$2
    local max_attempts=15
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

echo -e "${CYAN}🔄 Restarting Task Scheduling Tools${NC}"
echo "===================================="

# Restart services based on selection
case $SERVICE in
    airflow)
        restart_service "Apache Airflow" "airflow" "🌪️"
        wait_for_service "Airflow" "http://localhost:8080/health"
        ;;
    prefect)
        restart_service "Prefect" "prefect" "🔮"
        wait_for_service "Prefect" "http://localhost:4200"
        ;;
    stackstorm)
        restart_service "StackStorm Workflow Engine" "stackstorm" "⚡"
        wait_for_service "StackStorm" "http://localhost:8090/api/workflows"
        ;;
    jenkins)
        restart_service "Jenkins" "jenkins" "🏗️"
        wait_for_service "Jenkins" "http://localhost:8081/login"
        ;;
    saltstack)
        restart_service "SaltStack" "saltstack" "🧂"
        wait_for_service "SaltStack" "http://localhost:3333"
        ;;
    all)
        print_info "Restarting all services..."
        
        services=("airflow:Apache Airflow:🌪️" "prefect:Prefect:🔮" "stackstorm:StackStorm Workflow Engine:⚡" "jenkins:Jenkins:🏗️" "saltstack:SaltStack:🧂")
        failed_services=()
        
        for service_info in "${services[@]}"; do
            IFS=':' read -r service_dir service_name service_emoji <<< "$service_info"
            
            if ! restart_service "$service_name" "$service_dir" "$service_emoji"; then
                failed_services+=("$service_name")
            fi
        done
        
        if [ ${#failed_services[@]} -eq 0 ]; then
            print_status "All services restarted successfully!"
        else
            print_error "Failed to restart: ${failed_services[*]}"
        fi
        
        # Wait for key services
        print_info "Checking service readiness..."
        wait_for_service "Prefect" "http://localhost:4200"
        wait_for_service "StackStorm" "http://localhost:8090/api/workflows"
        ;;
esac

echo ""
print_header "📊 Service Status"
echo "=================="
print_info "Run './status.sh' for detailed status information"
print_info "Run './logs.sh $SERVICE -f' to follow logs"

echo ""
print_status "Restart operation completed!"