# Ansible Automation for CI/CD Pipeline

This Ansible playbook automatically sets up the complete CI/CD pipeline on a fresh Debian/Ubuntu VM.

## Prerequisites

### On Your Local Machine (Ansible Control Node)
```bash
# Install Ansible
# Ubuntu/Debian:
sudo apt update
sudo apt install ansible

# macOS:
brew install ansible

# CentOS/RHEL:
sudo yum install epel-release
sudo yum install ansible
```

### Target VM Requirements
- **OS**: Debian 11+ or Ubuntu 20.04+
- **RAM**: 4GB minimum (8GB recommended)
- **Storage**: 20GB+ free space
- **Network**: Internet access
- **SSH**: SSH access with sudo privileges

## Quick Setup

### 1. Prepare Your VM
```bash
# On your Debian VM, ensure SSH and sudo are working
sudo apt update
sudo apt install openssh-server sudo

# Add your SSH key (recommended)
ssh-copy-id user@your-vm-ip
```

### 2. Configure Inventory
```bash
# Edit the inventory file
nano inventory.ini

# Replace 'your-vm-ip-here' with your actual VM IP
[cicd-servers]
192.168.1.100 ansible_user=debian
```

### 3. Run the Playbook
```bash
# Test connection first
ansible all -m ping

# Run the full setup (takes 5-10 minutes)
ansible-playbook playbook.yml

# Or run with verbose output
ansible-playbook playbook.yml -v
```

## What the Playbook Does

### System Setup
- ✅ Updates system packages
- ✅ Installs Docker and Docker Compose
- ✅ Configures firewall (UFW)
- ✅ Sets up user permissions

### CI/CD Pipeline Setup
- ✅ Creates project directory structure
- ✅ Downloads/copies project files
- ✅ Creates data directories with correct permissions
- ✅ Pulls all required Docker images
- ✅ Configures Docker daemon for insecure registry

### Convenience Features
- ✅ Creates systemd service for auto-start
- ✅ Adds helpful bash aliases
- ✅ Creates startup script
- ✅ Sets up environment configuration

## After Installation

### 1. Start the Pipeline
```bash
# SSH to your VM
ssh user@your-vm-ip

# Start the CI/CD pipeline
cd local-cicd-pipeline
make start

# Or use the convenient alias
cicd-start
```

### 2. Access Services
- **Forgejo**: http://your-vm-ip:3000
- **ArgoCD**: http://your-vm-ip:8080
- **Registry**: http://your-vm-ip:5000

### 3. Initial Configuration
```bash
# Check service status
make status

# Get ArgoCD admin password
make argocd-password

# View logs if needed
make logs
```

## Customization

### Different User/SSH Key
```ini
# In inventory.ini
[cicd-servers]
your-vm-ip ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/custom-key.pem
```

### Multiple VMs
```ini
# In inventory.ini
[cicd-servers]
dev-server.example.com ansible_user=debian
staging-server.example.com ansible_user=debian
prod-server.example.com ansible_user=debian
```

### Custom Variables
```bash
# Run with custom variables
ansible-playbook playbook.yml -e "cicd_user=myuser" -e "project_dir=/opt/cicd"
```

## Troubleshooting

### Connection Issues
```bash
# Test SSH connection
ssh -i ~/.ssh/your-key user@your-vm-ip

# Test Ansible connection
ansible all -m ping -v
```

### Permission Issues
```bash
# Ensure user has sudo access
ansible all -m shell -a "sudo whoami" --ask-become-pass
```

### Docker Issues
```bash
# Check Docker installation on target
ansible all -m shell -a "docker --version"
ansible all -m shell -a "docker-compose --version"
```

### Port Conflicts
```bash
# Check if ports are free on target
ansible all -m shell -a "netstat -tuln | grep -E ':(3000|8080|5000)'"
```

## Advanced Usage

### Run Specific Tasks
```bash
# Only install Docker
ansible-playbook playbook.yml --tags docker

# Only setup firewall
ansible-playbook playbook.yml --tags firewall

# Skip Docker installation
ansible-playbook playbook.yml --skip-tags docker
```

### Dry Run
```bash
# Check what would be changed
ansible-playbook playbook.yml --check --diff
```

### Limit to Specific Hosts
```bash
# Run only on specific server
ansible-playbook playbook.yml --limit dev-server.example.com
```

## Production Considerations

### Security Hardening
- Use SSH keys instead of passwords
- Configure proper firewall rules
- Set up HTTPS with reverse proxy
- Enable automatic security updates

### Monitoring
- Enable the monitoring stack
- Set up log aggregation
- Configure alerting

### Backup
- Set up automated backups
- Test restore procedures
- Store backups securely

## Support

If you encounter issues:
1. Check the troubleshooting section
2. Review Ansible logs with `-v` flag
3. Check the main project documentation
4. Verify VM meets minimum requirements