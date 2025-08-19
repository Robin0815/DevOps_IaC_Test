#!/bin/bash
# Quick setup script for CI/CD Pipeline on Debian VM
# This script helps you set up Ansible and run the playbook

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running on macOS or Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
else
    print_error "Unsupported platform: $OSTYPE"
    exit 1
fi

print_header "CI/CD Pipeline VM Setup Script"

echo "This script will:"
echo "1. Install Ansible on your local machine"
echo "2. Help you configure the inventory"
echo "3. Run the playbook to set up your Debian VM"
echo ""

# Check if Ansible is installed
if command -v ansible >/dev/null 2>&1; then
    print_success "Ansible is already installed ($(ansible --version | head -n1))"
else
    print_warning "Ansible not found. Installing..."
    
    if [[ "$PLATFORM" == "macos" ]]; then
        if command -v brew >/dev/null 2>&1; then
            brew install ansible
        else
            print_error "Homebrew not found. Please install Homebrew first:"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    elif [[ "$PLATFORM" == "linux" ]]; then
        if command -v apt >/dev/null 2>&1; then
            sudo apt update
            sudo apt install -y ansible
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y epel-release
            sudo yum install -y ansible
        else
            print_error "Package manager not supported. Please install Ansible manually."
            exit 1
        fi
    fi
    
    print_success "Ansible installed successfully"
fi

# Change to ansible directory
cd ansible

# Check if inventory is configured
if grep -q "your-vm-ip-here" inventory.ini; then
    print_warning "Inventory not configured yet"
    echo ""
    echo "Please configure your VM details:"
    read -p "Enter your VM IP address: " VM_IP
    read -p "Enter SSH username (default: debian): " SSH_USER
    SSH_USER=${SSH_USER:-debian}
    
    # Update inventory
    sed -i.bak "s/your-vm-ip-here/$VM_IP/" inventory.ini
    sed -i.bak "s/ansible_user=debian/ansible_user=$SSH_USER/" inventory.ini
    
    print_success "Inventory configured with IP: $VM_IP, User: $SSH_USER"
else
    print_success "Inventory already configured"
fi

# Test connection
print_header "Testing Connection to VM"
echo "Testing SSH connection to your VM..."

if ansible all -m ping; then
    print_success "Connection successful!"
else
    print_error "Connection failed!"
    echo ""
    echo "Troubleshooting tips:"
    echo "1. Ensure SSH key is set up: ssh-copy-id $SSH_USER@$VM_IP"
    echo "2. Test manual SSH: ssh $SSH_USER@$VM_IP"
    echo "3. Check VM is running and accessible"
    echo "4. Verify firewall allows SSH (port 22)"
    echo ""
    read -p "Do you want to continue anyway? (y/N): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Run the playbook
print_header "Running CI/CD Pipeline Setup"
echo "This will take 5-10 minutes depending on your internet connection..."
echo ""

if ansible-playbook playbook.yml; then
    print_success "Setup completed successfully!"
    
    # Get VM IP for display
    VM_IP=$(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' inventory.ini | head -n1)
    
    echo ""
    print_header "Setup Complete!"
    echo ""
    echo "🎉 Your CI/CD pipeline is ready!"
    echo ""
    echo "📊 Access your services:"
    echo "   Forgejo:  http://$VM_IP:3000"
    echo "   ArgoCD:   http://$VM_IP:8080"
    echo "   Registry: http://$VM_IP:5000"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. SSH to your VM: ssh $SSH_USER@$VM_IP"
    echo "   2. Start the pipeline: cd local-cicd-pipeline && make start"
    echo "   3. Wait 2-3 minutes for services to start"
    echo "   4. Configure Forgejo and ArgoCD"
    echo "   5. Follow the Quick Start Guide"
    echo ""
    echo "📚 Documentation: ~/local-cicd-pipeline/docs/"
    echo ""
else
    print_error "Setup failed!"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check the error messages above"
    echo "2. Ensure VM has internet access"
    echo "3. Verify VM has enough resources (4GB+ RAM)"
    echo "4. Run with verbose output: ansible-playbook playbook.yml -v"
    exit 1
fi