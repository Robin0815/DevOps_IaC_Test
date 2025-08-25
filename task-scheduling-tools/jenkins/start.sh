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

print_header "🏗️  Starting Jenkins"
echo "===================="

# Check if Docker is running
print_info "Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop first."
    exit 1
fi
print_status "Docker is running"

# Check if already running
if docker-compose ps | grep -q "Up"; then
    print_warning "Jenkins containers are already running"
    docker-compose ps
    exit 0
fi

# Start Jenkins
print_info "Starting Jenkins containers..."
if docker-compose up -d; then
    print_status "Jenkins started successfully!"
else
    print_error "Failed to start Jenkins"
    exit 1
fi

# Wait for services to be ready
print_info "Waiting for Jenkins to be ready..."
sleep 30

# Check if server is responding
for i in {1..60}; do
    if curl -s http://localhost:8081/login > /dev/null 2>&1; then
        print_status "Jenkins server is ready!"
        break
    fi
    if [ $i -eq 60 ]; then
        print_warning "Jenkins may not be fully ready yet"
    fi
    sleep 2
done

echo ""
print_header "📊 Jenkins Access Information"
echo "============================="
echo -e "${CYAN}• Web UI:${NC}        http://localhost:8081"
echo ""
print_header "🔑 Initial Setup"
echo "================"
echo -e "${CYAN}• Get admin password:${NC}"
echo "  docker-compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
print_header "🔧 Useful Commands"
echo "=================="
echo -e "${CYAN}• View logs:${NC}     docker-compose logs -f"
echo -e "${CYAN}• Stop service:${NC}  docker-compose down"
echo -e "${CYAN}• Restart:${NC}       docker-compose restart"
echo -e "${CYAN}• Status:${NC}        docker-compose ps"
echo ""