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
print_header() { echo -e "${PURPLE}$1${NC}"; }

print_header "🧪 Testing DolphinScheduler"
echo "============================"

# Test 1: Check container status
print_info "Test 1: Checking container status..."
if docker-compose ps | grep -q "Up.*healthy"; then
    print_status "Container is running and healthy"
else
    print_error "Container is not running or not healthy"
    exit 1
fi

# Test 2: Check API health
print_info "Test 2: Checking API health..."
if curl -s http://localhost:12345/dolphinscheduler/actuator/health | grep -q '"status":"UP"'; then
    print_status "API is responding and healthy"
else
    print_error "API is not responding properly"
    exit 1
fi

# Test 3: Check UI accessibility
print_info "Test 3: Checking UI accessibility..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:12345/dolphinscheduler/ui | grep -q "200"; then
    print_status "UI is accessible"
else
    print_error "UI is not accessible"
    exit 1
fi

echo ""
print_header "🎉 All Tests Passed!"
echo "===================="
echo -e "${CYAN}• Container:${NC}      ✅ Running and healthy"
echo -e "${CYAN}• API Health:${NC}     ✅ Responding"
echo -e "${CYAN}• UI Access:${NC}      ✅ Available"
echo ""
print_header "🚀 Ready to Use!"
echo "================="
echo -e "${CYAN}• Web UI:${NC}         http://localhost:12345/dolphinscheduler/ui"
echo -e "${CYAN}• Login:${NC}          admin / dolphinscheduler123"
echo -e "${CYAN}• API Docs:${NC}       http://localhost:12345/dolphinscheduler/doc.html"
echo ""