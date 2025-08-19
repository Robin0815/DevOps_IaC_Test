# System Prerequisites

## Minimum System Requirements

### Hardware
- **CPU**: 2+ cores (4+ recommended)
- **RAM**: 4GB minimum (8GB+ recommended)
- **Storage**: 20GB+ free space
- **Network**: Internet connection for initial setup

### Operating System Support
- **Linux**: Ubuntu 20.04+, Debian 11+, CentOS 8+, RHEL 8+
- **macOS**: 10.15+ with Homebrew
- **Windows**: WSL2 with Ubuntu

## Required Software

### Core Requirements
1. **Docker** (20.10+) or **Podman** (3.0+)
2. **Docker Compose** (2.0+) or **Podman Compose**
3. **Git** (2.20+)
4. **Make** (optional, for convenience)

### Network Requirements
- **Ports available**: 3000, 8080, 5000, 9090, 3001
- **Internet access** for pulling container images
- **DNS resolution** working properly

## Manual Installation (if not using Ansible)

### Debian/Ubuntu
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin

# Install other tools
sudo apt install git make curl wget

# Logout and login to apply docker group
```

### CentOS/RHEL
```bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Install other tools
sudo yum install -y git make curl wget
```

### macOS
```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install docker docker-compose git make

# Start Docker Desktop
open /Applications/Docker.app
```

## Verification Commands

After installation, verify everything works:

```bash
# Check Docker
docker --version
docker-compose --version
docker run hello-world

# Check Git
git --version

# Check Make
make --version

# Check available ports
sudo netstat -tlnp | grep -E ':(3000|8080|5000|9090|3001)'
```

## Firewall Configuration

### UFW (Ubuntu/Debian)
```bash
# Allow required ports
sudo ufw allow 3000/tcp  # Forgejo
sudo ufw allow 8080/tcp  # ArgoCD
sudo ufw allow 5000/tcp  # Registry
sudo ufw allow 9090/tcp  # Prometheus (optional)
sudo ufw allow 3001/tcp  # Grafana (optional)
```

### Firewalld (CentOS/RHEL)
```bash
# Allow required ports
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --permanent --add-port=9090/tcp
sudo firewall-cmd --permanent --add-port=3001/tcp
sudo firewall-cmd --reload
```

## Resource Optimization

### For Low-Resource Systems (4GB RAM)
```bash
# Limit container resources in docker-compose.override.yml
version: '3.8'
services:
  forgejo:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
  
  argocd-server:
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.3'
```

### For Production Systems (8GB+ RAM)
- No resource limits needed
- Consider enabling monitoring stack
- Set up automated backups

## Security Considerations

### Basic Security Setup
```bash
# Create non-root user for running services
sudo useradd -m -s /bin/bash cicd-user
sudo usermod -aG docker cicd-user

# Set up SSH key authentication
ssh-keygen -t ed25519 -C "cicd-pipeline"

# Configure fail2ban (optional)
sudo apt install fail2ban
```

### Production Security
- Use reverse proxy (nginx/traefik) with HTTPS
- Configure proper firewall rules
- Set up log monitoring
- Enable automatic security updates
- Use secrets management

## Troubleshooting Prerequisites

### Docker Issues
```bash
# Check Docker daemon
sudo systemctl status docker

# Check Docker permissions
groups $USER

# Test Docker without sudo
docker ps
```

### Port Conflicts
```bash
# Find what's using a port
sudo lsof -i :3000

# Kill process using port
sudo kill -9 $(sudo lsof -t -i:3000)
```

### Memory Issues
```bash
# Check available memory
free -h

# Check disk space
df -h

# Clean up Docker
docker system prune -a
```

## Next Steps

After meeting prerequisites:
1. Use the Ansible playbook for automated setup
2. Or follow the manual installation guide
3. Run `make start` to begin using the pipeline