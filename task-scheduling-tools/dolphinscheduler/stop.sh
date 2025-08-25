#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}✅${NC} $1"; }
print_error() { echo -e "${RED}❌${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ️${NC}  $1"; }
print_warning() { echo -e "${YELLOW}⚠️${NC}  $1"; }
print_header() { echo -e "${PURPLE}$1${NC}"; }

print_header "🛑 Stopping Apache DolphinScheduler"
echo "===================================="

# Check if containers are running
if ! docker-compose ps | grep -q "Up"; then
    print_warning "No DolphinScheduler containers are currently running"
    exit 0
fi

# Parse command line arguments
CLEANUP_VOLUMES=false
FORCE=false

for arg in "$@"; do
    case $arg in
        --cleanup-volumes|-v)
            CLEANUP_VOLUMES=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        *)
            ;;
    esac
done

# Stop containers
print_info "Stopping DolphinScheduler containers..."
if docker-compose down; then
    print_status "DolphinScheduler containers stopped"
else
    print_error "Failed to stop some containers"
fi

# Cleanup volumes if requested
if [ "$CLEANUP_VOLUMES" = true ]; then
    print_info "Cleaning up volumes..."
    if [ "$FORCE" = true ]; then
        docker-compose down -v --remove-orphans
        print_status "Volumes cleaned up"
    else
        echo -e "${YELLOW}⚠️  This will remove all DolphinScheduler data including:${NC}"
        echo "   • Workflow definitions and history"
        echo "   • Database data (projects, users, tasks)"
        echo "   • Log files and configurations"
        echo "   • Resource files and UDFs"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose down -v --remove-orphans
            print_status "Volumes cleaned up"
        else
            print_info "Volume cleanup cancelled"
        fi
    fi
fi

echo ""
print_header "🔧 Additional Options"
echo "===================="
echo -e "${CYAN}• Clean volumes:${NC}      ./stop.sh --cleanup-volumes"
echo -e "${CYAN}• Force cleanup:${NC}      ./stop.sh --force"
echo -e "${CYAN}• Start again:${NC}        ./start.sh"
echo ""