# Flask + React CI/CD Example

A complete full-stack application demonstrating the CI/CD pipeline with:
- **Backend**: Python Flask API with SQLite database
- **Frontend**: React SPA with modern UI
- **CI/CD**: Complete pipeline with testing, building, and deployment
- **Containerization**: Multi-stage Docker builds
- **Kubernetes**: Production-ready manifests

## Architecture

```
flask-react-app/
├── backend/              # Flask API server
│   ├── app.py           # Main Flask application
│   ├── models.py        # Database models
│   ├── requirements.txt # Python dependencies
│   └── tests/           # Backend tests
├── frontend/            # React application
│   ├── src/             # React source code
│   ├── public/          # Static assets
│   ├── package.json     # Node.js dependencies
│   └── tests/           # Frontend tests
├── docker/              # Docker configurations
│   ├── Dockerfile.backend
│   ├── Dockerfile.frontend
│   └── docker-compose.dev.yml
├── k8s/                 # Kubernetes manifests
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   └── ingress.yaml
├── .gitea/workflows/    # CI/CD pipeline
│   └── ci-cd.yml
└── docs/                # Documentation
```

## Features

### Backend (Flask)
- ✅ RESTful API with CRUD operations
- ✅ SQLite database with SQLAlchemy ORM
- ✅ User authentication with JWT
- ✅ Input validation and error handling
- ✅ Unit and integration tests
- ✅ Health check endpoints
- ✅ CORS support for frontend

### Frontend (React)
- ✅ Modern React with hooks and context
- ✅ Material-UI components
- ✅ Responsive design
- ✅ API integration with axios
- ✅ User authentication flow
- ✅ Error handling and loading states
- ✅ Unit tests with Jest and React Testing Library

### CI/CD Pipeline
- ✅ Automated testing (backend + frontend)
- ✅ Code quality checks (linting, formatting)
- ✅ Security scanning
- ✅ Multi-stage Docker builds
- ✅ Container registry push
- ✅ Kubernetes deployment
- ✅ Environment-specific configurations

## Quick Start

### 1. Development Setup
```bash
# Clone to your Forgejo repository
cp -r examples/flask-react-app/* /path/to/your/repo/

# Backend setup
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python app.py

# Frontend setup (new terminal)
cd frontend
npm install
npm start
```

### 2. Docker Development
```bash
# Build and run with Docker Compose
docker-compose -f docker/docker-compose.dev.yml up --build

# Access services:
# Frontend: http://localhost:3000
# Backend API: http://localhost:5000
```

### 3. CI/CD Pipeline
```bash
# Push to Forgejo to trigger pipeline
git add .
git commit -m "Add Flask React app"
git push origin main

# Monitor pipeline at:
# http://localhost:3000/your-username/your-repo/actions
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get user profile

### Tasks (CRUD Example)
- `GET /api/tasks` - List all tasks
- `POST /api/tasks` - Create new task
- `GET /api/tasks/{id}` - Get specific task
- `PUT /api/tasks/{id}` - Update task
- `DELETE /api/tasks/{id}` - Delete task

### Health & Monitoring
- `GET /health` - Health check
- `GET /api/metrics` - Application metrics

## Testing

### Backend Tests
```bash
cd backend
python -m pytest tests/ -v
python -m pytest tests/ --cov=app
```

### Frontend Tests
```bash
cd frontend
npm test
npm run test:coverage
```

### Integration Tests
```bash
# Start services
docker-compose -f docker/docker-compose.dev.yml up -d

# Run integration tests
cd tests
python integration_tests.py
```

## Deployment

### Local Kubernetes
```bash
# Apply manifests
kubectl apply -f k8s/

# Check deployment
kubectl get pods -n flask-react-app
kubectl get services -n flask-react-app

# Access application
kubectl port-forward -n flask-react-app svc/frontend-service 8080:80
```

### Production Considerations
- Environment variables for configuration
- Persistent volumes for database
- Ingress with HTTPS/TLS
- Resource limits and requests
- Horizontal Pod Autoscaling
- Monitoring and logging

## Environment Variables

### Backend
- `DATABASE_URL` - Database connection string
- `JWT_SECRET_KEY` - JWT signing key
- `FLASK_ENV` - Environment (development/production)
- `CORS_ORIGINS` - Allowed CORS origins

### Frontend
- `REACT_APP_API_URL` - Backend API URL
- `REACT_APP_ENV` - Environment name

## Monitoring

The application includes built-in monitoring:
- Health check endpoints
- Application metrics
- Request logging
- Error tracking
- Performance monitoring

Access metrics at:
- Backend: http://localhost:5000/api/metrics
- Frontend: Built-in React DevTools support

This example demonstrates a complete modern web application with proper CI/CD practices, containerization, and Kubernetes deployment.