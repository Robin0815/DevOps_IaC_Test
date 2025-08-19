# Troubleshooting Guide

## Common Issues and Solutions

### Service Startup Issues

#### Services Won't Start
**Symptoms**: Containers exit immediately or fail to start
```bash
# Check service status
make status

# View logs for specific service
docker-compose logs forgejo
docker-compose logs runner
docker-compose logs argocd-server
```

**Common Causes**:
1. **Port conflicts**:
   ```bash
   # Check what's using the port
   lsof -i :3000
   # Kill the process or change port in docker-compose.yml
   ```

2. **Insufficient resources**:
   ```bash
   # Check system resources
   docker system df
   docker system prune  # Clean up if needed
   ```

3. **Permission issues**:
   ```bash
   # Fix Docker permissions (Linux)
   sudo usermod -aG docker $USER
   newgrp docker
   ```

#### Database Connection Issues
**Symptoms**: Forgejo shows database connection errors
```bash
# Check if database is running
docker-compose ps postgres

# Check database logs
docker-compose logs postgres

# Reset database (WARNING: destroys data)
docker-compose down -v
docker-compose up -d
```

### Forgejo Issues

#### Can't Access Web Interface
**Symptoms**: Browser shows "connection refused" or timeout
```bash
# Check if Forgejo is running
docker-compose ps forgejo

# Check Forgejo logs
docker-compose logs forgejo

# Test connectivity
curl -I http://localhost:3000
```

**Solutions**:
1. **Service not ready**: Wait for startup (can take 1-2 minutes)
2. **Port binding issue**: Check if port 3000 is available
3. **Firewall blocking**: Check firewall rules

#### Actions Runner Not Registering
**Symptoms**: No runners visible in Forgejo Actions settings
```bash
# Check runner logs
docker-compose logs runner

# Manual registration
docker exec -it gitea-runner act_runner register \
  --instance http://forgejo:3000 \
  --token YOUR_REGISTRATION_TOKEN
```

**Get registration token**:
1. Go to Forgejo admin panel
2. Navigate to Actions → Runners
3. Copy the registration token
4. Update the runner service with the token

#### Git Operations Fail
**Symptoms**: Can't clone, push, or pull repositories
```bash
# Test SSH connection
ssh -T git@localhost -p 2222

# Test HTTP clone
git clone http://localhost:3000/username/repo.git

# Check SSH key configuration
cat ~/.ssh/id_rsa.pub
```

### ArgoCD Issues

#### Can't Access ArgoCD UI
**Symptoms**: ArgoCD web interface not accessible
```bash
# Check ArgoCD services
docker-compose ps | grep argocd

# Check ArgoCD server logs
docker-compose logs argocd-server

# Get admin password
make argocd-password
```

#### Applications Not Syncing
**Symptoms**: ArgoCD shows "OutOfSync" status
```bash
# Check application status
argocd app get sample-app

# Force sync
argocd app sync sample-app

# Check repository connectivity
argocd repo list
```

**Common causes**:
1. **Repository access**: Check credentials and URL
2. **Manifest errors**: Validate Kubernetes YAML
3. **Resource conflicts**: Check for existing resources

#### Repository Connection Failed
**Symptoms**: "Unable to connect to repository" error
```bash
# Test repository access from ArgoCD container
docker exec argocd-server git ls-remote http://forgejo:3000/username/repo.git

# Check network connectivity
docker exec argocd-server ping forgejo
```

### Registry Issues

#### Can't Push/Pull Images
**Symptoms**: Docker push/pull fails with registry errors
```bash
# Test registry connectivity
curl http://localhost:5000/v2/_catalog

# Check registry logs
docker-compose logs registry

# List images in registry
curl http://localhost:5000/v2/_catalog | jq
```

**Configure insecure registry**:
```json
# /etc/docker/daemon.json
{
  "insecure-registries": ["localhost:5000"]
}
```

#### Registry Storage Full
**Symptoms**: Push operations fail with storage errors
```bash
# Check registry storage usage
docker exec local-registry du -sh /var/lib/registry

# Clean up old images
docker exec local-registry registry garbage-collect /etc/docker/registry/config.yml
```

### CI/CD Pipeline Issues

#### Workflows Not Triggering
**Symptoms**: Git pushes don't trigger CI workflows
```bash
# Check if Actions are enabled
# Go to Forgejo → Repository Settings → Actions

# Check workflow file syntax
# Validate .gitea/workflows/*.yml files

# Check runner availability
# Go to Forgejo → Admin → Actions → Runners
```

#### Build Failures
**Symptoms**: CI jobs fail during execution
```bash
# Check workflow logs in Forgejo UI
# Repository → Actions → Workflow Run

# Check runner logs
docker-compose logs runner

# Test build locally
docker build -t test-image .
```

#### Deployment Failures
**Symptoms**: ArgoCD can't deploy applications
```bash
# Check application events
argocd app get sample-app

# Check Kubernetes events
kubectl get events -n sample-app

# Validate manifests
kubectl apply --dry-run=client -f k8s/
```

### Network and Connectivity Issues

#### Services Can't Communicate
**Symptoms**: Services can't reach each other
```bash
# Check Docker network
docker network ls
docker network inspect local-cicd-pipeline_cicd-network

# Test connectivity between containers
docker exec forgejo ping argocd-server
docker exec runner ping registry
```

#### DNS Resolution Issues
**Symptoms**: Services can't resolve hostnames
```bash
# Check DNS resolution
docker exec forgejo nslookup registry
docker exec argocd-server nslookup forgejo

# Check /etc/hosts in containers
docker exec forgejo cat /etc/hosts
```

### Performance Issues

#### Slow Response Times
**Symptoms**: Web interfaces are slow or unresponsive
```bash
# Check system resources
docker stats

# Check disk usage
df -h
docker system df

# Check memory usage
free -h
```

**Solutions**:
1. **Increase resources**: Add more RAM/CPU
2. **Clean up**: Remove unused containers/images
3. **Optimize**: Tune service configurations

#### High Resource Usage
**Symptoms**: System becomes slow, high CPU/memory usage
```bash
# Identify resource-heavy containers
docker stats --no-stream

# Check for resource limits
docker-compose config | grep -A 5 -B 5 resources

# Monitor system resources
htop
iotop
```

### Data and Storage Issues

#### Volume Mount Failures
**Symptoms**: Services can't access persistent data
```bash
# Check volume mounts
docker-compose config | grep -A 10 volumes

# Check local data directory permissions
ls -la data/

# Fix permissions for local data directories
sudo chown -R 1000:1000 data/forgejo
sudo chown -R 999:999 data/argocd
sudo chown -R 65534:65534 data/prometheus
sudo chown -R 472:472 data/grafana
```

#### Data Corruption
**Symptoms**: Services fail to start, data appears corrupted
```bash
# Check filesystem
ls -la data/forgejo/

# Restore from backup
make restore

# Reset specific service data (WARNING: destroys data)
docker-compose down
rm -rf data/forgejo/
mkdir -p data/forgejo
docker-compose up -d
```

## Debugging Commands

### Comprehensive Health Check
```bash
#!/bin/bash
# health-check.sh

echo "=== System Resources ==="
free -h
df -h

echo "=== Docker Status ==="
docker version
docker-compose version

echo "=== Service Status ==="
docker-compose ps

echo "=== Network Connectivity ==="
curl -I http://localhost:3000 || echo "Forgejo not accessible"
curl -I http://localhost:8080 || echo "ArgoCD not accessible"
curl -I http://localhost:5000/v2/ || echo "Registry not accessible"

echo "=== Container Resources ==="
docker stats --no-stream

echo "=== Recent Logs ==="
docker-compose logs --tail=10
```

### Log Collection
```bash
#!/bin/bash
# collect-logs.sh

mkdir -p debug-logs/$(date +%Y%m%d-%H%M%S)
cd debug-logs/$(date +%Y%m%d-%H%M%S)

# Collect service logs
docker-compose logs > docker-compose.log
docker-compose logs forgejo > forgejo.log
docker-compose logs runner > runner.log
docker-compose logs argocd-server > argocd.log
docker-compose logs registry > registry.log

# Collect system info
docker version > docker-version.txt
docker-compose version > docker-compose-version.txt
docker-compose ps > services-status.txt
docker network ls > networks.txt
docker volume ls > volumes.txt

# Collect configuration
cp ../../docker-compose.yml .
cp -r ../../config .

echo "Debug information collected in: $(pwd)"
```

## Getting Help

### Log Analysis
When reporting issues, include:
1. **Service logs**: `docker-compose logs [service-name]`
2. **System information**: OS, Docker version, available resources
3. **Configuration**: Relevant parts of docker-compose.yml
4. **Steps to reproduce**: What you were trying to do
5. **Expected vs actual behavior**

### Community Resources
- **Forgejo**: https://codeberg.org/forgejo/forgejo/issues
- **ArgoCD**: https://github.com/argoproj/argo-cd/issues
- **Docker**: https://docs.docker.com/
- **Stack Overflow**: Tag questions with relevant tool names

### Professional Support
For production deployments, consider:
- Professional consulting services
- Managed CI/CD platforms
- Enterprise support contracts
- Custom development services

## Prevention

### Regular Maintenance
```bash
# Weekly maintenance script
#!/bin/bash

# Update images
docker-compose pull

# Clean up unused resources
docker system prune -f

# Backup data
make backup

# Check service health
make status
```

### Monitoring Setup
```bash
# Set up basic monitoring
docker-compose --profile monitoring up -d

# Configure alerts
# Set up Grafana dashboards
# Configure Prometheus alerts
```

### Best Practices
1. **Regular backups**: Automate daily backups
2. **Resource monitoring**: Set up alerts for resource usage
3. **Log rotation**: Configure log rotation to prevent disk full
4. **Security updates**: Regularly update container images
5. **Documentation**: Keep deployment documentation updated