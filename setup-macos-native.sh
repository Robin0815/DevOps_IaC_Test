#!/bin/bash
# Native macOS CI/CD Pipeline Setup
# Run the complete CI/CD pipeline directly on your Mac

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }

print_header "Native macOS CI/CD Pipeline Setup"

echo "This script sets up the complete CI/CD pipeline directly on your Mac."
echo ""
echo "✅ What you get:"
echo "   - Forgejo Git server running locally"
echo "   - Gitea Actions CI/CD runner"
echo "   - ArgoCD for GitOps deployments"
echo "   - Local container registry"
echo "   - Optional monitoring (Prometheus + Grafana)"
echo ""
echo "🖥️  System Requirements:"
echo "   - macOS 10.15+ (Catalina or newer)"
echo "   - 8GB+ RAM (16GB recommended)"
echo "   - 20GB+ free disk space"
echo "   - Internet connection"
echo ""
echo "⚡ Advantages of native setup:"
echo "   - Better performance (no VM overhead)"
echo "   - Direct access to host resources"
echo "   - Easier integration with local development"
echo "   - Faster startup times"
echo ""

read -p "Continue with native macOS setup? (y/N): " CONTINUE
if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is for macOS only"
    exit 1
fi

# Check system resources
print_header "System Requirements Check"

# Check RAM
TOTAL_RAM=$(sysctl -n hw.memsize)
TOTAL_RAM_GB=$((TOTAL_RAM / 1024 / 1024 / 1024))

if [ $TOTAL_RAM_GB -lt 8 ]; then
    print_warning "System has ${TOTAL_RAM_GB}GB RAM. 8GB+ recommended for optimal performance."
    read -p "Continue anyway? (y/N): " CONTINUE_LOW_RAM
    if [[ ! "$CONTINUE_LOW_RAM" =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    print_success "System RAM: ${TOTAL_RAM_GB}GB ✓"
fi

# Check disk space
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G.*//')
if [ "$AVAILABLE_SPACE" -lt 20 ]; then
    print_warning "Available disk space: ${AVAILABLE_SPACE}GB. 20GB+ recommended."
    read -p "Continue anyway? (y/N): " CONTINUE_LOW_DISK
    if [[ ! "$CONTINUE_LOW_DISK" =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    print_success "Available disk space: ${AVAILABLE_SPACE}GB ✓"
fi

# Install dependencies
print_header "Installing Dependencies"

# Check and install Homebrew
if ! command -v brew >/dev/null 2>&1; then
    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    print_success "Homebrew already installed"
fi

# Install required tools
print_info "Installing required tools..."
brew_packages=(
    "docker"
    "docker-compose" 
    "git"
    "make"
    "curl"
    "jq"
)

for package in "${brew_packages[@]}"; do
    if brew list "$package" &>/dev/null; then
        print_success "$package already installed"
    else
        print_info "Installing $package..."
        brew install "$package"
    fi
done

# Install Docker Desktop if not present
if [ ! -d "/Applications/Docker.app" ]; then
    print_info "Installing Docker Desktop..."
    brew install --cask docker
    print_warning "Docker Desktop installed. Please start it manually and complete setup."
    echo "1. Open Docker Desktop from Applications"
    echo "2. Complete the initial setup"
    echo "3. Ensure Docker is running (whale icon in menu bar)"
    echo "4. Run this script again"
    exit 0
fi

# Check if Docker is running
print_info "Checking Docker status..."
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop first."
    echo "1. Open Docker Desktop from Applications"
    echo "2. Wait for it to start (whale icon in menu bar should be steady)"
    echo "3. Run this script again"
    exit 1
fi

print_success "Docker is running"

# Check port availability
print_header "Checking Port Availability"
required_ports=(3000 8080 5000 9090 3001)
ports_in_use=()

for port in "${required_ports[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null; then
        ports_in_use+=($port)
        print_warning "Port $port is in use"
    else
        print_success "Port $port is available"
    fi
done

if [ ${#ports_in_use[@]} -gt 0 ]; then
    echo ""
    echo "The following ports are in use: ${ports_in_use[*]}"
    echo "You can:"
    echo "1. Stop services using these ports"
    echo "2. Continue anyway (may cause conflicts)"
    echo "3. Exit and free the ports manually"
    echo ""
    read -p "Continue anyway? (y/N): " CONTINUE_PORTS
    if [[ ! "$CONTINUE_PORTS" =~ ^[Yy]$ ]]; then
        echo ""
        echo "To find what's using a port: lsof -i :PORT"
        echo "To kill a process: kill -9 PID"
        exit 0
    fi
fi

# Configure Docker for insecure registry
print_header "Configuring Docker"
DOCKER_CONFIG_FILE="$HOME/.docker/daemon.json"
mkdir -p "$HOME/.docker"

if [ -f "$DOCKER_CONFIG_FILE" ]; then
    # Backup existing config
    cp "$DOCKER_CONFIG_FILE" "$DOCKER_CONFIG_FILE.backup"
    print_info "Backed up existing Docker configuration"
fi

# Create or update Docker daemon configuration
cat > "$DOCKER_CONFIG_FILE" << EOF
{
  "insecure-registries": ["localhost:5000"],
  "experimental": false
}
EOF

print_success "Docker configured for local registry"
print_warning "Docker Desktop needs to restart to apply configuration changes"

# Ask user to restart Docker
echo ""
echo "Please restart Docker Desktop:"
echo "1. Click the Docker whale icon in the menu bar"
echo "2. Select 'Restart Docker Desktop'"
echo "3. Wait for Docker to restart completely"
echo ""
read -p "Press Enter after Docker has restarted..."

# Verify Docker is running again
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running after restart. Please start Docker Desktop."
    exit 1
fi

print_success "Docker restarted successfully"

# Set up project
print_header "Setting Up CI/CD Pipeline"

# Create directories
print_info "Creating project directories..."
mkdir -p data/{forgejo,runner,argocd,registry,prometheus,grafana}
mkdir -p config backups

# Copy Prometheus configuration
if [ -f "config/prometheus.yml.example" ]; then
    cp config/prometheus.yml.example config/prometheus.yml
    print_success "Prometheus configuration ready"
fi

# Pull Docker images
print_info "Pulling Docker images (this may take a few minutes)..."
images=(
    "codeberg.org/forgejo/forgejo:1.21"
    "gitea/act_runner:latest"
    "quay.io/argoproj/argocd:v2.9.3"
    "registry:2"
    "prom/prometheus:latest"
    "grafana/grafana:latest"
)

for image in "${images[@]}"; do
    print_info "Pulling $image..."
    docker pull "$image"
done

print_success "All Docker images pulled"

# Start the services
print_header "Starting CI/CD Pipeline"
print_info "Starting services with Docker Compose..."

if make start; then
    print_success "Services started successfully!"
else
    print_error "Failed to start services. Check the logs above."
    exit 1
fi

# Wait for services to be ready
print_info "Waiting for services to be ready (this may take 2-3 minutes)..."
sleep 30

# Check service status
print_header "Service Status Check"
services_ready=true

# Check Forgejo
if curl -s http://localhost:3000 >/dev/null; then
    print_success "Forgejo is ready at http://localhost:3000"
else
    print_warning "Forgejo not ready yet (may need more time)"
    services_ready=false
fi

# Check ArgoCD
if curl -s http://localhost:8080 >/dev/null; then
    print_success "ArgoCD is ready at http://localhost:8080"
else
    print_warning "ArgoCD not ready yet (may need more time)"
    services_ready=false
fi

# Check Registry
if curl -s http://localhost:5000/v2/ >/dev/null; then
    print_success "Registry is ready at http://localhost:5000"
else
    print_warning "Registry not ready yet (may need more time)"
    services_ready=false
fi

if [ "$services_ready" = false ]; then
    echo ""
    print_info "Some services are still starting up. This is normal."
    echo "Run 'make status' in a few minutes to check again."
fi

# Create helpful aliases
print_header "Setting Up Convenience Features"

# Add aliases to shell profile
SHELL_PROFILE=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_PROFILE="$HOME/.bash_profile"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
fi

if [ -n "$SHELL_PROFILE" ]; then
    print_info "Adding convenience aliases to $SHELL_PROFILE..."
    
    # Check if aliases already exist
    if ! grep -q "# CI/CD Pipeline aliases" "$SHELL_PROFILE"; then
        cat >> "$SHELL_PROFILE" << EOF

# CI/CD Pipeline aliases
alias cicd-start='cd $(pwd) && make start'
alias cicd-stop='cd $(pwd) && make stop'
alias cicd-status='cd $(pwd) && make status'
alias cicd-logs='cd $(pwd) && make logs'
alias cicd-clean='cd $(pwd) && make clean'
alias cicd-backup='cd $(pwd) && make backup'
EOF
        print_success "Aliases added to $SHELL_PROFILE"
        echo "Reload your shell or run: source $SHELL_PROFILE"
    else
        print_success "Aliases already exist in $SHELL_PROFILE"
    fi
fi

# Create desktop shortcuts
print_info "Creating desktop shortcuts..."
cat > "$HOME/Desktop/CI_CD_Services.txt" << EOF
CI/CD Pipeline Services - Native macOS
=====================================

Service URLs:
- Forgejo (Git):     http://localhost:3000
- ArgoCD (CD):       http://localhost:8080
- Registry:          http://localhost:5000
- Prometheus:        http://localhost:9090 (if monitoring enabled)
- Grafana:           http://localhost:3001 (if monitoring enabled)

Project Location: $(pwd)

Quick Commands:
- Start:    make start    (or cicd-start)
- Stop:     make stop     (or cicd-stop)
- Status:   make status   (or cicd-status)
- Logs:     make logs     (or cicd-logs)
- Backup:   make backup   (or cicd-backup)

Next Steps:
1. Configure Forgejo: http://localhost:3000
2. Get ArgoCD password: make argocd-password
3. Follow Quick Start Guide: docs/quick-start-guide.md

Documentation: $(pwd)/docs/
EOF

print_success "Service information saved to Desktop"

# Final success message
print_header "🎉 Native macOS Setup Complete!"
echo ""
echo "Your CI/CD pipeline is running natively on macOS!"
echo ""
echo "📊 Access your services:"
echo "   Forgejo:  http://localhost:3000"
echo "   ArgoCD:   http://localhost:8080"
echo "   Registry: http://localhost:5000"
echo ""
echo "🚀 Quick commands:"
echo "   make start    # Start all services"
echo "   make stop     # Stop all services"
echo "   make status   # Check service status"
echo "   make logs     # View service logs"
echo ""
echo "📋 Next steps:"
echo "   1. Configure Forgejo (create admin account)"
echo "   2. Get ArgoCD password: make argocd-password"
echo "   3. Follow the Quick Start Guide: docs/quick-start-guide.md"
echo ""
echo "📚 Documentation: $(pwd)/docs/"
echo "💾 Service info saved to Desktop: CI_CD_Services.txt"
echo ""
echo "🎯 Pro tip: Services will start automatically with 'make start'"
echo "   No VM needed - everything runs natively on your Mac!"
echo ""

# Optional monitoring setup
echo ""
read -p "Would you like to enable monitoring (Prometheus + Grafana)? (y/N): " ENABLE_MONITORING
if [[ "$ENABLE_MONITORING" =~ ^[Yy]$ ]]; then
    print_info "Starting monitoring stack..."
    make start-monitoring
    echo ""
    print_success "Monitoring enabled!"
    echo "   Prometheus: http://localhost:9090"
    echo "   Grafana:    http://localhost:3001 (admin/admin)"
fi

print_success "Setup complete! Your native macOS CI/CD pipeline is ready to use."