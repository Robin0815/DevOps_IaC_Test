#!/bin/bash
# Native Debian CI/CD Pipeline Setup with Podman
# Run the complete CI/CD pipeline directly on Debian using Podman

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

print_header "Native Debian CI/CD Pipeline Setup with Podman"

echo "This script sets up the complete CI/CD pipeline on Debian using Podman."
echo ""
echo "✅ What you get:"
echo "   - Forgejo Git server running locally"
echo "   - Gitea Actions CI/CD runner"
echo "   - ArgoCD for GitOps deployments"
echo "   - Local container registry"
echo "   - Optional monitoring (Prometheus + Grafana)"
echo ""
echo "🐧 System Requirements:"
echo "   - Debian 11+ or Ubuntu 20.04+"
echo "   - 4GB+ RAM (8GB recommended)"
echo "   - 20GB+ free disk space"
echo "   - Internet connection"
echo "   - Sudo privileges"
echo ""
echo "🚀 Advantages of Podman:"
echo "   - Rootless containers (better security)"
echo "   - No daemon required"
echo "   - Docker-compatible commands"
echo "   - Better resource isolation"
echo ""

read -p "Continue with Debian Podman setup? (y/N): " CONTINUE
if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Check if running on Debian/Ubuntu
if ! grep -E "(debian|ubuntu)" /etc/os-release >/dev/null 2>&1; then
    print_error "This script is for Debian/Ubuntu systems only"
    exit 1
fi

# Check system resources
print_header "System Requirements Check"

# Check RAM
TOTAL_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
if [ "$TOTAL_RAM" -lt 4 ]; then
    print_warning "System has ${TOTAL_RAM}GB RAM. 4GB+ recommended for optimal performance."
    read -p "Continue anyway? (y/N): " CONTINUE_LOW_RAM
    if [[ ! "$CONTINUE_LOW_RAM" =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    print_success "System RAM: ${TOTAL_RAM}GB ✓"
fi

# Check disk space
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 20 ]; then
    print_warning "Available disk space: ${AVAILABLE_SPACE}GB. 20GB+ recommended."
    read -p "Continue anyway? (y/N): " CONTINUE_LOW_DISK
    if [[ ! "$CONTINUE_LOW_DISK" =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    print_success "Available disk space: ${AVAILABLE_SPACE}GB ✓"
fi

# Update system
print_header "Updating System"
print_info "Updating package lists..."
sudo apt update

print_info "Upgrading system packages..."
sudo apt upgrade -y

# Install dependencies
print_header "Installing Dependencies"
print_info "Installing required packages..."

required_packages=(
    "podman"
    "podman-compose"
    "git"
    "make"
    "curl"
    "wget"
    "jq"
    "uidmap"
    "slirp4netns"
    "fuse-overlayfs"
)

for package in "${required_packages[@]}"; do
    if dpkg -l | grep -q "^ii  $package "; then
        print_success "$package already installed"
    else
        print_info "Installing $package..."
        sudo apt install -y "$package"
    fi
done

# Configure Podman for rootless operation
print_header "Configuring Podman"

# Enable user namespaces
if ! grep -q "^$USER:" /etc/subuid; then
    print_info "Configuring user namespaces..."
    echo "$USER:100000:65536" | sudo tee -a /etc/subuid
    echo "$USER:100000:65536" | sudo tee -a /etc/subgid
fi

# Configure Podman registries
print_info "Configuring container registries..."
mkdir -p ~/.config/containers

cat > ~/.config/containers/registries.conf << EOF
[registries.search]
registries = ['docker.io', 'quay.io']

[registries.insecure]
registries = ['localhost:5000']

[registries.block]
registries = []
EOF

# Configure Podman storage
cat > ~/.config/containers/storage.conf << EOF
[storage]
driver = "overlay"
runroot = "/run/user/1000/containers"
graphroot = "/home/$USER/.local/share/containers/storage"

[storage.options]
additionalimagestores = []

[storage.options.overlay]
mountopt = "nodev,metacopy=on"
EOF

print_success "Podman configured for rootless operation"

# Create podman-compose alias
print_info "Setting up podman-compose compatibility..."
if ! command -v docker-compose >/dev/null 2>&1; then
    sudo ln -sf /usr/bin/podman-compose /usr/local/bin/docker-compose
    print_success "docker-compose alias created for podman-compose"
fi

# Create docker alias for podman
if ! command -v docker >/dev/null 2>&1; then
    echo 'alias docker="podman"' >> ~/.bashrc
    alias docker="podman"
    print_success "docker alias created for podman"
fi

# Enable and start podman socket
print_info "Enabling Podman socket..."
systemctl --user enable podman.socket
systemctl --user start podman.socket

# Check port availability
print_header "Checking Port Availability"
required_ports=(3000 8080 5000 9090 3001)
ports_in_use=()

for port in "${required_ports[@]}"; do
    if ss -tuln | grep -q ":$port "; then
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
        echo "To find what's using a port: ss -tuln | grep :PORT"
        echo "To kill a process: sudo kill -9 PID"
        exit 0
    fi
fi

# Configure firewall
print_header "Configuring Firewall"
if command -v ufw >/dev/null 2>&1; then
    print_info "Configuring UFW firewall..."
    sudo ufw allow 3000/tcp comment "Forgejo"
    sudo ufw allow 8080/tcp comment "ArgoCD"
    sudo ufw allow 5000/tcp comment "Registry"
    sudo ufw allow 9090/tcp comment "Prometheus"
    sudo ufw allow 3001/tcp comment "Grafana"
    print_success "Firewall configured"
else
    print_warning "UFW not found. Please configure firewall manually if needed."
fi

# Set up project
print_header "Setting Up CI/CD Pipeline"

# Create directories
print_info "Creating project directories..."
mkdir -p data/{forgejo,runner,argocd,registry,prometheus,grafana}
mkdir -p config backups

# Set correct permissions for rootless Podman
chmod 755 data/
chmod -R 755 data/*/

# Copy Prometheus configuration
if [ -f "config/prometheus.yml.example" ]; then
    cp config/prometheus.yml.example config/prometheus.yml
    print_success "Prometheus configuration ready"
fi

# Create Podman-specific docker-compose override
print_info "Creating Podman-specific configuration..."
cat > docker-compose.podman.yml << EOF
version: '3.8'

# Podman-specific overrides
services:
  forgejo:
    volumes:
      - /run/user/$(id -u)/podman/podman.sock:/var/run/docker.sock
    user: "$(id -u):$(id -g)"
    
  runner:
    volumes:
      - /run/user/$(id -u)/podman/podman.sock:/var/run/docker.sock
    user: "$(id -u):$(id -g)"
    environment:
      - DOCKER_HOST=unix:///var/run/docker.sock
EOF

# Pull container images
print_info "Pulling container images (this may take a few minutes)..."
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
    podman pull "$image"
done

print_success "All container images pulled"

# Update Makefile for Podman
print_info "Configuring Makefile for Podman..."
if [ -f "Makefile" ]; then
    # Create Podman-specific Makefile
    sed 's/docker-compose/podman-compose/g' Makefile > Makefile.podman
    cp Makefile.podman Makefile
    print_success "Makefile configured for Podman"
fi

# Start the services
print_header "Starting CI/CD Pipeline"
print_info "Starting services with Podman Compose..."

# Use podman-compose with override file
export COMPOSE_FILE="docker-compose.yml:docker-compose.podman.yml"

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
SHELL_PROFILE="$HOME/.bashrc"
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

# Podman aliases
alias docker='podman'
alias docker-compose='podman-compose'
EOF
    print_success "Aliases added to $SHELL_PROFILE"
    echo "Reload your shell or run: source $SHELL_PROFILE"
else
    print_success "Aliases already exist in $SHELL_PROFILE"
fi

# Create service information file
print_info "Creating service information file..."
cat > "$HOME/CI_CD_Services_Debian.txt" << EOF
CI/CD Pipeline Services - Native Debian with Podman
===================================================

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

Podman Commands:
- List containers: podman ps
- View logs:       podman logs <container>
- Execute shell:   podman exec -it <container> /bin/bash

Next Steps:
1. Configure Forgejo: http://localhost:3000
2. Get ArgoCD password: make argocd-password
3. Follow Quick Start Guide: docs/quick-start-guide.md

Documentation: $(pwd)/docs/
EOF

print_success "Service information saved to ~/CI_CD_Services_Debian.txt"

# Enable systemd user services (optional)
print_info "Enabling user services..."
sudo loginctl enable-linger "$USER"
print_success "User services enabled (containers will start on boot)"

# Final success message
print_header "🎉 Native Debian Setup with Podman Complete!"
echo ""
echo "Your CI/CD pipeline is running natively on Debian with Podman!"
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
echo "🐧 Podman advantages:"
echo "   - Rootless containers (better security)"
echo "   - No daemon required"
echo "   - Docker-compatible commands"
echo "   - Better resource isolation"
echo ""
echo "📋 Next steps:"
echo "   1. Configure Forgejo (create admin account)"
echo "   2. Get ArgoCD password: make argocd-password"
echo "   3. Follow the Quick Start Guide: docs/quick-start-guide.md"
echo ""
echo "📚 Documentation: $(pwd)/docs/"
echo "💾 Service info saved to: ~/CI_CD_Services_Debian.txt"
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

print_success "Setup complete! Your native Debian CI/CD pipeline with Podman is ready to use."
echo ""
echo "🔄 To reload shell aliases: source ~/.bashrc"