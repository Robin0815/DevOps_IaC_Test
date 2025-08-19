#!/bin/bash
# UTM VM Setup Launcher for CI/CD Pipeline
# Choose between manual or automated setup

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

print_header "CI/CD Pipeline UTM VM Setup"

echo "Choose your setup method:"
echo ""
echo "1. 🚀 NATIVE macOS (Fastest & Best Performance)"
echo "   - Runs directly on your Mac (no VM)"
echo "   - Uses Docker Desktop"
echo "   - Best performance and integration"
echo "   - Total time: ~10 minutes"
echo "   - Recommended for development"
echo ""
echo "2. 🎯 FULLY AUTOMATED VM"
echo "   - Creates UTM VM automatically"
echo "   - Installs Debian unattended"
echo "   - Sets up CI/CD pipeline"
echo "   - Total time: ~30 minutes"
echo "   - Good for isolation"
echo ""
echo "3. 📋 SEMI-AUTOMATED VM"
echo "   - Creates VM with guided setup"
echo "   - You install Debian manually"
echo "   - Automates CI/CD pipeline setup"
echo "   - Total time: ~45 minutes"
echo "   - More control over installation"
echo ""
echo "4. 🛠️  EXISTING VM SETUP"
echo "   - Use any existing VM (UTM, VMware, VirtualBox, etc.)"
echo "   - Works with cloud VMs, physical servers"
echo "   - Just run Ansible playbook"
echo "   - Perfect for existing UTM installations"
echo ""

read -p "Enter your choice (1/2/3/4): " CHOICE

case $CHOICE in
    1)
        print_info "Starting native macOS setup..."
        if [ ! -f "setup-macos-native.sh" ]; then
            print_error "Native macOS setup script not found!"
            exit 1
        fi
        chmod +x setup-macos-native.sh
        ./setup-macos-native.sh
        ;;
    2)
        print_info "Starting fully automated VM setup..."
        if [ ! -f "create-utm-vm-auto.sh" ]; then
            print_error "Automated setup script not found!"
            exit 1
        fi
        chmod +x create-utm-vm-auto.sh
        ./create-utm-vm-auto.sh
        ;;
    3)
        print_info "Starting semi-automated VM setup..."
        if [ ! -f "create-utm-vm.sh" ]; then
            print_error "Semi-automated setup script not found!"
            exit 1
        fi
        chmod +x create-utm-vm.sh
        ./create-utm-vm.sh
        ;;
    4)
        print_info "Existing VM setup selected..."
        echo ""
        echo "✅ Perfect! This works with ANY existing VM:"
        echo "   - UTM VMs you already have"
        echo "   - VMware, VirtualBox, Parallels VMs"
        echo "   - Cloud VMs (AWS, GCP, Azure)"
        echo "   - Physical servers"
        echo ""
        echo "� Quicdk setup steps:"
        echo "1. Ensure your VM is running Debian/Ubuntu"
        echo "2. Test SSH access: ssh user@vm-ip"
        echo "3. Edit ansible/inventory.ini with your VM details"
        echo "4. Run: cd ansible && ansible-playbook playbook.yml"
        echo ""
        echo "📚 Detailed guide: docs/existing-vm-setup.md"
        echo "📋 Prerequisites: docs/prerequisites.md"
        
        # Offer to help with inventory setup
        echo ""
        read -p "Would you like help configuring the inventory? (y/N): " HELP_INVENTORY
        if [[ "$HELP_INVENTORY" =~ ^[Yy]$ ]]; then
            echo ""
            read -p "Enter your VM IP address: " VM_IP
            read -p "Enter SSH username: " SSH_USER
            read -p "SSH key path (press Enter for default ~/.ssh/id_rsa): " SSH_KEY
            SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}
            
            # Update inventory
            cd ansible
            cp inventory.ini inventory.ini.backup
            cat > inventory.ini << EOF
# Ansible Inventory for Existing VM
[cicd-servers]
$VM_IP ansible_user=$SSH_USER ansible_ssh_private_key_file=$SSH_KEY

[cicd-servers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
EOF
            
            print_success "Inventory configured!"
            echo ""
            echo "🧪 Test connection:"
            echo "   cd ansible && ansible all -m ping"
            echo ""
            echo "🚀 Run setup:"
            echo "   cd ansible && ansible-playbook playbook.yml"
        fi
        ;;
    *)
        print_error "Invalid choice. Please run the script again."
        exit 1
        ;;
esac