# Installation Guide

## Prerequisites

### System Requirements
- **OS**: macOS, Linux (Ubuntu, CentOS, Debian, etc.)
- **RAM**: 8GB+ recommended (4GB minimum)
- **Storage**: 20GB+ free space
- **CPU**: 2+ cores recommended

### Required Software

#### Option 1: Docker (Recommended)
```bash
# macOS (using Homebrew)
brew install docker docker-compose

# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose
sudo usermod -aG docker $USER

# CentOS/RHEL
sudo yum install docker docker-compose
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

#### Option 2: Podman (Alternative)
```bash
# macOS
brew install podman podman-compose

# Ubuntu/Debian
sudo apt install podman podman-compose

# CentOS/RHEL
sudo yum install podman podman-compose
```

### Optional Tools
```bash
# Make (for convenience commands)
# macOS
brew install make

# Ubuntu/Debian
sudo apt install make

# Git (if not already installed)
# macOS
brew install git

# Ubuntu/Debian
sudo apt install git
```

## Installation Steps

### 1. Clone the Repository
```bash
git clone <repository-url>
cd local-cicd-pipeline
```

### 2. Initial Setup
```bash
# Run setup to create necessary directories and configs
make setup

# Or manually:
mkdir -p config docs examples backups data/{forgejo,runner,argocd,registry,prometheus,grafana}
```

### 3. Configure (Optional)
Edit configuration files in the `config/` directory if needed:
- `prometheus.yml` - Monitoring configuration
- Custom environment variables in `docker-compose.override.yml`

### 4. Start Services
```bash
# Start basic pipeline
make start

# Or start with monitoring
make start-monitoring

# Or using docker-compose directly
docker-compose up -d
```

### 5. Verify Installation
```bash
# Check service status
make status

# View logs
make logs
```

## Port Configuration

Default ports used:
- **3000**: Forgejo web interface
- **2222**: Forgejo SSH
- **8080**: ArgoCD web interface
- **5000**: Container registry
- **9090**: Prometheus (monitoring)
- **3001**: Grafana (monitoring)

### Changing Ports
If you need to change ports, edit the `docker-compose.yml` file:

```yaml
services:
  forgejo:
    ports:
      - "3001:3000"  # Change 3000 to 3001
```

## Using Podman Instead of Docker

### 1. Install Podman Compose
```bash
# Create alias for docker-compose
echo 'alias docker-compose="podman-compose"' >> ~/.bashrc
source ~/.bashrc
```

### 2. Enable Podman Socket (Linux)
```bash
systemctl --user enable podman.socket
systemctl --user start podman.socket
```

### 3. Update Docker Socket Path
Create `docker-compose.override.yml`:
```yaml
version: '3.8'
services:
  forgejo:
    volumes:
      - /run/user/1000/podman/podman.sock:/var/run/docker.sock
  runner:
    volumes:
      - /run/user/1000/podman/podman.sock:/var/run/docker.sock
```

## Troubleshooting Installation

### Common Issues

#### Port Already in Use
```bash
# Find what's using the port
lsof -i :3000

# Kill the process or change the port in docker-compose.yml
```

#### Permission Denied (Docker)
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in, or:
newgrp docker
```

#### Out of Disk Space
```bash
# Clean up Docker
docker system prune -a

# Or for Podman
podman system prune -a
```

#### Services Not Starting
```bash
# Check logs
make logs

# Check individual service
docker-compose logs forgejo
```

## Next Steps

After installation:
1. [Configure the services](configuration.md)
2. [Set up your first project](usage.md)
3. [Learn about deployment options](deployment.md)