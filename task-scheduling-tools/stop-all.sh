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

echo -e "${CYAN}🛑 Stopping Task Scheduling Tools Suite${NC}"
echo "========================================"

# Function to stop service with error handling
stop_service() {
    local service_name=$1
    local service_dir=$2
    local service_emoji=$3
    local cleanup_volumes=$4
    
    print_header "${service_emoji} Stopping ${service_name}..."
    
    if [ ! -d "$service_dir" ]; then
        print_warning "Directory $service_dir not found, skipping $service_name"
        return
    fi
    
    cd "$service_dir"
    
    # Stop and remove containers
    if docker-compose down; then
        print_status "$service_name stopped successfully"
    else
        print_error "Failed to stop $service_name"
    fi
    
    # Clean up volumes if requested
    if [ "$cleanup_volumes" = "true" ]; then
        print_info "Cleaning up volumes for $service_name..."
        docker-compose down -v 2>/dev/null || true
    fi
    
    cd ..
}

# Parse command line arguments
CLEANUP_VOLUMES=false
FORCE_CLEANUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --cleanup-volumes|-v)
            CLEANUP_VOLUMES=true
            shift
            ;;
        --force|-f)
            FORCE_CLEANUP=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --cleanup-volumes, -v    Remove Docker volumes (data will be lost)"
            echo "  --force, -f              Force cleanup including orphaned containers"
            echo "  --help, -h               Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [ "$CLEANUP_VOLUMES" = "true" ]; then
    print_warning "Volume cleanup requested - this will remove all data!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Volume cleanup cancelled"
        CLEANUP_VOLUMES=false
    fi
fi

# Stop services in reverse order
stop_service "DolphinScheduler" "dolphinscheduler" "🐬" "$CLEANUP_VOLUMES"
stop_service "SaltStack" "saltstack" "🧂" "$CLEANUP_VOLUMES"
stop_service "Jenkins" "jenkins" "🏗️" "$CLEANUP_VOLUMES"
stop_service "StackStorm (Workflow Engine)" "stackstorm" "⚡" "$CLEANUP_VOLUMES"
stop_service "Prefect" "prefect" "🔮" "$CLEANUP_VOLUMES"
stop_service "Apache Airflow" "airflow" "🌪️" "$CLEANUP_VOLUMES"

# Force cleanup if requested
if [ "$FORCE_CLEANUP" = "true" ]; then
    print_info "Performing force cleanup..."
    
    # Stop any remaining containers
    print_info "Stopping any remaining containers..."
    docker stop $(docker ps -q) 2>/dev/null || true
    
    # Remove orphaned containers
    print_info "Removing orphaned containers..."
    docker container prune -f 2>/dev/null || true
    
    # Clean up networks
    print_info "Cleaning up networks..."
    docker network prune -f 2>/dev/null || true
    
    if [ "$CLEANUP_VOLUMES" = "true" ]; then
        print_info "Removing unused volumes..."
        docker volume prune -f 2>/dev/null || true
    fi
    
    print_status "Force cleanup completed"
fi

echo ""
print_header "📊 Cleanup Summary:"
echo "==================="

# Show remaining containers
REMAINING_CONTAINERS=$(docker ps -q | wc -l)
if [ "$REMAINING_CONTAINERS" -gt 0 ]; then
    print_warning "$REMAINING_CONTAINERS containers still running"
    echo "Run 'docker ps' to see them"
else
    print_status "No containers running"
fi

# Show disk usage
print_info "Docker disk usage:"
docker system df 2>/dev/null || true

echo ""
print_header "🔧 Additional Cleanup Options:"
echo "==============================="
echo -e "${CYAN}• Remove all volumes:${NC}     ./stop-all.sh --cleanup-volumes"
echo -e "${CYAN}• Force cleanup:${NC}          ./stop-all.sh --force"
echo -e "${CYAN}• Full system cleanup:${NC}    docker system prune -a --volumes"
echo -e "${CYAN}• View disk usage:${NC}        docker system df"
echo ""

print_status "Task Scheduling Tools Suite stopped!"

if [ "$CLEANUP_VOLUMES" = "true" ]; then
    print_warning "Volumes were removed - data has been deleted"
    print_info "Next startup will initialize fresh databases"
else
    print_info "Data volumes preserved - next startup will restore previous state"
fi