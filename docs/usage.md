# Usage Guide

## Creating Your First CI/CD Pipeline

### 1. Create a Sample Application

#### Sample Node.js Application
```bash
# Create a new repository in Forgejo
# Then clone it locally
git clone http://localhost:3000/username/sample-app.git
cd sample-app
```

Create the application files:

**package.json**:
```json
{
  "name": "sample-app",
  "version": "1.0.0",
  "description": "Sample application for CI/CD pipeline",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "jest",
    "build": "echo 'Build completed'"
  },
  "dependencies": {
    "express": "^4.18.0"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  }
}
```

**index.js**:
```javascript
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ message: 'Hello from CI/CD Pipeline!', version: '1.0.0' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

module.exports = app;
```

**Dockerfile**:
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

USER node

CMD ["npm", "start"]
```

### 2. Create CI Pipeline (Gitea Actions)

Create `.gitea/workflows/ci.yml`:
```yaml
name: CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Run linting
        run: npm run lint || echo "No linting configured"

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Build Docker image
        run: |
          docker build -t localhost:5000/sample-app:${{ github.sha }} .
          docker build -t localhost:5000/sample-app:latest .
      
      - name: Push to registry
        run: |
          docker push localhost:5000/sample-app:${{ github.sha }}
          docker push localhost:5000/sample-app:latest

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    steps:
      - name: Update staging deployment
        run: |
          echo "Updating staging deployment manifest"
          # This would update your K8s manifests or trigger ArgoCD sync
```

### 3. Create CD Configuration (ArgoCD)

Create Kubernetes manifests in `k8s/` directory:

**k8s/namespace.yaml**:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sample-app
```

**k8s/deployment.yaml**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: sample-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: sample-app
        image: localhost:5000/sample-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

**k8s/service.yaml**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: sample-app-service
  namespace: sample-app
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP
```

### 4. Configure ArgoCD Application

Create ArgoCD application via CLI or UI:

**Via CLI**:
```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Login to ArgoCD
argocd login localhost:8080

# Create application
argocd app create sample-app \
  --repo http://forgejo:3000/username/sample-app.git \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace sample-app \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

**Via UI**:
1. Open ArgoCD at http://localhost:8080
2. Click **New App**
3. Fill in the details:
   - **Application Name**: sample-app
   - **Project**: default
   - **Sync Policy**: Automatic
   - **Repository URL**: http://forgejo:3000/username/sample-app.git
   - **Path**: k8s
   - **Cluster URL**: https://kubernetes.default.svc
   - **Namespace**: sample-app

## Advanced Workflows

### Multi-Environment Pipeline

Create environment-specific branches and configurations:

```
├── environments/
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   └── deployment-patch.yaml
│   └── production/
│       ├── kustomization.yaml
│       └── deployment-patch.yaml
```

**environments/staging/kustomization.yaml**:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../k8s

patchesStrategicMerge:
  - deployment-patch.yaml

namePrefix: staging-
namespace: sample-app-staging
```

### GitOps Workflow

1. **Developer pushes code** → Forgejo
2. **Gitea Actions runs CI** → Tests, builds, pushes image
3. **CI updates manifest** → New image tag in Git
4. **ArgoCD detects change** → Syncs to cluster
5. **Application deployed** → New version running

### Monitoring and Observability

Add monitoring to your application:

**prometheus-config.yaml**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'sample-app'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_label_app]
            action: keep
            regex: sample-app
```

## Common Patterns

### Feature Branch Workflow
```yaml
# .gitea/workflows/feature.yml
name: Feature Branch CI

on:
  push:
    branches-ignore: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: npm test
      
      - name: Build preview
        run: |
          docker build -t localhost:5000/sample-app:pr-${{ github.event.number }} .
          docker push localhost:5000/sample-app:pr-${{ github.event.number }}
```

### Rollback Strategy
```bash
# Rollback via ArgoCD
argocd app rollback sample-app

# Or via kubectl
kubectl rollout undo deployment/sample-app -n sample-app
```

### Blue-Green Deployment
```yaml
# Blue-Green service switching
apiVersion: v1
kind: Service
metadata:
  name: sample-app-active
spec:
  selector:
    app: sample-app
    version: blue  # Switch between blue/green
```

## Troubleshooting Pipelines

### Check CI Logs
```bash
# View runner logs
docker-compose logs runner

# Check specific workflow
# Via Forgejo UI: Repository → Actions → Workflow Run
```

### Check CD Status
```bash
# ArgoCD CLI
argocd app get sample-app
argocd app sync sample-app

# Check application logs
kubectl logs -f deployment/sample-app -n sample-app
```

### Registry Issues
```bash
# Test registry connectivity
curl http://localhost:5000/v2/_catalog

# Check image exists
curl http://localhost:5000/v2/sample-app/tags/list
```

## Next Steps
- [Deploy to different environments](deployment.md)
- [Learn about troubleshooting](troubleshooting.md)
- Explore advanced ArgoCD features
- Set up monitoring and alerting