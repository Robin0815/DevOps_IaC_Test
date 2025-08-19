# Using Existing VMs with CI/CD Pipeline

## Overview

The Ansible automation works perfectly with **any existing VM**, regardless of how it was created. You don't need to create a new VM - just point the Ansible playbook at your existing Debian/Ubuntu VM.

## ✅ Compatible VM Types

### UTM VMs (macOS)
- ✅ Existing UTM VMs you already have
- ✅ VMs created with different settings
- ✅ VMs with different OS versions
- ✅ Both Intel and Apple Silicon VMs

### Other Virtualization Platforms
- ✅ **VMware Fusion/Workstation** VMs
- ✅ **VirtualBox** VMs  
- ✅ **Parallels Desktop** VMs
- ✅ **QEMU/KVM** VMs
- ✅ **Hyper-V** VMs
- ✅ **Cloud VMs** (AWS, GCP, Azure, DigitalOcean)
- ✅ **Physical servers**
- ✅ **Docker containers** with SSH
- ✅ **WSL2** instances

## Requirements for Existing VMs

### Operating System
- **Debian**: 10, 11, 12 (Buster, Bullseye, Bookworm)
- **Ubuntu**: 18.04, 20.04, 22.04, 23.04 LTS
- **Other Debian-based**: Linux Mint, Pop!_OS, etc.

### System Resources
- **RAM**: 4GB minimum (8GB+ recommended)
- **Storage**: 20GB+ free space
- **CPU**: 2+ cores recommended
- **Network**: Internet access required

### Access Requirements
- **SSH access** with sudo privileges
- **User account** with sudo rights
- **SSH key or password** authentication
- **Ports available**: 3000, 8080, 5000 (or configurable)

## Quick Setup for Existing VMs

### Step 1: Test SSH Access
```bash
# Test connection to your existing VM
ssh your-username@your-vm-ip

# Ensure sudo works
sudo whoami
```

### Step 2: Configure Ansible Inventory
```bash
# Edit the inventory file
cd ansible
nano inventory.ini

# Replace with your VM details:
[cicd-servers]
your-vm-ip ansible_user=your-username ansible_ssh_private_key_file=~/.ssh/your-key
```

### Step 3: Run the Playbook
```bash
# Test connection
ansible all -m ping

# Run the full setup
ansible-playbook playbook.yml

# Or with verbose output
ansible-playbook playbook.yml -v
```

## Configuration Examples

### For UTM VM with Password Auth
```ini
[cicd-servers]
192.168.64.5 ansible_user=debian ansible_ssh_pass=your-password
```

### For UTM VM with SSH Key
```ini
[cicd-servers]
192.168.64.5 ansible_user=debian ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### For VMware/VirtualBox VM
```ini
[cicd-servers]
192.168.1.100 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/vm_key
```

### For Cloud VM (AWS/GCP/Azure)
```ini
[cicd-servers]
your-cloud-vm.compute.amazonaws.com ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/aws-key.pem
```

### For Multiple VMs
```ini
[cicd-servers]
dev-vm.local ansible_user=debian
staging-vm.local ansible_user=ubuntu  
prod-vm.local ansible_user=centos

[cicd-servers:vars]
ansible_ssh_private_key_file=~/.ssh/shared_key
```

## VM-Specific Considerations

### UTM VMs
```bash
# Find UTM VM IP
# In UTM: VM Details > Network
# Or on VM: ip addr show

# UTM typically uses these IP ranges:
# Shared Network: 192.168.64.x
# Bridged Network: Your local network range
```

### VMware VMs
```bash
# VMware typically uses:
# NAT: 192.168.x.x
# Bridged: Your local network range
# Host-only: 192.168.x.x
```

### VirtualBox VMs
```bash
# VirtualBox typically uses:
# NAT: 10.0.2.x
# Bridged: Your local network range
# Host-only: 192.168.56.x
```

### Cloud VMs
```bash
# Use public IP or hostname
# Ensure security groups allow SSH (port 22)
# And CI/CD ports: 3000, 8080, 5000
```

## Advanced Configuration

### Custom Variables
```bash
# Run with custom settings
ansible-playbook playbook.yml -e "cicd_user=myuser" -e "project_dir=/opt/cicd"
```

### Skip Certain Tasks
```bash
# Skip Docker installation (if already installed)
ansible-playbook playbook.yml --skip-tags docker

# Only run specific tasks
ansible-playbook playbook.yml --tags firewall,setup
```

### Different SSH Ports
```ini
[cicd-servers]
your-vm-ip:2222 ansible_user=debian ansible_ssh_private_key_file=~/.ssh/key
```

### Using Sudo Password
```ini
[cicd-servers]
your-vm-ip ansible_user=debian ansible_become_pass=sudo-password
```

## Troubleshooting Existing VMs

### SSH Connection Issues
```bash
# Test manual SSH first
ssh -v your-username@your-vm-ip

# Check SSH service on VM
sudo systemctl status ssh

# Check firewall on VM
sudo ufw status
```

### Permission Issues
```bash
# Ensure user has sudo access
sudo usermod -aG sudo your-username

# Test sudo without password (recommended)
echo "your-username ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/your-username
```

### Network Issues
```bash
# Check VM can reach internet
ping google.com

# Check required ports are free
sudo netstat -tlnp | grep -E ':(3000|8080|5000)'
```

### Resource Issues
```bash
# Check available resources
free -h
df -h

# Increase VM resources if needed
# (varies by virtualization platform)
```

## Migration from Other Setups

### From Docker Desktop
```bash
# If you have Docker Desktop, the playbook will:
# - Use existing Docker installation
# - Configure for CI/CD use
# - Add insecure registry settings
```

### From Existing CI/CD Tools
```bash
# The playbook can coexist with:
# - Jenkins (different ports)
# - GitLab (different ports)  
# - GitHub Actions runners
# - Other containerized services
```

### From Development Environment
```bash
# The playbook won't interfere with:
# - Existing development tools
# - IDE configurations
# - Local databases
# - Other Docker containers
```

## Post-Installation with Existing VMs

### Accessing Services
```bash
# Services will be available at your VM's IP:
# Forgejo: http://your-vm-ip:3000
# ArgoCD: http://your-vm-ip:8080
# Registry: http://your-vm-ip:5000
```

### Integration with Host
```bash
# Add to /etc/hosts for easy access (optional)
echo "your-vm-ip forgejo.local" | sudo tee -a /etc/hosts
echo "your-vm-ip argocd.local" | sudo tee -a /etc/hosts

# Then access via:
# http://forgejo.local:3000
# http://argocd.local:8080
```

### Backup Considerations
```bash
# VM snapshots (recommended before running playbook)
# Platform-specific snapshot commands

# Data backups (after installation)
ssh your-username@your-vm-ip "cd local-cicd-pipeline && make backup"
```

## Benefits of Using Existing VMs

### ✅ **No VM Creation Overhead**
- Use VMs you already have configured
- Keep existing network settings
- Maintain current resource allocations

### ✅ **Preserve Existing Setup**
- Won't interfere with other services
- Keeps your development environment
- Maintains existing SSH keys and access

### ✅ **Flexible Resource Management**
- Adjust VM resources as needed
- Use different VM configurations
- Scale resources based on usage

### ✅ **Multi-Platform Support**
- Works with any virtualization platform
- Consistent setup across different hosts
- Easy to replicate on different systems

The Ansible automation is designed to be **completely platform-agnostic** - it only cares that it can SSH to a Debian/Ubuntu system with sudo access. Whether that system is a UTM VM, VMware VM, cloud instance, or physical server doesn't matter at all!