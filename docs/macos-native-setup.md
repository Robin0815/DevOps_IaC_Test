# Native macOS CI/CD Pipeline Setup

## Overview

Run the complete CI/CD pipeline directly on your Mac without any virtualization. This provides the best performance and easiest integration with your local development environment.

## ✅ Advantages of Native macOS Setup

### **🚀 Performance Benefits**
- **No VM overhead** - Direct access to system resources
- **Faster startup** - Services start in seconds, not minutes
- **Better resource utilization** - No hypervisor layer
- **Native Docker performance** - Optimal container performance

### **🔧 Development Integration**
- **Direct file system access** - Easy to browse data and logs
- **Local networking** - Services accessible via localhost
- **IDE integration** - Direct access from VS Code, IntelliJ, etc.
- **Host tool access** - Use native macOS tools and utilities

### **💻 Convenience Features**
- **Menu bar integration** - Docker Desktop integration
- **Native notifications** - System-level alerts
- **Spotlight search** - Find project files easily
- **Time Machine backup** - Automatic backup of pipeline data

## System Requirements

### **Hardware Requirements**
- **CPU**: Intel or Apple Silicon (M1/M2/M3)
- **RAM**: 8GB minimum (16GB+ recommended)
- **Storage**: 20GB+ free space (SSD recommended)
- **Network**: Internet connection for initial setup

### **Software Requirements**
- **macOS**: 10.15+ (Catalina or newer)
- **Docker Desktop**: Latest version
- **Homebrew**: Package manager (auto-installed)
- **Xcode Command Line Tools**: Auto-installed with Homebrew

## Quick Setup

### **🎯 One-Command Installation**
```bash
chmod +x setup-macos-native.sh
./setup-macos-native.sh
```

### **📋 Manual Installation**
```bash
# Install Homebrew (if not present)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker

# Install other tools
brew install docker-compose git make curl jq

# Start Docker Desktop and complete setup

# Clone and start pipeline
make setup
make start
```

## Configuration Differences

### **Docker Desktop Configuration**
The native setup automatically configures Docker Desktop for optimal CI/CD use:

```json
{
  "insecure-registries": ["localhost:5000"],
  "experimental": false
}
```

### **Resource Allocation**
Docker Desktop resource settings (recommended):
- **Memory**: 6-8GB (adjust based on your system)
- **CPU**: 4+ cores
- **Disk**: 60GB+ (for images and data)
- **Swap**: 2GB

### **Network Configuration**
Services are accessible via localhost:
- **Forgejo**: http://localhost:3000
- **ArgoCD**: http://localhost:8080
- **Registry**: http://localhost:5000
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3001

## Native macOS Features

### **Convenience Aliases**
The setup automatically adds shell aliases:
```bash
cicd-start    # Start all services
cicd-stop     # Stop all services
cicd-status   # Check service status
cicd-logs     # View service logs
cicd-backup   # Create backup
cicd-clean    # Clean up everything
```

### **Desktop Integration**
- **Service info file** on Desktop with all URLs and commands
- **Spotlight searchable** project files
- **Finder integration** for easy file access

### **Menu Bar Access**
Docker Desktop provides menu bar access to:
- Container status and logs
- Resource usage monitoring
- Quick restart options
- Volume and network management

## Development Workflow

### **Local Development Integration**
```bash
# Your typical workflow
cd ~/Projects/my-app

# Push to local Forgejo
git remote add local http://localhost:3000/username/my-app.git
git push local main

# CI/CD pipeline runs automatically
# View progress at http://localhost:3000

# Deploy via ArgoCD
# Monitor at http://localhost:8080
```

### **IDE Integration**
```bash
# VS Code with Docker extension
code .
# View containers, logs, and exec into containers

# IntelliJ with Docker plugin
# Direct container management from IDE
```

### **Database Access**
```bash
# Direct access to Forgejo database
sqlite3 data/forgejo/forgejo.db

# View Git repositories
ls -la data/forgejo/git/repositories/

# Browse registry contents
curl http://localhost:5000/v2/_catalog
```

## Performance Optimization

### **Docker Desktop Settings**
```bash
# Optimize Docker Desktop for CI/CD
# Docker Desktop > Settings > Resources:
# - Memory: 6-8GB
# - CPU: 4+ cores
# - Disk image size: 60GB+

# Enable experimental features for better performance
# Docker Desktop > Settings > Docker Engine:
{
  "experimental": true,
  "features": {
    "buildkit": true
  }
}
```

### **macOS System Optimization**
```bash
# Increase file descriptor limits
echo 'ulimit -n 65536' >> ~/.zshrc

# Optimize for development
# System Preferences > Energy Saver:
# - Prevent computer from sleeping automatically
# - Put hard disks to sleep: Never
```

### **Storage Optimization**
```bash
# Use SSD for best performance
# Store data on fastest drive available

# Clean up Docker regularly
docker system prune -a

# Monitor disk usage
du -sh data/
docker system df
```

## Monitoring and Observability

### **Native Monitoring Tools**
```bash
# Activity Monitor integration
# View Docker processes and resource usage

# Console app integration
# View Docker and container logs

# Network Utility
# Monitor port usage and connections
```

### **Built-in Monitoring Stack**
```bash
# Enable Prometheus + Grafana
make start-monitoring

# Access monitoring
open http://localhost:9090  # Prometheus
open http://localhost:3001  # Grafana (admin/admin)
```

### **Log Management**
```bash
# View all logs
make logs

# Follow logs in real-time
make logs-follow

# View specific service logs
docker-compose logs forgejo
docker-compose logs argocd-server

# macOS Console app integration
# Logs appear in system Console app
```

## Backup and Restore

### **Time Machine Integration**
```bash
# Ensure project directory is backed up
# Time Machine automatically backs up:
# - Project files
# - Data directory
# - Configuration files
```

### **Manual Backup**
```bash
# Create backup
make backup

# Backup to external drive
rsync -av . /Volumes/Backup/cicd-pipeline/

# Cloud backup
tar czf cicd-backup.tar.gz data/ config/
# Upload to iCloud, Dropbox, etc.
```

### **Restore Process**
```bash
# Stop services
make stop

# Restore data
tar xzf cicd-backup.tar.gz

# Restart services
make start
```

## Troubleshooting Native Setup

### **Docker Desktop Issues**
```bash
# Docker not starting
# 1. Restart Docker Desktop
# 2. Check system resources
# 3. Reset Docker Desktop if needed

# Port conflicts
lsof -i :3000  # Find what's using port 3000
kill -9 PID    # Kill conflicting process

# Permission issues
# Docker Desktop handles permissions automatically
# No manual permission fixes needed
```

### **Performance Issues**
```bash
# Check Docker Desktop resources
# Docker Desktop > Settings > Resources

# Check system resources
top
Activity Monitor

# Clean up Docker
docker system prune -a
docker volume prune
```

### **Network Issues**
```bash
# Test localhost connectivity
curl http://localhost:3000

# Check Docker network
docker network ls
docker network inspect bridge

# Reset Docker networks
docker network prune
```

## Security Considerations

### **Local Development Security**
```bash
# Services are bound to localhost only
# Not accessible from external networks
# Safe for development use

# For production deployment:
# Use proper authentication
# Enable HTTPS
# Configure firewall rules
```

### **Docker Desktop Security**
```bash
# Docker Desktop runs with user privileges
# No root access required
# Containers run in isolated environment

# Enable Docker Content Trust (optional)
export DOCKER_CONTENT_TRUST=1
```

## Integration with Cloud Services

### **Hybrid Development**
```bash
# Develop locally, deploy to cloud
# Use local pipeline for testing
# Deploy to cloud for production

# Cloud registry integration
docker tag localhost:5000/app:latest your-registry.com/app:latest
docker push your-registry.com/app:latest
```

### **Remote Git Integration**
```bash
# Use local Forgejo for development
# Mirror to GitHub/GitLab for collaboration
git remote add origin https://github.com/user/repo.git
git remote add local http://localhost:3000/user/repo.git

# Push to both
git push origin main
git push local main
```

## Advanced Configuration

### **Custom Docker Compose Override**
```yaml
# docker-compose.override.yml
version: '3.8'
services:
  forgejo:
    ports:
      - "3001:3000"  # Use different port
    volumes:
      - /Users/username/git-repos:/data/git/repositories
  
  argocd-server:
    environment:
      - ARGOCD_SERVER_INSECURE=false  # Enable HTTPS
```

### **Environment-Specific Configuration**
```bash
# Development environment
export ENVIRONMENT=development
make start

# Staging environment  
export ENVIRONMENT=staging
make start

# Different configurations loaded automatically
```

## Migration from VM Setup

### **From UTM/VMware to Native**
```bash
# Export data from VM
ssh user@vm-ip "cd local-cicd-pipeline && make backup"
scp user@vm-ip:local-cicd-pipeline/backups/* ./backups/

# Set up native environment
./setup-macos-native.sh

# Restore data
tar xzf backups/forgejo-backup.tar.gz -C data/
make start
```

The native macOS setup provides the optimal development experience with maximum performance and seamless integration with your local development workflow.