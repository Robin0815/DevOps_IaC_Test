#!/bin/bash
# UTM VM Creation and CI/CD Pipeline Setup Script for macOS
# This script creates a Debian VM in UTM and sets up the complete CI/CD pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Configuration
VM_NAME="cicd-pipeline-vm"
VM_MEMORY="8192"  # 8GB RAM
VM_DISK_SIZE="40"  # 40GB disk
VM_CPUS="4"
DEBIAN_ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.2.0-amd64-netinst.iso"
DEBIAN_ISO_NAME="debian-12.2.0-amd64-netinst.iso"
UTM_VMS_DIR="$HOME/UTM VMs"
VM_DIR="$UTM_VMS_DIR/$VM_NAME.utm"
SSH_KEY_PATH="$HOME/.ssh/cicd_vm_key"

print_header "UTM VM Creation and CI/CD Pipeline Setup"

echo "This script will:"
echo "1. Check and install UTM if needed"
echo "2. Download Debian ISO if not present"
echo "3. Create a new UTM VM with optimal settings"
echo "4. Guide you through Debian installation"
echo "5. Set up SSH access to the VM"
echo "6. Run Ansible to install the CI/CD pipeline"
echo ""
echo "VM Configuration:"
echo "  Name: $VM_NAME"
echo "  RAM: ${VM_MEMORY}MB (8GB)"
echo "  Disk: ${VM_DISK_SIZE}GB"
echo "  CPUs: $VM_CPUS"
echo ""

read -p "Continue? (y/N): " CONTINUE
if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

# Check if UTM is installed
print_header "Checking UTM Installation"
if [ -d "/Applications/UTM.app" ]; then
    print_success "UTM is installed"
else
    print_warning "UTM not found. Installing via Homebrew..."
    if command -v brew >/dev/null 2>&1; then
        brew install --cask utm
        print_success "UTM installed successfully"
    else
        print_error "Homebrew not found. Please install UTM manually from https://mac.getutm.app/"
        echo "Or install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
fi

# Create UTM VMs directory if it doesn't exist
mkdir -p "$UTM_VMS_DIR"

# Check if VM already exists
if [ -d "$VM_DIR" ]; then
    print_warning "VM '$VM_NAME' already exists"
    read -p "Delete existing VM and create new one? (y/N): " DELETE_VM
    if [[ "$DELETE_VM" =~ ^[Yy]$ ]]; then
        rm -rf "$VM_DIR"
        print_success "Existing VM deleted"
    else
        print_info "Using existing VM. Skipping VM creation..."
        SKIP_VM_CREATION=true
    fi
fi

# Download Debian ISO if not present
if [ ! "$SKIP_VM_CREATION" = true ]; then
    print_header "Downloading Debian ISO"
    ISO_PATH="$HOME/Downloads/$DEBIAN_ISO_NAME"
    
    if [ -f "$ISO_PATH" ]; then
        print_success "Debian ISO already exists: $ISO_PATH"
    else
        print_info "Downloading Debian ISO (this may take a while)..."
        curl -L -o "$ISO_PATH" "$DEBIAN_ISO_URL"
        print_success "Debian ISO downloaded: $ISO_PATH"
    fi
fi

# Create UTM VM configuration
if [ ! "$SKIP_VM_CREATION" = true ]; then
    print_header "Creating UTM VM"
    
    # Create VM directory
    mkdir -p "$VM_DIR"
    
    # Create UTM configuration file
    cat > "$VM_DIR/config.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Backend</key>
    <string>qemu</string>
    <key>ConfigurationVersion</key>
    <integer>4</integer>
    <key>Information</key>
    <dict>
        <key>Name</key>
        <string>$VM_NAME</string>
        <key>Notes</key>
        <string>Debian VM for CI/CD Pipeline - Created automatically</string>
        <key>UUID</key>
        <string>$(uuidgen)</string>
    </dict>
    <key>System</key>
    <dict>
        <key>Architecture</key>
        <string>x86_64</string>
        <key>Boot</key>
        <dict>
            <key>BootOrder</key>
            <array>
                <string>cd</string>
                <string>hd</string>
            </array>
        </dict>
        <key>CPU</key>
        <dict>
            <key>Cores</key>
            <integer>$VM_CPUS</integer>
        </dict>
        <key>Memory</key>
        <dict>
            <key>Size</key>
            <integer>$VM_MEMORY</integer>
        </dict>
        <key>Target</key>
        <string>q35</string>
    </dict>
    <key>Drives</key>
    <array>
        <dict>
            <key>Identifier</key>
            <string>$(uuidgen)</string>
            <key>ImageName</key>
            <string>disk.qcow2</string>
            <key>ImageType</key>
            <string>Disk</string>
            <key>Interface</key>
            <string>ide</string>
            <key>Removable</key>
            <false/>
        </dict>
        <dict>
            <key>Identifier</key>
            <string>$(uuidgen)</string>
            <key>ImageName</key>
            <string>$DEBIAN_ISO_NAME</string>
            <key>ImageType</key>
            <string>CD</string>
            <key>Interface</key>
            <string>ide</string>
            <key>Removable</key>
            <true/>
        </dict>
    </array>
    <key>Networks</key>
    <array>
        <dict>
            <key>Identifier</key>
            <string>$(uuidgen)</string>
            <key>Mode</key>
            <string>Bridged</string>
            <key>Hardware</key>
            <string>rtl8139</string>
        </dict>
    </array>
    <key>Input</key>
    <dict>
        <key>PointingEnabled</key>
        <true/>
        <key>KeyboardEnabled</key>
        <true/>
    </dict>
    <key>Display</key>
    <dict>
        <key>ConsoleMode</key>
        <string>VGA</string>
        <key>PixelFormat</key>
        <string>RGBA8888</string>
        <key>Resolution</key>
        <dict>
            <key>Width</key>
            <integer>1024</integer>
            <key>Height</key>
            <integer>768</integer>
        </dict>
    </dict>
</dict>
</plist>
EOF

    # Create disk image
    print_info "Creating disk image..."
    qemu-img create -f qcow2 "$VM_DIR/Images/disk.qcow2" "${VM_DISK_SIZE}G"
    
    # Copy ISO to VM directory
    mkdir -p "$VM_DIR/Images"
    cp "$ISO_PATH" "$VM_DIR/Images/"
    
    print_success "UTM VM created successfully"
fi

# Generate SSH key for VM access
print_header "Setting up SSH Access"
if [ ! -f "$SSH_KEY_PATH" ]; then
    print_info "Generating SSH key for VM access..."
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "cicd-vm-access"
    print_success "SSH key generated: $SSH_KEY_PATH"
else
    print_success "SSH key already exists: $SSH_KEY_PATH"
fi

# Create VM setup instructions
print_header "VM Installation Instructions"
cat > "$HOME/Desktop/VM_Setup_Instructions.txt" << EOF
CI/CD Pipeline VM Setup Instructions
===================================

Your UTM VM has been created and is ready for installation.

STEP 1: Start the VM
1. Open UTM application
2. Find and start the VM: $VM_NAME
3. The VM will boot from the Debian installer

STEP 2: Install Debian
1. Select "Install" (not Graphical Install)
2. Choose your language, location, and keyboard
3. Configure network (use DHCP)
4. Set hostname: cicd-pipeline
5. Set domain: local
6. Set root password: cicd123 (or your choice)
7. Create user: cicd / password: cicd123 (or your choice)
8. Partition disks: Use entire disk, single partition
9. Select software: SSH server + Standard system utilities
10. Install GRUB to /dev/sda
11. Finish installation and reboot

STEP 3: Post-Installation Setup
After reboot, login as root and run:

# Update system
apt update && apt upgrade -y

# Install sudo and add user
apt install -y sudo
usermod -aG sudo cicd

# Enable SSH with password (temporarily)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh

# Find VM IP address
ip addr show

STEP 4: Continue with Automation
1. Note the VM's IP address
2. Run the automation script: ./setup-vm-complete.sh
3. Enter the VM IP when prompted

The script will handle the rest automatically!
EOF

print_success "Setup instructions saved to Desktop: VM_Setup_Instructions.txt"

# Create the complete setup script
print_header "Creating Complete Setup Script"
cat > "setup-vm-complete.sh" << 'EOF'
#!/bin/bash
# Complete VM setup after Debian installation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

SSH_KEY_PATH="$HOME/.ssh/cicd_vm_key"

echo "========================================="
echo "CI/CD Pipeline VM Complete Setup"
echo "========================================="
echo ""

# Get VM IP
read -p "Enter your VM's IP address: " VM_IP
read -p "Enter SSH username (default: cicd): " SSH_USER
SSH_USER=${SSH_USER:-cicd}

print_info "Testing SSH connection to $SSH_USER@$VM_IP..."

# Test SSH connection with password first
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "echo 'SSH connection successful'"; then
    print_success "SSH connection working"
else
    print_error "Cannot connect to VM. Please check:"
    echo "1. VM is running and network is configured"
    echo "2. SSH server is installed and running"
    echo "3. IP address is correct"
    echo "4. User credentials are correct"
    exit 1
fi

# Copy SSH key to VM
print_info "Setting up SSH key authentication..."
ssh-copy-id -i "$SSH_KEY_PATH.pub" "$SSH_USER@$VM_IP"
print_success "SSH key copied to VM"

# Update Ansible inventory
print_info "Configuring Ansible inventory..."
cd ansible
sed -i.bak "s/your-vm-ip-here/$VM_IP/" inventory.ini
sed -i.bak "s/ansible_user=debian/ansible_user=$SSH_USER/" inventory.ini
sed -i.bak "s|ansible_ssh_private_key_file=.*|ansible_ssh_private_key_file=$SSH_KEY_PATH|" inventory.ini

# Test Ansible connection
print_info "Testing Ansible connection..."
if ansible all -m ping; then
    print_success "Ansible connection successful"
else
    print_error "Ansible connection failed"
    exit 1
fi

# Run the full setup
print_info "Running CI/CD pipeline installation (this takes 5-10 minutes)..."
if ansible-playbook playbook.yml; then
    print_success "Installation completed successfully!"
    
    echo ""
    echo "🎉 Your CI/CD Pipeline is ready!"
    echo ""
    echo "📊 Access your services:"
    echo "   Forgejo:  http://$VM_IP:3000"
    echo "   ArgoCD:   http://$VM_IP:8080"
    echo "   Registry: http://$VM_IP:5000"
    echo ""
    echo "🚀 To start the pipeline:"
    echo "   ssh -i $SSH_KEY_PATH $SSH_USER@$VM_IP"
    echo "   cd local-cicd-pipeline"
    echo "   make start"
    echo ""
    echo "📚 Documentation: ~/local-cicd-pipeline/docs/"
    
    # Save connection info
    cat > "$HOME/Desktop/VM_Connection_Info.txt" << EOL
CI/CD Pipeline VM Connection Information
=======================================

VM IP: $VM_IP
SSH User: $SSH_USER
SSH Key: $SSH_KEY_PATH

Connect to VM:
ssh -i $SSH_KEY_PATH $SSH_USER@$VM_IP

Service URLs:
- Forgejo: http://$VM_IP:3000
- ArgoCD: http://$VM_IP:8080
- Registry: http://$VM_IP:5000

Start Pipeline:
ssh -i $SSH_KEY_PATH $SSH_USER@$VM_IP
cd local-cicd-pipeline
make start

Quick Commands:
cicd-start   # Start all services
cicd-stop    # Stop all services
cicd-status  # Check service status
cicd-logs    # View logs
EOL
    
    print_success "Connection info saved to Desktop: VM_Connection_Info.txt"
    
else
    print_error "Installation failed. Check the output above for errors."
    exit 1
fi
EOF

chmod +x setup-vm-complete.sh

print_success "Complete setup script created: setup-vm-complete.sh"

# Open UTM if not already running
print_header "Starting UTM"
if ! pgrep -f "UTM.app" > /dev/null; then
    print_info "Opening UTM..."
    open -a UTM
    sleep 3
fi

print_header "Setup Complete!"
echo ""
print_success "UTM VM has been created and configured!"
echo ""
echo "📋 Next Steps:"
echo "1. UTM should now be open with your new VM"
echo "2. Start the VM: '$VM_NAME'"
echo "3. Follow the installation instructions on your Desktop"
echo "4. After Debian installation, run: ./setup-vm-complete.sh"
echo ""
echo "📄 Files created:"
echo "   - VM: $VM_DIR"
echo "   - SSH Key: $SSH_KEY_PATH"
echo "   - Instructions: ~/Desktop/VM_Setup_Instructions.txt"
echo "   - Setup Script: ./setup-vm-complete.sh"
echo ""
print_info "The VM will boot from the Debian installer. Follow the instructions!"
echo ""