#!/bin/bash
# Quick setup for existing UTM VMs
# This script helps you use the CI/CD pipeline with VMs you already have

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
print_header() { echo -e "${BLUE}========================================\n$1\n========================================${NC}"; }

print_header "CI/CD Pipeline Setup for Existing UTM VMs"

echo "This script helps you set up the CI/CD pipeline on UTM VMs you already have."
echo ""
echo "✅ Works with:"
echo "   - Any existing UTM VM"
echo "   - Debian, Ubuntu, or other Debian-based VMs"
echo "   - VMs created with different settings"
echo "   - Both Intel and Apple Silicon VMs"
echo ""

# Check if UTM is installed
if [ ! -d "/Applications/UTM.app" ]; then
    echo "⚠️  UTM not found. This script is for existing UTM users."
    echo "   If you need to install UTM, use: ./setup-utm.sh"
    exit 1
fi

print_success "UTM installation found"

# List UTM VMs
echo ""
echo "📋 Your UTM VMs:"
UTM_VMS_DIR="$HOME/UTM VMs"
if [ -d "$UTM_VMS_DIR" ]; then
    ls -1 "$UTM_VMS_DIR" | grep -E '\.utm$' | sed 's/\.utm$//' | nl
else
    echo "   No UTM VMs directory found at: $UTM_VMS_DIR"
    echo "   Please ensure you have UTM VMs created."
    exit 1
fi

echo ""
echo "🔧 Setup Requirements:"
echo "   - VM must be running Debian/Ubuntu"
echo "   - SSH access to the VM"
echo "   - VM has internet access"
echo "   - At least 4GB RAM, 20GB storage"
echo ""

read -p "Do you have a suitable VM ready? (y/N): " VM_READY
if [[ ! "$VM_READY" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Please prepare your VM first:"
    echo "1. Start your UTM VM"
    echo "2. Ensure it's running Debian/Ubuntu"
    echo "3. Set up SSH access (install openssh-server if needed)"
    echo "4. Note the VM's IP address"
    echo "5. Run this script again"
    exit 0
fi

# Get VM details
echo ""
print_info "VM Configuration"
read -p "Enter your VM's IP address: " VM_IP
read -p "Enter SSH username: " SSH_USER
echo ""
echo "SSH Key Options:"
echo "1. Use existing SSH key"
echo "2. Use password authentication"
echo "3. Generate new SSH key"
read -p "Choose option (1/2/3): " SSH_OPTION

case $SSH_OPTION in
    1)
        read -p "Enter path to SSH private key (default: ~/.ssh/id_rsa): " SSH_KEY
        SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}
        if [ ! -f "$SSH_KEY" ]; then
            echo "❌ SSH key not found: $SSH_KEY"
            exit 1
        fi
        SSH_CONFIG="ansible_ssh_private_key_file=$SSH_KEY"
        ;;
    2)
        read -s -p "Enter SSH password: " SSH_PASS
        echo ""
        SSH_CONFIG="ansible_ssh_pass=$SSH_PASS"
        ;;
    3)
        SSH_KEY="$HOME/.ssh/utm_cicd_key"
        print_info "Generating new SSH key: $SSH_KEY"
        ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "utm-cicd-access"
        
        print_info "Copying SSH key to VM..."
        ssh-copy-id -i "$SSH_KEY.pub" "$SSH_USER@$VM_IP"
        SSH_CONFIG="ansible_ssh_private_key_file=$SSH_KEY"
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

# Test SSH connection
print_info "Testing SSH connection..."
if [ "$SSH_OPTION" = "2" ]; then
    # Test with password
    if sshpass -p "$SSH_PASS" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "echo 'Connection successful'"; then
        print_success "SSH connection working"
    else
        echo "❌ SSH connection failed. Please check your credentials and VM status."
        exit 1
    fi
else
    # Test with key
    if ssh -i "$SSH_KEY" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "echo 'Connection successful'"; then
        print_success "SSH connection working"
    else
        echo "❌ SSH connection failed. Please check your SSH key and VM status."
        exit 1
    fi
fi

# Install Ansible if needed
if ! command -v ansible >/dev/null 2>&1; then
    print_info "Installing Ansible..."
    if command -v brew >/dev/null 2>&1; then
        brew install ansible
    else
        echo "❌ Homebrew not found. Please install Ansible manually:"
        echo "   brew install ansible"
        exit 1
    fi
fi

print_success "Ansible ready"

# Configure inventory
print_info "Configuring Ansible inventory..."
cd ansible
cp inventory.ini inventory.ini.backup 2>/dev/null || true

cat > inventory.ini << EOF
# Ansible Inventory for Existing UTM VM
[cicd-servers]
$VM_IP ansible_user=$SSH_USER $SSH_CONFIG

[cicd-servers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
EOF

print_success "Inventory configured"

# Test Ansible connection
print_info "Testing Ansible connection..."
if ansible all -m ping; then
    print_success "Ansible connection successful"
else
    echo "❌ Ansible connection failed"
    exit 1
fi

# Run the playbook
print_header "Installing CI/CD Pipeline"
echo "This will take 5-10 minutes..."
echo ""

if ansible-playbook playbook.yml; then
    print_success "Installation completed successfully!"
    
    echo ""
    print_header "🎉 Setup Complete!"
    echo ""
    echo "Your CI/CD pipeline is ready on your existing UTM VM!"
    echo ""
    echo "📊 Access your services:"
    echo "   Forgejo:  http://$VM_IP:3000"
    echo "   ArgoCD:   http://$VM_IP:8080"
    echo "   Registry: http://$VM_IP:5000"
    echo ""
    echo "🔑 SSH Access:"
    if [ "$SSH_OPTION" = "2" ]; then
        echo "   ssh $SSH_USER@$VM_IP"
    else
        echo "   ssh -i $SSH_KEY $SSH_USER@$VM_IP"
    fi
    echo ""
    echo "🚀 Start the pipeline:"
    echo "   SSH to your VM and run:"
    echo "   cd local-cicd-pipeline"
    echo "   make start"
    echo ""
    echo "📚 Documentation: ~/local-cicd-pipeline/docs/"
    
    # Save connection info
    cat > "$HOME/Desktop/UTM_CI_CD_Info.txt" << EOL
UTM VM CI/CD Pipeline Information
================================

VM IP: $VM_IP
SSH User: $SSH_USER
$([ "$SSH_OPTION" != "2" ] && echo "SSH Key: $SSH_KEY")

Service URLs:
- Forgejo: http://$VM_IP:3000
- ArgoCD: http://$VM_IP:8080
- Registry: http://$VM_IP:5000

Connect to VM:
$([ "$SSH_OPTION" = "2" ] && echo "ssh $SSH_USER@$VM_IP" || echo "ssh -i $SSH_KEY $SSH_USER@$VM_IP")

Start Pipeline:
cd local-cicd-pipeline
make start

Quick Commands:
cicd-start   # Start all services
cicd-stop    # Stop all services
cicd-status  # Check service status
EOL
    
    print_success "Connection info saved to Desktop: UTM_CI_CD_Info.txt"
    
else
    echo "❌ Installation failed. Check the output above for errors."
    echo ""
    echo "💡 Troubleshooting tips:"
    echo "   - Ensure VM has internet access"
    echo "   - Check VM has enough resources (4GB+ RAM)"
    echo "   - Verify SSH access works manually"
    echo "   - See docs/troubleshooting.md for more help"
    exit 1
fi