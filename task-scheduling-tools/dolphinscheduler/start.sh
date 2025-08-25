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

print_header "🐬 Starting Apache DolphinScheduler"
echo "===================================="

# Check if Docker is running
print_info "Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop first."
    exit 1
fi
print_status "Docker is running"

# Check if already running
if docker-compose ps | grep -q "Up"; then
    print_warning "DolphinScheduler containers are already running"
    docker-compose ps
    exit 0
fi

# Start DolphinScheduler
print_info "Starting DolphinScheduler containers..."
print_info "This may take a few minutes on first startup..."
if docker-compose up -d; then
    print_status "DolphinScheduler started successfully!"
else
    print_error "Failed to start DolphinScheduler"
    exit 1
fi

# Wait for standalone server to be ready
print_info "Waiting for DolphinScheduler standalone server to initialize..."
print_info "This includes API, Master, Worker, Alert, and UI services in one container..."
sleep 30

# Check if API server is responding
print_info "Checking API server readiness..."
for i in {1..60}; do
    if curl -s http://localhost:12345/dolphinscheduler/actuator/health > /dev/null 2>&1; then
        print_status "DolphinScheduler API server is ready!"
        break
    fi
    if [ $i -eq 60 ]; then
        print_warning "API server may still be initializing. Check logs if needed."
    fi
    sleep 5
done

# Check if UI is responding
print_info "Checking UI server readiness..."
for i in {1..30}; do
    if curl -s http://localhost:12345/dolphinscheduler/ui > /dev/null 2>&1; then
        print_status "DolphinScheduler UI is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        print_warning "UI may still be starting. Check logs if needed."
    fi
    sleep 2
done

echo ""
print_header "📊 DolphinScheduler Access Information"
echo "======================================"
echo -e "${CYAN}• Web UI:${NC}        http://localhost:12345/dolphinscheduler/ui"
echo -e "${CYAN}• API Server:${NC}    http://localhost:12345/dolphinscheduler"
echo -e "${CYAN}• Username:${NC}      admin"
echo -e "${CYAN}• Password:${NC}      dolphinscheduler123"
echo ""
print_header "🔧 Useful Commands"
echo "=================="
echo -e "${CYAN}• View logs:${NC}     docker-compose logs -f"
echo -e "${CYAN}• Stop service:${NC}  docker-compose down"
echo -e "${CYAN}• Restart:${NC}       docker-compose restart"
echo -e "${CYAN}• Status:${NC}        docker-compose ps"
echo ""
print_header "🐬 DolphinScheduler Features"
echo "============================"
echo -e "${CYAN}• Visual DAG Editor${NC}  - Drag & drop workflow builder"
echo -e "${CYAN}• Multi-tenancy${NC}      - Project and user management"
echo -e "${CYAN}• Task Dependencies${NC}  - Complex workflow orchestration"
echo -e "${CYAN}• Resource Center${NC}    - File and UDF management"
echo -e "${CYAN}• Alert Management${NC}   - Email and webhook notifications"
echo ""
print_header "🚀 Getting Started"
echo "=================="
echo -e "${CYAN}1.${NC} Access the UI at http://localhost:12345/dolphinscheduler/ui"
echo -e "${CYAN}2.${NC} Login with admin/dolphinscheduler123"
echo -e "${CYAN}3.${NC} Create a new project"
echo -e "${CYAN}4.${NC} Import example workflows from ./flows/ directory"
echo -e "${CYAN}5.${NC} Use the visual DAG editor to create workflows"
echo ""