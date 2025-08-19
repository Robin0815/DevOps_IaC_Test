# Quick Start Guide - Deploy Any Webapp

## 🚀 Running the Pipeline

### 1. Start the Services
```bash
make start
# Wait for services to be ready (1-2 minutes)
make status
```

### 2. Initial Setup
1. **Forgejo Setup** (http://localhost:3000):
   - Complete setup wizard
   - Create admin account
   - Enable Actions in admin panel

2. **ArgoCD Setup** (http://localhost:8080):
   - Get password: `make argocd-password`
   - Login as `admin`

## 📁 Deploy ANY Webapp - Step by Step

### Option 1: Use the Sample App (Easiest)
```bash
# 1. Create new repo in Forgejo UI
# 2. Clone the sample app
cp -r examples/sample-app/* /path/to/your/new/repo/
cd /path/to/your/new/repo/

# 3. Push to Forgejo
git add .
git commit -m "Initial commit"
git push origin main

# 4. CI will automatically run!
```

### Option 2: Add CI/CD to Your Existing Webapp

#### For Node.js Apps:
```bash
# In your existing Node.js project:
mkdir -p .gitea/workflows

# Create CI workflow
cat > .gitea/workflows/ci.yml << 'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - run: npm ci
      - run: npm test
      - run: npm run build

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker image
        run: |
          docker build -t localhost:5000/my-app:${{ github.sha }} .
          docker push localhost:5000/my-app:${{ github.sha }}
EOF

# Create Dockerfile if you don't have one
cat > Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF
```

#### For Python Apps:
```bash
mkdir -p .gitea/workflows

cat > .gitea/workflows/ci.yml << 'EOF'
name: Python CI/CD

on:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - run: pip install -r requirements.txt
      - run: pytest
      - run: python -m build

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker image
        run: |
          docker build -t localhost:5000/my-python-app:${{ github.sha }} .
          docker push localhost:5000/my-python-app:${{ github.sha }}
EOF

# Sample Dockerfile for Python
cat > Dockerfile << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "app.py"]
EOF
```

#### For Static Sites (React, Vue, etc.):
```bash
mkdir -p .gitea/workflows

cat > .gitea/workflows/ci.yml << 'EOF'
name: Static Site CI/CD

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run build
      - name: Build Docker image
        run: |
          docker build -t localhost:5000/my-site:${{ github.sha }} .
          docker push localhost:5000/my-site:${{ github.sha }}
EOF

# Dockerfile for static sites
cat > Dockerfile << 'EOF'
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
```

## 🎯 Setting Up Kubernetes Deployment (CD)

### 1. Create Kubernetes Manifests
```bash
mkdir -p k8s

# Namespace
cat > k8s/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
EOF

# Deployment
cat > k8s/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: localhost:5000/my-app:latest
        ports:
        - containerPort: 3000  # Change to your app's port
        env:
        - name: NODE_ENV
          value: "production"
EOF

# Service
cat > k8s/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  namespace: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 3000  # Change to your app's port
  type: ClusterIP
EOF
```

### 2. Configure ArgoCD Application
```bash
# Method 1: Via ArgoCD UI
# 1. Go to http://localhost:8080
# 2. Click "New App"
# 3. Fill in:
#    - Name: my-app
#    - Repository: http://forgejo:3000/username/my-app.git
#    - Path: k8s
#    - Destination: https://kubernetes.default.svc
#    - Namespace: my-app

# Method 2: Via CLI (if you have kubectl access)
argocd app create my-app \
  --repo http://forgejo:3000/username/my-app.git \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace my-app \
  --sync-policy automated
```

## 🔄 Complete Workflow

1. **Developer pushes code** → Forgejo receives it
2. **Gitea Actions triggers** → Runs tests, builds Docker image
3. **Image pushed to registry** → localhost:5000
4. **ArgoCD detects changes** → Syncs to Kubernetes
5. **App deployed** → Running in cluster

## 🛠️ Customization for Different Apps

### Environment Variables
```yaml
# In k8s/deployment.yaml
env:
- name: DATABASE_URL
  value: "postgresql://user:pass@db:5432/myapp"
- name: REDIS_URL
  value: "redis://redis:6379"
```

### Different Ports
```yaml
# In k8s/deployment.yaml and service.yaml
ports:
- containerPort: 8080  # Your app's port
# And in service:
- port: 80
  targetPort: 8080
```

### Health Checks
```yaml
# In k8s/deployment.yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
```

## 🎯 What Gets Deployed?

**Any webapp that can be containerized:**
- ✅ Node.js apps (Express, Next.js, etc.)
- ✅ Python apps (Django, Flask, FastAPI)
- ✅ Static sites (React, Vue, Angular)
- ✅ Go applications
- ✅ Java/Spring Boot apps
- ✅ PHP applications
- ✅ .NET applications
- ✅ Any Docker-compatible app

## 🚨 Requirements Summary

### For CI to work:
- `.gitea/workflows/*.yml` file
- `Dockerfile` in your repo
- Tests that can run in the workflow

### For CD to work:
- Kubernetes manifests (usually in `k8s/` folder)
- ArgoCD application configured
- Access to a Kubernetes cluster

### For local development:
- Just the CI part works fine
- Images get built and stored in local registry
- You can test deployments manually

## 🎉 Success Indicators

- ✅ Push code → CI runs automatically
- ✅ Tests pass → Docker image builds
- ✅ Image appears in registry (http://localhost:5000/v2/_catalog)
- ✅ ArgoCD syncs → App deploys to Kubernetes
- ✅ App accessible via Kubernetes service

That's it! Any webapp can now use this CI/CD pipeline with minimal setup.