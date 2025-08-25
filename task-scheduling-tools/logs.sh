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

print_info() {
    echo -e "${BLUE}ℹ️${NC}  $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Function to show usage
show_usage() {
    echo -e "${CYAN}📋 Task Scheduling Tools - Log Viewer${NC}"
    echo "======================================"
    echo ""
    echo "Usage: $0 [SERVICE] [OPTIONS]"
    echo ""
    echo "Services:"
    echo "  airflow     - Apache Airflow logs"
    echo "  prefect     - Prefect server logs"
    echo "  stackstorm  - StackStorm workflow engine logs"
    echo "  jenkins     - Jenkins CI/CD logs"
    echo "  saltstack   - SaltStack configuration management logs"
    echo "  all         - Show logs from all services"
    echo ""
    echo "Options:"
    echo "  -f, --follow    Follow log output (like tail -f)"
    echo "  -n, --lines N   Show last N lines (default: 50)"
    echo "  --since TIME    Show logs since timestamp (e.g., '2h', '30m')"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 prefect -f                    # Follow Prefect logs"
    echo "  $0 airflow --lines 100           # Show last 100 lines of Airflow logs"
    echo "  $0 stackstorm --since 1h         # Show StackStorm logs from last hour"
    echo "  $0 all -n 20                     # Show last 20 lines from all services"
}

# Parse arguments
SERVICE=""
FOLLOW=false
LINES=50
SINCE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        airflow|prefect|stackstorm|jenkins|saltstack|all)
            SERVICE=$1
            shift
            ;;
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n|--lines)
            LINES=$2
            shift 2
            ;;
        --since)
            SINCE=$2
            shift 2
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

# Function to show logs for a service
show_service_logs() {
    local service_name=$1
    local service_dir=$2
    
    if [ ! -d "$service_dir" ]; then
        print_error "Directory $service_dir not found"
        return
    fi
    
    print_header "📋 $service_name Logs"
    echo "========================"
    
    cd "$service_dir"
    
    # Build docker-compose logs command
    local cmd="docker-compose logs"
    
    if [ "$FOLLOW" = true ]; then
        cmd="$cmd -f"
    fi
    
    if [ ! -z "$LINES" ]; then
        cmd="$cmd --tail $LINES"
    fi
    
    if [ ! -z "$SINCE" ]; then
        cmd="$cmd --since $SINCE"
    fi
    
    print_info "Running: $cmd"
    echo ""
    
    # Execute the command
    eval "$cmd"
    
    cd ..
}

# Show logs based on service selection
case $SERVICE in
    airflow)
        show_service_logs "Apache Airflow" "airflow"
        ;;
    prefect)
        show_service_logs "Prefect" "prefect"
        ;;
    stackstorm)
        show_service_logs "StackStorm Workflow Engine" "stackstorm"
        ;;
    jenkins)
        show_service_logs "Jenkins" "jenkins"
        ;;
    saltstack)
        show_service_logs "SaltStack" "saltstack"
        ;;
    all)
        print_header "📋 All Services Logs"
        echo "====================="
        
        services=("airflow:Apache Airflow" "prefect:Prefect" "stackstorm:StackStorm" "jenkins:Jenkins" "saltstack:SaltStack")
        
        for service_info in "${services[@]}"; do
            IFS=':' read -r service_dir service_name <<< "$service_info"
            
            if [ -d "$service_dir" ]; then
                echo ""
                print_info "=== $service_name ==="
                cd "$service_dir"
                docker-compose logs --tail "$LINES" 2>/dev/null | head -20
                cd ..
            fi
        done
        
        if [ "$FOLLOW" = true ]; then
            print_info "Following logs from all services (press Ctrl+C to stop)..."
            echo ""
            
            # Follow logs from all services simultaneously
            for service_info in "${services[@]}"; do
                IFS=':' read -r service_dir service_name <<< "$service_info"
                
                if [ -d "$service_dir" ]; then
                    (
                        cd "$service_dir"
                        docker-compose logs -f 2>/dev/null | sed "s/^/[$service_name] /"
                    ) &
                fi
            done
            
            # Wait for all background processes
            wait
        fi
        ;;
esac