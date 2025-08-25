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

print_header "🐬 Setting up DolphinScheduler"
echo "==============================="

# Wait for API server to be fully ready
print_info "Waiting for DolphinScheduler API to be fully initialized..."
sleep 30

# Check if API is accessible
API_READY=false
for i in {1..60}; do
    if curl -s http://localhost:12345/dolphinscheduler/users/get-user-info > /dev/null 2>&1; then
        API_READY=true
        break
    fi
    sleep 5
done

if [ "$API_READY" = false ]; then
    print_error "API server is not ready. Please check the logs."
    exit 1
fi

print_status "API server is ready!"

# Create a default tenant (required for DolphinScheduler)
print_info "Creating default tenant..."
TENANT_RESPONSE=$(curl -s -X POST "http://localhost:12345/dolphinscheduler/tenants" \
  -H "Content-Type: application/json" \
  -d '{
    "tenantCode": "default",
    "description": "Default tenant for workflows",
    "queueId": 1
  }' 2>/dev/null || echo "")

if [[ $TENANT_RESPONSE == *"success"* ]] || [[ $TENANT_RESPONSE == *"already exists"* ]]; then
    print_status "Default tenant created/exists"
else
    print_warning "Tenant creation may have failed, but this is often normal on first setup"
fi

# Create a default project
print_info "Creating default project..."
PROJECT_RESPONSE=$(curl -s -X POST "http://localhost:12345/dolphinscheduler/projects" \
  -H "Content-Type: application/json" \
  -d '{
    "projectName": "demo_project",
    "description": "Demo project for example workflows"
  }' 2>/dev/null || echo "")

if [[ $PROJECT_RESPONSE == *"success"* ]] || [[ $PROJECT_RESPONSE == *"already exists"* ]]; then
    print_status "Default project created/exists"
else
    print_warning "Project creation may have failed, but you can create it manually in the UI"
fi

print_status "DolphinScheduler setup completed!"
echo ""
print_header "🚀 Next Steps"
echo "=============="
echo -e "${CYAN}1.${NC} Access the UI at http://localhost:12346"
echo -e "${CYAN}2.${NC} Login with admin/dolphinscheduler123"
echo -e "${CYAN}3.${NC} Create or select a project"
echo -e "${CYAN}4.${NC} Start creating workflows with the visual editor"
echo -e "${CYAN}5.${NC} Import example workflows from the flows/ directory"
echo ""