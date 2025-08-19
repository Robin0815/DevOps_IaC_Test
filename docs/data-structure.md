# Data Directory Structure

## Overview

All persistent data is stored locally in the `data/` subdirectory within the project folder. This approach provides:

- **Portability**: Easy to backup, move, or version control data
- **Transparency**: Clear visibility of what data is stored
- **Simplicity**: No Docker volume management needed
- **Development-friendly**: Easy access to data files for debugging

## Directory Structure

```
data/
├── forgejo/          # Forgejo Git server data
│   ├── forgejo.db    # SQLite database
│   ├── git/          # Git repositories
│   ├── attachments/  # File attachments
│   ├── avatars/      # User avatars
│   └── lfs/          # Git LFS objects
├── runner/           # Gitea Actions runner data
│   ├── .runner       # Runner configuration
│   └── token         # Registration token
├── argocd/           # ArgoCD data
│   ├── ssh/          # SSH keys
│   ├── tls/          # TLS certificates
│   └── plugins/      # ArgoCD plugins
├── registry/         # Container registry data
│   └── docker/       # Registry storage
│       └── registry/
├── prometheus/       # Prometheus metrics data (optional)
│   └── data/         # Time series data
└── grafana/          # Grafana dashboards data (optional)
    ├── grafana.db    # Grafana database
    └── dashboards/   # Dashboard definitions
```

## Permissions

Each service runs with specific user IDs that need appropriate permissions:

```bash
# Set correct permissions after first run
sudo chown -R 1000:1000 data/forgejo    # Forgejo user
sudo chown -R 1000:1000 data/runner     # Runner user  
sudo chown -R 999:999 data/argocd       # ArgoCD user
sudo chown -R 65534:65534 data/registry # Registry user
sudo chown -R 65534:65534 data/prometheus # Prometheus user
sudo chown -R 472:472 data/grafana      # Grafana user
```

## Backup and Restore

### Manual Backup
```bash
# Create timestamped backup
tar czf backup-$(date +%Y%m%d-%H%M%S).tar.gz data/

# Backup specific services
tar czf forgejo-backup.tar.gz data/forgejo/
tar czf argocd-backup.tar.gz data/argocd/
```

### Automated Backup
```bash
# Use the provided Makefile command
make backup
```

### Restore
```bash
# Stop services
docker-compose down

# Restore from backup
tar xzf backup-20240101-120000.tar.gz

# Fix permissions
sudo chown -R 1000:1000 data/forgejo
sudo chown -R 999:999 data/argocd
# ... (other permissions as needed)

# Start services
docker-compose up -d
```

## Migration

### From Docker Volumes
If you have existing data in Docker volumes, migrate it:

```bash
# Stop services
docker-compose down

# Create data directories
mkdir -p data/{forgejo,runner,argocd,registry,prometheus,grafana}

# Copy data from Docker volumes
docker run --rm -v local-cicd-pipeline_forgejo-data:/source -v $(PWD)/data/forgejo:/dest alpine cp -a /source/. /dest/
docker run --rm -v local-cicd-pipeline_argocd-data:/source -v $(PWD)/data/argocd:/dest alpine cp -a /source/. /dest/
# ... repeat for other volumes

# Fix permissions
sudo chown -R 1000:1000 data/forgejo
sudo chown -R 999:999 data/argocd

# Remove old volumes
docker volume rm local-cicd-pipeline_forgejo-data local-cicd-pipeline_argocd-data

# Start with new configuration
docker-compose up -d
```

### To Different System
```bash
# On source system
make backup

# Transfer backup file to destination
scp backup-*.tar.gz user@destination:/path/to/project/

# On destination system
tar xzf backup-*.tar.gz
sudo chown -R 1000:1000 data/forgejo
sudo chown -R 999:999 data/argocd
make start
```

## Development Tips

### Accessing Data Files
```bash
# View Forgejo database
sqlite3 data/forgejo/forgejo.db ".tables"

# Browse Git repositories
ls -la data/forgejo/git/repositories/

# Check ArgoCD configuration
cat data/argocd/ssh/ssh_known_hosts

# View registry contents
find data/registry -name "*.json" | head -5
```

### Debugging Storage Issues
```bash
# Check disk usage
du -sh data/*

# Check permissions
ls -la data/

# Monitor file access
sudo lsof +D data/
```

### Cleaning Up
```bash
# Remove all data (WARNING: destructive)
make clean

# Remove specific service data
rm -rf data/forgejo/
mkdir -p data/forgejo

# Clean up old registry images
docker exec local-registry registry garbage-collect /etc/docker/registry/config.yml
```

## Security Considerations

### File Permissions
- Ensure data directory is not world-readable
- Use appropriate user/group ownership
- Consider encrypting sensitive data at rest

### Backup Security
- Encrypt backups before storing remotely
- Use secure transfer methods (scp, rsync over SSH)
- Regularly test backup restoration

### Access Control
```bash
# Restrict access to data directory
chmod 750 data/
chmod -R 640 data/forgejo/
chmod -R 640 data/argocd/
```

This local data storage approach makes the CI/CD pipeline completely self-contained and portable while maintaining full control over your data.