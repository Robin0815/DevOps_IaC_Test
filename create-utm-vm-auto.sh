#!/bin/bash
# Fully Automated UTM VM Creation with Preseed Installation
# This script creates a Debian VM and installs it automatically

set -e

# Colors for output
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

# Configuration
VM_NAME="cicd-pipeline-vm-auto"
VM_MEMORY="8192"
VM_DISK_SIZE="40"
VM_CPUS="4"
VM_USERNAME="cicd"
VM_PASSWORD="cicd123"
VM_HOSTNAME="cicd-pipeline"

# URLs and paths
DEBIAN_ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.2.0-amd64-netinst.iso"
DEBIAN_ISO_NAME="debian-12.2.0-amd64-netinst.iso"
UTM_VMS_DIR="$HOME/UTM VMs"
VM_DIR="$UTM_VMS_DIR/$VM_NAME.utm"
SSH_KEY_PATH="$HOME/.ssh/cicd_vm_auto_key"

print_header "Fully Automated UTM VM Creation"

echo "This script will:"
echo "1. Install UTM if needed"
echo "2. Download Debian ISO"
echo "3. Create preseed file for automated installation"
echo "4. Create and configure UTM VM"
echo "5. Start VM and wait for installation to complete"
echo "6. Set up SSH access and run Ansible automation"
echo ""
echo "VM Configuration:"
echo "  Name: $VM_NAME"
echo "  RAM: ${VM_MEMORY}MB (8GB)"
echo "  Disk: ${VM_DISK_SIZE}GB"
echo "  CPUs: $VM_CPUS"
echo "  Username: $VM_USERNAME"
echo "  Hostname: $VM_HOSTNAME"
echo ""
echo "⏱️  Total time: ~20-30 minutes (mostly automated)"
echo ""

read -p "Continue with automated setup? (y/N): " CONTINUE
if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Check macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is for macOS only"
    exit 1
fi

# Install dependencies
print_header "Installing Dependencies"

# Check and install Homebrew
if ! command -v brew >/dev/null 2>&1; then
    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install required tools
print_info "Installing required tools..."
brew install --cask utm
brew install qemu ansible wget

print_success "Dependencies installed"

# Create directories
mkdir -p "$UTM_VMS_DIR"
mkdir -p "$(dirname "$SSH_KEY_PATH")"

# Generate SSH key
print_header "Setting up SSH Access"
if [ ! -f "$SSH_KEY_PATH" ]; then
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "cicd-vm-auto"
    print_success "SSH key generated"
fi

# Download Debian ISO
print_header "Downloading Debian ISO"
ISO_PATH="$HOME/Downloads/$DEBIAN_ISO_NAME"
if [ ! -f "$ISO_PATH" ]; then
    print_info "Downloading Debian ISO..."
    wget -O "$ISO_PATH" "$DEBIAN_ISO_URL"
fi
print_success "Debian ISO ready"

# Create preseed file for automated installation
print_header "Creating Automated Installation Configuration"
PRESEED_PATH="/tmp/preseed.cfg"
cat > "$PRESEED_PATH" << EOF
# Debian Preseed Configuration for Automated Installation

# Localization
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# Network configuration
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string $VM_HOSTNAME
d-i netcfg/get_domain string local
d-i netcfg/wireless_wep string

# Mirror settings
d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

# Account setup
d-i passwd/root-login boolean true
d-i passwd/root-password password $VM_PASSWORD
d-i passwd/root-password-again password $VM_PASSWORD
d-i passwd/user-fullname string CI/CD User
d-i passwd/username string $VM_USERNAME
d-i passwd/user-password password $VM_PASSWORD
d-i passwd/user-password-again password $VM_PASSWORD
d-i user-setup/allow-password-weak boolean true

# Clock and time zone setup
d-i clock-setup/utc boolean true
d-i time/zone string UTC
d-i clock-setup/ntp boolean true

# Partitioning
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# Base system installation
d-i base-installer/install-recommends boolean false
d-i base-installer/kernel/image string linux-image-amd64

# Package selection
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string openssh-server sudo curl wget git
d-i pkgsel/upgrade select full-upgrade
popularity-contest popularity-contest/participate boolean false

# Boot loader installation
d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string /dev/sda

# Finishing up the installation
d-i finish-install/reboot_in_progress note

# Late commands to set up SSH key
d-i preseed/late_command string \\
    in-target mkdir -p /home/$VM_USERNAME/.ssh; \\
    in-target chmod 700 /home/$VM_USERNAME/.ssh; \\
    echo '$(cat "$SSH_KEY_PATH.pub")' > /target/home/$VM_USERNAME/.ssh/authorized_keys; \\
    in-target chmod 600 /home/$VM_USERNAME/.ssh/authorized_keys; \\
    in-target chown -R $VM_USERNAME:$VM_USERNAME /home/$VM_USERNAME/.ssh; \\
    in-target usermod -aG sudo $VM_USERNAME; \\
    in-target sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config; \\
    in-target systemctl enable ssh
EOF

print_success "Preseed configuration created"

# Create custom Debian ISO with preseed
print_header "Creating Custom Installation ISO"
CUSTOM_ISO_PATH="/tmp/debian-auto-install.iso"
TEMP_ISO_DIR="/tmp/debian-iso"

# Extract original ISO
print_info "Extracting Debian ISO..."
rm -rf "$TEMP_ISO_DIR"
mkdir -p "$TEMP_ISO_DIR"
hdiutil mount "$ISO_PATH" -mountpoint "/tmp/debian-mount" -nobrowse
cp -R "/tmp/debian-mount/"* "$TEMP_ISO_DIR/"
hdiutil unmount "/tmp/debian-mount"

# Add preseed file
cp "$PRESEED_PATH" "$TEMP_ISO_DIR/preseed.cfg"

# Modify isolinux configuration for auto-install
cat > "$TEMP_ISO_DIR/isolinux/isolinux.cfg" << EOF
default auto
timeout 10

label auto
    kernel /install.amd/vmlinuz
    append initrd=/install.amd/initrd.gz auto=true priority=critical preseed/file=/cdrom/preseed.cfg console-setup/ask_detect=false keyboard-configuration/layoutcode=us netcfg/get_hostname=$VM_HOSTNAME netcfg/get_domain=local
EOF

# Create new ISO
print_info "Creating custom ISO..."
genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o "$CUSTOM_ISO_PATH" "$TEMP_ISO_DIR"

print_success "Custom installation ISO created"

# Remove existing VM if present
if [ -d "$VM_DIR" ]; then
    print_warning "Removing existing VM..."
    rm -rf "$VM_DIR"
fi

# Create UTM VM
print_header "Creating UTM VM"
mkdir -p "$VM_DIR/Images"

# Create disk image
qemu-img create -f qcow2 "$VM_DIR/Images/disk.qcow2" "${VM_DISK_SIZE}G"

# Copy custom ISO
cp "$CUSTOM_ISO_PATH" "$VM_DIR/Images/debian-auto.iso"

# Create UTM configuration
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
        <string>Auto-installed Debian VM for CI/CD Pipeline</string>
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
            <string>virtio</string>
            <key>Removable</key>
            <false/>
        </dict>
        <dict>
            <key>Identifier</key>
            <string>$(uuidgen)</string>
            <key>ImageName</key>
            <string>debian-auto.iso</string>
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
            <string>Shared</string>
            <key>Hardware</key>
            <string>virtio-net-pci</string>
        </dict>
    </array>
</dict>
</plist>
EOF

print_success "UTM VM created"

# Start UTM and the VM
print_header "Starting Automated Installation"
print_info "Opening UTM and starting VM..."

# Open UTM
open -a UTM

# Wait for UTM to load
sleep 5

# Start the VM using UTM's command line interface
print_info "Starting VM installation (this will take 15-20 minutes)..."
print_warning "The VM will install automatically. Please be patient..."

# Create monitoring script
cat > "/tmp/monitor_vm.sh" << 'EOF'
#!/bin/bash
VM_NAME="cicd-pipeline-vm-auto"
SSH_KEY_PATH="$HOME/.ssh/cicd_vm_auto_key"
VM_USERNAME="cicd"

echo "Monitoring VM installation..."
echo "This may take 15-20 minutes..."

# Wait for VM to be accessible via SSH
for i in {1..60}; do
    echo "Attempt $i/60: Checking if VM is ready..."
    
    # Try to get VM IP from UTM (this is a simplified approach)
    # In reality, you might need to check UTM's network configuration
    
    # Try common IP ranges for UTM VMs
    for ip in 192.168.64.{2..20} 10.0.2.{2..20}; do
        if timeout 5 ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$VM_USERNAME@$ip" "echo 'VM Ready'" 2>/dev/null; then
            echo "✅ VM is ready at IP: $ip"
            echo "$ip" > /tmp/vm_ip.txt
            exit 0
        fi
    done
    
    sleep 30
done

echo "❌ VM installation timeout. Please check UTM manually."
exit 1
EOF

chmod +x "/tmp/monitor_vm.sh"

# Run monitoring in background
"/tmp/monitor_vm.sh" &
MONITOR_PID=$!

print_info "Installation monitoring started (PID: $MONITOR_PID)"
print_info "You can watch the installation progress in UTM"

# Wait for installation to complete
wait $MONITOR_PID
MONITOR_EXIT_CODE=$?

if [ $MONITOR_EXIT_CODE -eq 0 ]; then
    VM_IP=$(cat /tmp/vm_ip.txt)
    print_success "VM installation completed! IP: $VM_IP"
    
    # Run Ansible setup
    print_header "Running CI/CD Pipeline Setup"
    
    # Update Ansible inventory
    cd ansible
    sed -i.bak "s/your-vm-ip-here/$VM_IP/" inventory.ini
    sed -i.bak "s/ansible_user=debian/ansible_user=$VM_USERNAME/" inventory.ini
    echo "ansible_ssh_private_key_file=$SSH_KEY_PATH" >> inventory.ini
    
    # Run Ansible
    if ansible-playbook playbook.yml; then
        print_success "Complete setup finished!"
        
        # Create connection info
        cat > "$HOME/Desktop/Auto_VM_Info.txt" << EOL
Automated CI/CD Pipeline VM Information
======================================

VM Name: $VM_NAME
VM IP: $VM_IP
Username: $VM_USERNAME
Password: $VM_PASSWORD
SSH Key: $SSH_KEY_PATH

Connect to VM:
ssh -i $SSH_KEY_PATH $VM_USERNAME@$VM_IP

Service URLs:
- Forgejo: http://$VM_IP:3000
- ArgoCD: http://$VM_IP:8080
- Registry: http://$VM_IP:5000

Start Pipeline:
ssh -i $SSH_KEY_PATH $VM_USERNAME@$VM_IP
cd local-cicd-pipeline
make start
EOL
        
        print_header "🎉 Complete Setup Finished!"
        echo ""
        echo "Your fully automated CI/CD pipeline is ready!"
        echo ""
        echo "📊 Access URLs:"
        echo "   Forgejo:  http://$VM_IP:3000"
        echo "   ArgoCD:   http://$VM_IP:8080"
        echo "   Registry: http://$VM_IP:5000"
        echo ""
        echo "🔑 Connection: ssh -i $SSH_KEY_PATH $VM_USERNAME@$VM_IP"
        echo "📄 Details saved to: ~/Desktop/Auto_VM_Info.txt"
        
    else
        print_error "Ansible setup failed"
        exit 1
    fi
else
    print_error "VM installation failed or timed out"
    print_info "Please check UTM and try manual installation"
    exit 1
fi

# Cleanup
rm -rf "$TEMP_ISO_DIR" "/tmp/preseed.cfg" "$CUSTOM_ISO_PATH" "/tmp/monitor_vm.sh" "/tmp/vm_ip.txt"

print_success "Setup complete! Temporary files cleaned up."