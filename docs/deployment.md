# Multi-Platform Deployment Guide

## Overview

This guide covers deploying the CI/CD pipeline across different environments and platforms while maintaining consistency and security.

## Deployment Scenarios

### 1. Local Development (Current Setup)
- **Use Case**: Development, testing, learning
- **Infrastructure**: Docker Compose on local machine
- **Networking**: localhost, insecure connections
- **Storage**: Local volumes

### 2. Single Server Deployment
- **Use Case**: Small teams, staging environments
- **Infrastructure**: Single Linux server with Docker
- **Networking**: Domain name, reverse proxy, HTTPS
- **Storage**: Server local storage or NFS

### 3. Multi-Server Deployment
- **Use Case**: Production environments, high availability
- **Infrastructure**: Multiple servers, load balancing
- **Networking**: Service mesh, internal DNS
- **Storage**: Distributed storage, backups

### 4. Cloud Deployment
- **Use Case**: Scalable production environments
- **Infrastructure**: Kubernetes, managed services
- **Networking**: Cloud load balancers, CDN
- **Storage**: Cloud storage, automated backups

## Platform-Specific Configurations

### Linux Server Deployment

#### Prerequisites
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose nginx certbot

# CentOS/RHEL
sudo yum install docker docker-compose nginx certbot
sudo systemctl enable docker
sudo systemctl start docker
```

#### Production Configuration
Create `docker-compose.prod.yml`:
```yaml
version: '3.8'

services:
  forgejo:
    environment:
      - FORGEJO__server__DOMAIN=git.yourdomain.com
      - FORGEJO__server__ROOT_URL=https://git.yourdomain.com
      - FORGEJO__server__CERT_FILE=/certs/fullchain.pem
      - FORGEJO__server__KEY_FILE=/certs/privkey.pem
      - FORGEJO__database__DB_TYPE=postgres
      - FORGEJO__database__HOST=postgres:5432
      - FORGEJO__database__NAME=forgejo
      - FORGEJO__database__USER=forgejo
      - FORGEJO__database__PASSWD=${POSTGRES_PASSWORD}
    volumes:
      - /etc/letsencrypt/live/git.yourdomain.com:/certs:ro
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=forgejo
      - POSTGRES_USER=forgejo
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data

  argocd-server:
    environment:
      - ARGOCD_SERVER_INSECURE=false
    volumes:
      - /etc/letsencrypt/live/argocd.yourdomain.com:/certs:ro

volumes:
  postgres-data:
```

#### Nginx Reverse Proxy
```nginx
# /etc/nginx/sites-available/cicd
server {
    listen 80;
    server_name git.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name git.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/git.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/git.yourdomain.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 443 ssl http2;
    server_name argocd.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/argocd.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/argocd.yourdomain.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # ArgoCD specific headers
        proxy_set_header Accept-Encoding "";
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Kubernetes Deployment

#### Helm Chart Structure
```
helm-chart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── forgejo/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   ├── argocd/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   └── registry/
│       ├── deployment.yaml
│       └── service.yaml
```

**Chart.yaml**:
```yaml
apiVersion: v2
name: local-cicd-pipeline
description: A complete CI/CD pipeline for Kubernetes
version: 1.0.0
appVersion: "1.0.0"
```

**values.yaml**:
```yaml
global:
  domain: yourdomain.com
  storageClass: fast-ssd

forgejo:
  image:
    repository: codeberg.org/forgejo/forgejo
    tag: "1.21"
  
  ingress:
    enabled: true
    hostname: git.yourdomain.com
    tls: true
  
  postgresql:
    enabled: true
    auth:
      database: forgejo
      username: forgejo

argocd:
  server:
    ingress:
      enabled: true
      hostname: argocd.yourdomain.com
      tls: true
  
  configs:
    secret:
      argocdServerAdminPassword: "$2a$12$..."  # bcrypt hash

registry:
  persistence:
    enabled: true
    size: 100Gi
    storageClass: fast-ssd
```

#### Deploy to Kubernetes
```bash
# Add required Helm repositories
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD first
helm install argocd argo/argo-cd -n argocd --create-namespace

# Deploy the pipeline
helm install cicd-pipeline ./helm-chart -n cicd --create-namespace
```

### Cloud Platform Deployments

#### AWS Deployment
```yaml
# terraform/aws/main.tf
provider "aws" {
  region = var.aws_region
}

# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  
  cluster_name    = "cicd-pipeline"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  node_groups = {
    main = {
      desired_capacity = 3
      max_capacity     = 10
      min_capacity     = 1
      instance_types   = ["t3.medium"]
    }
  }
}

# RDS for Forgejo
resource "aws_db_instance" "forgejo" {
  identifier = "forgejo-db"
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  
  allocated_storage = 20
  storage_encrypted = true
  
  db_name  = "forgejo"
  username = "forgejo"
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = false
  final_snapshot_identifier = "forgejo-final-snapshot"
}
```

#### Google Cloud Deployment
```yaml
# terraform/gcp/main.tf
provider "google" {
  project = var.project_id
  region  = var.region
}

# GKE Cluster
resource "google_container_cluster" "cicd_pipeline" {
  name     = "cicd-pipeline"
  location = var.region
  
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = var.region
  cluster    = google_container_cluster.cicd_pipeline.name
  node_count = 3
  
  node_config {
    preemptible  = false
    machine_type = "e2-medium"
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

# Cloud SQL for Forgejo
resource "google_sql_database_instance" "forgejo" {
  name             = "forgejo-db"
  database_version = "POSTGRES_15"
  region           = var.region
  
  settings {
    tier = "db-f1-micro"
    
    backup_configuration {
      enabled = true
      start_time = "03:00"
    }
  }
}
```

## Environment-Specific Configurations

### Development Environment
```bash
# .env.development
ENVIRONMENT=development
LOG_LEVEL=debug
FORGEJO_DOMAIN=localhost
ARGOCD_INSECURE=true
REGISTRY_AUTH=false
```

### Staging Environment
```bash
# .env.staging
ENVIRONMENT=staging
LOG_LEVEL=info
FORGEJO_DOMAIN=git-staging.yourdomain.com
ARGOCD_INSECURE=false
REGISTRY_AUTH=true
BACKUP_ENABLED=true
```

### Production Environment
```bash
# .env.production
ENVIRONMENT=production
LOG_LEVEL=warn
FORGEJO_DOMAIN=git.yourdomain.com
ARGOCD_INSECURE=false
REGISTRY_AUTH=true
BACKUP_ENABLED=true
MONITORING_ENABLED=true
ALERTING_ENABLED=true
```

## Migration and Upgrade Strategies

### Data Migration
```bash
#!/bin/bash
# migrate.sh - Migrate from local to server deployment

# 1. Backup current data
make backup

# 2. Transfer backups to new server
scp backups/* user@newserver:/tmp/

# 3. On new server, restore data
docker run --rm -v cicd_forgejo-data:/data -v /tmp:/backup alpine \
  tar xzf /backup/forgejo-backup.tar.gz -C /data

# 4. Update DNS records
# 5. Start services on new server
```

### Rolling Updates
```yaml
# kubernetes/deployment.yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    spec:
      containers:
      - name: forgejo
        image: codeberg.org/forgejo/forgejo:1.21
        readinessProbe:
          httpGet:
            path: /api/healthz
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
```

## Security Considerations

### Network Security
```yaml
# Network policies for Kubernetes
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cicd-network-policy
spec:
  podSelector:
    matchLabels:
      app: forgejo
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx-ingress
    ports:
    - protocol: TCP
      port: 3000
```

### Secrets Management
```bash
# Using Kubernetes secrets
kubectl create secret generic forgejo-secrets \
  --from-literal=admin-password='secure-password' \
  --from-literal=jwt-secret='jwt-secret-key'

# Using HashiCorp Vault
vault kv put secret/cicd/forgejo \
  admin-password='secure-password' \
  jwt-secret='jwt-secret-key'
```

## Monitoring and Observability

### Production Monitoring Stack
```yaml
# monitoring/prometheus-values.yaml
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: fast-ssd
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 100Gi

grafana:
  persistence:
    enabled: true
    size: 10Gi
  
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        folder: ''
        type: file
        options:
          path: /var/lib/grafana/dashboards/default
```

## Disaster Recovery

### Backup Strategy
```bash
#!/bin/bash
# backup-production.sh

# Database backup
kubectl exec -n cicd deployment/postgres -- pg_dump -U forgejo forgejo > forgejo-db-$(date +%Y%m%d).sql

# Volume backup
kubectl get pvc -n cicd -o name | xargs -I {} kubectl exec -n cicd deployment/backup-pod -- \
  tar czf /backups/{}-$(date +%Y%m%d).tar.gz -C /mnt/{}

# Upload to cloud storage
aws s3 cp /backups/ s3://your-backup-bucket/$(date +%Y%m%d)/ --recursive
```

### Recovery Procedures
```bash
#!/bin/bash
# restore-production.sh

# Restore database
kubectl exec -n cicd deployment/postgres -- psql -U forgejo -d forgejo < forgejo-db-backup.sql

# Restore volumes
kubectl exec -n cicd deployment/backup-pod -- \
  tar xzf /backups/forgejo-data-backup.tar.gz -C /mnt/forgejo-data/
```

This deployment guide provides comprehensive coverage for moving your CI/CD pipeline from local development to production environments across different platforms while maintaining security and reliability.