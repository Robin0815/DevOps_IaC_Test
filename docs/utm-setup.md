# UTM VM Setup Guide for macOS

This guide covers creating a complete CI/CD pipeline using UTM virtualization on macOS.

## Overview

We provide three levels of automation:

1. **🎯 Fully Automated** - Everything done automatically
2. **📋 Semi-Automated** - Manual Debian install, automated CI/CD setup  
3. **🛠️ Manual** - Complete control over the process

## Prerequisites

### System Requirements
- **macOS**: 10.15+ (Catalina or newer)
- **RAM**: 12GB+ (8GB for VM + 4GB for host)
- **Storage**: 60GB+ free space
- **CPU**: Intel or Apple Silicon

### Required Software (Auto-installed)
- UTM (Virtual Machine software)
- Homebrew (Package manager)
- Ansible (Automation tool)
- QEMU (Virtualization backend)

## Option 1: Fully Automated Setup ⚡

**Perfect for**: Users who want everything done automatically

### What It Does
- ✅ Installs UTM and dependencies
- ✅ Downloads Debian ISO
- ✅ Creates preseed configuration for unattended install
- ✅ Creates and configures UTM VM
- ✅ Installs Debian automatically
- ✅ Sets up SSH access
- ✅ Runs Ansible to install CI/CD pipeline
- ✅ Provides ready-to-use environment

### Usage
```bash
chmod +x setup-utm.sh
./setup-utm.sh
# Choose option 1
```

### Timeline
- **5 minutes**: Setup and VM creation
- **20 minutes**: Automated Debian installation
- **10 minutes**: CI/CD pipeline installation
- **Total**: ~35 minutes (mostly unattended)

### VM Configuration
- **Name**: cicd-pipeline-vm-auto
- **RAM**: 8GB
- **Disk**: 40GB
- **CPUs**: 4 cores
- **Username**: cicd
- **Password**: cicd123
- **Hostname**: cicd-pipeline

## Option 2: Semi-Automated Setup 📋

**Perfect for**: Users who want control over Debian installation

### What It Does
- ✅ Installs UTM and dependencies
- ✅ Downloads Debian ISO
- ✅ Creates UTM VM with optimal settings
- ✅ Provides detailed installation instructions
- 👤 You install Debian manually (guided)
- ✅ Automatically sets up CI/CD pipeline after install

### Usage
```bash
chmod +x setup-utm.sh
./setup-utm.sh
# Choose option 2
```

### Manual Steps Required
1. Start the created VM in UTM
2. Follow the Debian installation wizard
3. Run the completion script when done

### Timeline
- **5 minutes**: Setup and VM creation
- **15 minutes**: Manual Debian installation
- **10 minutes**: Automated CI/CD setup
- **Total**: ~30 minutes

## Option 3: Manual Setup 🛠️

**Perfect for**: Advanced users or existing VM users

### Usage
```bash
# Use existing VM or create your own
cd ansible
# Edit inventory.ini with your VM details
ansible-playbook playbook.yml
```

## Post-Installation

### Accessing Your VM
```bash
# SSH to VM (credentials provided after setup)
ssh -i ~/.ssh/cicd_vm_key cicd@VM_IP

# Or use UTM console directly
```

### Starting the CI/CD Pipeline
```bash
# On the VM
cd local-cicd-pipeline
make start

# Wait 2-3 minutes for services to start
make status
```

### Service Access
- **Forgejo**: http://VM_IP:3000
- **ArgoCD**: http://VM_IP:8080  
- **Registry**: http://VM_IP:5000

## VM Management

### UTM Controls
```bash
# UTM is installed at /Applications/UTM.app
open -a UTM

# VM location: ~/UTM VMs/[vm-name].utm
```

### Common Operations
```bash
# Start VM
# Use UTM GUI or:
# (UTM doesn't have reliable CLI, use GUI)

# Connect via SSH
ssh -i ~/.ssh/cicd_vm_key cicd@VM_IP

# Stop services
ssh -i ~/.ssh/cicd_vm_key cicd@VM_IP "cd local-cicd-pipeline && make stop"

# Backup VM
# Use UTM's snapshot feature or:
tar czf vm-backup.tar.gz ~/UTM\ VMs/cicd-pipeline-vm*.utm
```

### Resource Management
```bash
# Check VM resource usage
ssh -i ~/.ssh/cicd_vm_key cicd@VM_IP "htop"

# Adjust VM resources (requires VM shutdown)
# Edit in UTM: VM Settings > System > Memory/CPU
```

## Networking

### UTM Network Modes
- **Shared**: Default, provides internet access
- **Bridged**: VM gets IP on your local network
- **Host Only**: VM only accessible from host

### Port Forwarding (if needed)
```bash
# UTM GUI: VM Settings > Network > Port Forward
# Forward host ports to VM services:
# Host 3000 -> VM 3000 (Forgejo)
# Host 8080 -> VM 8080 (ArgoCD)
# Host 5000 -> VM 5000 (Registry)
```

### Finding VM IP
```bash
# On the VM
ip addr show

# From host (if using shared networking)
# Check UTM network settings or VM console
```

## Troubleshooting

### UTM Installation Issues
```bash
# If UTM install fails
brew install --cask utm --force

# If Homebrew missing
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### VM Creation Issues
```bash
# Check available disk space
df -h

# Check UTM VMs directory
ls -la ~/UTM\ VMs/

# Remove corrupted VM
rm -rf ~/UTM\ VMs/problematic-vm.utm
```

### VM Boot Issues
```bash
# Check VM configuration in UTM
# Ensure ISO is properly attached
# Verify boot order: CD first, then HD

# Reset VM
# UTM: Right-click VM > Delete > Create new
```

### Network Issues
```bash
# Test VM network from host
ping VM_IP

# Test from VM
ssh -i ~/.ssh/cicd_vm_key cicd@VM_IP "ping google.com"

# Check UTM network settings
# VM Settings > Network > Mode
```

### SSH Issues
```bash
# Test SSH key
ssh -i ~/.ssh/cicd_vm_key -v cicd@VM_IP

# Regenerate SSH key if needed
rm ~/.ssh/cicd_vm_key*
ssh-keygen -t ed25519 -f ~/.ssh/cicd_vm_key -N ""

# Copy key to VM manually
ssh-copy-id -i ~/.ssh/cicd_vm_key.pub cicd@VM_IP
```

### Performance Issues
```bash
# Increase VM resources in UTM
# VM Settings > System > Memory (8GB+)
# VM Settings > System > CPU (4+ cores)

# Check host resources
top
# Ensure host has enough free RAM
```

## Advanced Configuration

### Custom VM Settings
```bash
# Edit VM before first boot
# UTM: VM Settings > System
# - Enable hardware acceleration
# - Adjust memory/CPU as needed
# - Configure network mode

# For Apple Silicon Macs
# Use ARM64 architecture if available
# May require different Debian ISO
```

### Automated Snapshots
```bash
# Create snapshot before major changes
# UTM: VM > Snapshots > Create

# Restore from snapshot
# UTM: VM > Snapshots > Restore
```

### Multiple VMs
```bash
# Create multiple environments
./setup-utm.sh  # Creates dev environment
# Edit VM_NAME in script for staging/prod
```

## Integration with Development

### VS Code Remote Development
```bash
# Install Remote-SSH extension
# Connect to: ssh://cicd@VM_IP
# Use SSH key: ~/.ssh/cicd_vm_key
```

### Local Development Workflow
```bash
# Develop locally, test in VM
git push origin feature-branch
# CI/CD pipeline in VM tests and deploys
```

### Backup and Restore
```bash
# Backup entire VM
cp -R ~/UTM\ VMs/cicd-pipeline-vm.utm ~/Backups/

# Backup just the data
ssh -i ~/.ssh/cicd_vm_key cicd@VM_IP "cd local-cicd-pipeline && make backup"
scp -i ~/.ssh/cicd_vm_key cicd@VM_IP:local-cicd-pipeline/backups/* ./local-backups/
```

This UTM setup provides a complete, isolated CI/CD environment that's perfect for development, testing, and learning without affecting your host system.