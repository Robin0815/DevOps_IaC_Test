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

print_header "🔮 Starting Prefect"
echo "==================="

# Check if Docker is running
print_info "Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop first."
    exit 1
fi
print_status "Docker is running"

# Check if already running
if docker-compose ps | grep -q "Up"; then
    print_warning "Prefect containers are already running"
    docker-compose ps
    exit 0
fi

# Start Prefect
print_info "Starting Prefect containers..."
if docker-compose up -d; then
    print_status "Prefect started successfully!"
else
    print_error "Failed to start Prefect"
    exit 1
fi

# Wait for services to be ready
print_info "Waiting for Prefect to be ready..."
sleep 15

# Check if server is responding
for i in {1..30}; do
    if curl -s http://localhost:4200/api/health > /dev/null 2>&1; then
        print_status "Prefect server is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        print_warning "Prefect server may not be fully ready yet"
    fi
    sleep 2
done

echo ""
print_header "📊 Prefect Access Information"
echo "============================="
echo -e "${CYAN}• Web UI:${NC}        http://localhost:4200"
echo -e "${CYAN}• API:${NC}           http://localhost:4200/api"
echo ""
print_header "🔧 Useful Commands"
echo "=================="
echo -e "${CYAN}• View logs:${NC}     docker-compose logs -f"
echo -e "${CYAN}• Stop service:${NC}  docker-compose down"
echo -e "${CYAN}• Restart:${NC}       docker-compose restart"
echo -e "${CYAN}• Status:${NC}        docker-compose ps"
echo ""
print_header "🚀 Test Workflows & UI Features"
echo "==============================="
echo -e "${CYAN}• Flow dependencies:${NC}  python demo_flow_dependencies.py"
echo -e "${CYAN}• UI showcase:${NC}        docker-compose exec prefect-server python /opt/prefect/flows/ui_showcase_flow.py"
echo -e "${CYAN}• Advanced flows:${NC}     docker-compose exec prefect-server python /opt/prefect/flows/orchestrator_flow.py"
echo ""
print_header "🎨 New UI Features (v3.4.14)"
echo "============================"
echo -e "${CYAN}• Visual flow graphs${NC}  with real-time updates"
echo -e "${CYAN}• Interactive nodes${NC}   click for details & logs"
echo -e "${CYAN}• Parameter forms${NC}     auto-generated UI inputs"
echo -e "${CYAN}• Subflow hierarchy${NC}   nested workflow visualization"
echo -e "${CYAN}• Mobile responsive${NC}   works on tablets & phones"
echo ""