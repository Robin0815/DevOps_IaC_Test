# Configuration Guide

## Initial Setup

### 1. Access Forgejo (Git Server)
1. Open http://localhost:3000
2. Complete the initial setup wizard:
   - **Database**: SQLite (default)
   - **Admin Account**: Create your admin user
   - **Server Domain**: `localhost`
   - **SSH Port**: `2222`
   - **HTTP Port**: `3000`
   - **Application URL**: `http://localhost:3000`

### 2. Configure Gitea Actions (CI)
1. In Forgejo admin panel, go to **Site Administration** > **Actions**
2. Enable Actions if not already enabled
3. The runner should auto-register (check logs: `docker-compose logs runner`)

### 3. Access ArgoCD (CD Platform)
1. Open http://localhost:8080
2. Get the initial admin password:
   ```bash
   make argocd-password
   ```
3. Login with username `admin` and the retrieved password
4. Change the password in **User Info** > **Update Password**

## Service Configuration

### Forgejo Configuration

#### Enable Container Registry Integration
Add to Forgejo's `app.ini` (via web UI or volume mount):
```ini
[packages]
ENABLED = true

[packages.registry]
ENABLED = true
```

#### Configure Actions Runner
The runner auto-registers with these labels:
- `docker` - For Docker-based builds
- `ubuntu` - For Ubuntu-based builds

### ArgoCD Configuration

#### Add Git Repository
1. Go to **Settings** > **Repositories**
2. Click **Connect Repo**
3. Add your Forgejo repository:
   - **Type**: Git
   - **Repository URL**: `http://forgejo:3000/username/repo.git`
   - **Username**: Your Forgejo username
   - **Password**: Your Forgejo password or token

#### Configure Container Registry
1. Go to **Settings** > **Repositories**
2. Add the local registry:
   - **Type**: Docker
   - **Name**: `local-registry`
   - **Repository URL**: `localhost:5000`

### Local Registry Configuration

The registry runs on port 5000 and is configured for:
- HTTP access (insecure for local development)
- Delete operations enabled
- No authentication (local use only)

#### Configure Docker/Podman for Insecure Registry
Add to Docker daemon configuration:

**Docker Desktop (macOS/Windows)**:
1. Open Docker Desktop settings
2. Go to **Docker Engine**
3. Add to the JSON configuration:
```json
{
  "insecure-registries": ["localhost:5000"]
}
```

**Linux Docker**:
Edit `/etc/docker/daemon.json`:
```json
{
  "insecure-registries": ["localhost:5000"]
}
```

**Podman**:
Edit `/etc/containers/registries.conf`:
```toml
[[registry]]
location = "localhost:5000"
insecure = true
```

## Environment Customization

### Custom Environment Variables
Create `docker-compose.override.yml`:
```yaml
version: '3.8'
services:
  forgejo:
    environment:
      - FORGEJO__server__DOMAIN=your-domain.com
      - FORGEJO__server__ROOT_URL=https://your-domain.com
  
  argocd-server:
    environment:
      - ARGOCD_SERVER_INSECURE=false  # Enable HTTPS
```

### Custom Volumes
Mount custom configuration:
```yaml
version: '3.8'
services:
  forgejo:
    volumes:
      - ./custom/forgejo:/data/forgejo/custom
  
  argocd-server:
    volumes:
      - ./custom/argocd:/home/argocd/custom
```

## Monitoring Configuration (Optional)

### Enable Monitoring Stack
```bash
make start-monitoring
```

### Prometheus Configuration
Edit `config/prometheus.yml`:
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'forgejo'
    static_configs:
      - targets: ['forgejo:3000']
    metrics_path: '/metrics'
  
  - job_name: 'argocd'
    static_configs:
      - targets: ['argocd-server:8080']
    metrics_path: '/metrics'
```

### Grafana Dashboards
1. Access Grafana at http://localhost:3001
2. Login with `admin/admin`
3. Add Prometheus data source: `http://prometheus:9090`
4. Import dashboards for Forgejo and ArgoCD

## Security Configuration

### Production Security Settings

#### Forgejo Security
```ini
[security]
INSTALL_LOCK = true
SECRET_KEY = your-secret-key-here
INTERNAL_TOKEN = your-internal-token-here

[service]
DISABLE_REGISTRATION = true
REQUIRE_SIGNIN_VIEW = true
```

#### ArgoCD Security
```yaml
# In argocd-server service
environment:
  - ARGOCD_SERVER_INSECURE=false
  - ARGOCD_SERVER_GRPC_WEB=true
volumes:
  - ./certs:/app/config/tls
```

### Network Security
For production, consider:
- Using reverse proxy (nginx, traefik)
- Enabling HTTPS/TLS
- Restricting network access
- Using secrets management

## Backup Configuration

### Automated Backups
Create a backup script:
```bash
#!/bin/bash
# backup.sh
make backup
# Upload to cloud storage
aws s3 cp backups/ s3://your-backup-bucket/ --recursive
```

Add to crontab:
```bash
# Daily backup at 2 AM
0 2 * * * /path/to/backup.sh
```

## Next Steps
- [Learn how to use the pipeline](usage.md)
- [Deploy to different environments](deployment.md)
- [Troubleshoot common issues](troubleshooting.md)