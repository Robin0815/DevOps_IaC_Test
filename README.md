# Local CI/CD Pipeline with IaC

A complete Infrastructure as Code (IaC) solution for running a full CI/CD pipeline locally using open-source tools.

## Architecture

- **Git Server**: Forgejo (Gitea fork) - Self-hosted Git service
- **CI Platform**: Gitea Actions - Built-in CI/CD for Forgejo
- **CD Platform**: ArgoCD - GitOps continuous delivery
- **Container Runtime**: Docker/Podman compatible
- **Infrastructure**: Docker Compose for orchestration

## Components

1. **Forgejo** - Git repository hosting with web UI
2. **Gitea Actions Runner** - CI/CD execution engine
3. **ArgoCD** - GitOps CD platform
4. **Registry** - Local container registry for built images
5. **Monitoring** - Prometheus + Grafana (optional)

## Quick Start

```bash
# Clone and start the pipeline
git clone <this-repo>
cd local-cicd-pipeline
make start

# Access services (wait 1-2 minutes for startup)
make status

# Follow the quick start guide to deploy your first app
```

**🚀 [Quick Start Guide](docs/quick-start-guide.md) - Deploy any webapp in 5 minutes!**

## Prerequisites

### System Requirements
- **CPU**: 2+ cores (4+ recommended)
- **RAM**: 4GB minimum (8GB+ recommended)  
- **Storage**: 20GB+ free space
- **OS**: Linux, macOS, or Windows with WSL2

### Required Software
- Docker (20.10+) or Podman (3.0+)
- Docker Compose (2.0+)
- Git (2.20+)
- Make (optional)

**📋 [Full Prerequisites Guide](docs/prerequisites.md)**

## Installation Options

### Option 1: 🚀 Native macOS (Fastest & Recommended)
```bash
# Runs directly on your Mac - no VM needed!
chmod +x setup-macos-native.sh
./setup-macos-native.sh
```
**⚡ Best performance, 10 minutes setup, perfect for development**

### Option 2: 🎯 Complete UTM VM Automation (macOS)
```bash
# Creates VM, installs Debian, sets up CI/CD - fully automated!
chmod +x setup-utm.sh
./setup-utm.sh
```
**🔒 Isolated environment, 30 minutes setup**

### Option 3: 🤖 Existing VM Automation  
```bash
# Works with ANY existing VM (UTM, VMware, VirtualBox, Cloud, etc.)
chmod +x setup-vm.sh
./setup-vm.sh
```
**🤖 [Ansible Automation Guide](ansible/README.md) | [Existing VM Guide](docs/existing-vm-setup.md)**

### Option 4: 📖 Manual Setup
```bash
# Install Docker, Docker Compose, Git, Make
# Then:
make setup
make start
```
**📖 [Manual Installation Guide](docs/installation.md)**

## Services Access

- Forgejo: http://localhost:3000
- ArgoCD: http://localhost:8080
- Registry: http://localhost:5000
- Grafana: http://localhost:3001 (if enabled)

## Documentation

- **[Quick Start Guide](docs/quick-start-guide.md)** - Deploy any webapp in 5 minutes
- **[Native macOS Setup](docs/macos-native-setup.md)** - Best performance, no VM needed
- [UTM VM Setup](docs/utm-setup.md) - Complete VM automation for macOS
- [Existing VM Setup](docs/existing-vm-setup.md) - Use any existing VM
- [Installation Guide](docs/installation.md) - Detailed setup instructions
- [Configuration](docs/configuration.md) - Service configuration
- [Usage Examples](docs/usage.md) - Advanced workflows
- [Data Structure](docs/data-structure.md) - Local storage explained
- [Troubleshooting](docs/troubleshooting.md) - Common issues
- [Multi-Platform Deployment](docs/deployment.md) - Production deployment