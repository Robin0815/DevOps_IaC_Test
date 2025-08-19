#!/usr/bin/env python3
"""
Flask Backend API for CI/CD Pipeline Demo
A complete REST API with authentication, CRUD operations, and monitoring
"""

import os
import logging
from datetime import datetime, timedelta
from functools import wraps

from flask import Flask, request, jsonify, g
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_migrate import Migrate
from werkzeug.security import generate_password_hash, check_password_hash
import jwt

# Initialize Flask app
app = Flask(__name__)

# Configuration
app.config['SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///app.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_EXPIRATION_DELTA'] = timedelta(hours=24)

# Initialize extensions
db = SQLAlchemy(app)
migrate = Migrate(app, db)
CORS(app, origins=os.environ.get('CORS_ORIGINS', 'http://localhost:3000').split(','))

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Models
class User(db.Model):
    """User model for authentication"""
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_active = db.Column(db.Boolean, default=True)
    
    # Relationships
    tasks = db.relationship('Task', backref='user', lazy=True, cascade='all, delete-orphan')
    
    def set_password(self, password):
        """Hash and set password"""
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        """Check password against hash"""
        return check_password_hash(self.password_hash, password)
    
    def generate_token(self):
        """Generate JWT token"""
        payload = {
            'user_id': self.id,
            'username': self.username,
            'exp': datetime.utcnow() + app.config['JWT_EXPIRATION_DELTA']
        }
        return jwt.encode(payload, app.config['SECRET_KEY'], algorithm='HS256')
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'created_at': self.created_at.isoformat(),
            'is_active': self.is_active
        }

class Task(db.Model):
    """Task model for CRUD operations demo"""
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    completed = db.Column(db.Boolean, default=False)
    priority = db.Column(db.String(20), default='medium')  # low, medium, high
    due_date = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Foreign key
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'completed': self.completed,
            'priority': self.priority,
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
            'user_id': self.user_id
        }

# Authentication decorator
def token_required(f):
    """Decorator to require JWT token"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        
        if not token:
            return jsonify({'error': 'Token is missing'}), 401
        
        try:
            # Remove 'Bearer ' prefix if present
            if token.startswith('Bearer '):
                token = token[7:]
            
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            current_user = User.query.get(data['user_id'])
            
            if not current_user or not current_user.is_active:
                return jsonify({'error': 'Invalid token'}), 401
            
            g.current_user = current_user
            
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token'}), 401
        
        return f(*args, **kwargs)
    
    return decorated

# Health check endpoints
@app.route('/health')
def health_check():
    """Basic health check"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0'
    })

@app.route('/health/ready')
def readiness_check():
    """Readiness check - includes database connectivity"""
    try:
        # Test database connection
        db.session.execute('SELECT 1')
        return jsonify({
            'status': 'ready',
            'database': 'connected',
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        return jsonify({
            'status': 'not ready',
            'database': 'disconnected',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 503

# Metrics endpoint
@app.route('/api/metrics')
def metrics():
    """Application metrics"""
    try:
        user_count = User.query.count()
        task_count = Task.query.count()
        completed_tasks = Task.query.filter_by(completed=True).count()
        
        return jsonify({
            'users': {
                'total': user_count,
                'active': User.query.filter_by(is_active=True).count()
            },
            'tasks': {
                'total': task_count,
                'completed': completed_tasks,
                'pending': task_count - completed_tasks
            },
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        logger.error(f"Metrics endpoint failed: {e}")
        return jsonify({'error': 'Failed to retrieve metrics'}), 500

# Authentication routes
@app.route('/api/auth/register', methods=['POST'])
def register():
    """User registration"""
    try:
        data = request.get_json()
        
        # Validation
        if not data or not data.get('username') or not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Username, email, and password are required'}), 400
        
        # Check if user exists
        if User.query.filter_by(username=data['username']).first():
            return jsonify({'error': 'Username already exists'}), 409
        
        if User.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Email already exists'}), 409
        
        # Create user
        user = User(
            username=data['username'],
            email=data['email']
        )
        user.set_password(data['password'])
        
        db.session.add(user)
        db.session.commit()
        
        logger.info(f"New user registered: {user.username}")
        
        return jsonify({
            'message': 'User created successfully',
            'user': user.to_dict(),
            'token': user.generate_token()
        }), 201
        
    except Exception as e:
        logger.error(f"Registration failed: {e}")
        db.session.rollback()
        return jsonify({'error': 'Registration failed'}), 500

@app.route('/api/auth/login', methods=['POST'])
def login():
    """User login"""
    try:
        data = request.get_json()
        
        if not data or not data.get('username') or not data.get('password'):
            return jsonify({'error': 'Username and password are required'}), 400
        
        user = User.query.filter_by(username=data['username']).first()
        
        if not user or not user.check_password(data['password']):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        if not user.is_active:
            return jsonify({'error': 'Account is disabled'}), 401
        
        logger.info(f"User logged in: {user.username}")
        
        return jsonify({
            'message': 'Login successful',
            'user': user.to_dict(),
            'token': user.generate_token()
        })
        
    except Exception as e:
        logger.error(f"Login failed: {e}")
        return jsonify({'error': 'Login failed'}), 500

@app.route('/api/auth/profile', methods=['GET'])
@token_required
def get_profile():
    """Get user profile"""
    return jsonify({
        'user': g.current_user.to_dict()
    })

# Task CRUD routes
@app.route('/api/tasks', methods=['GET'])
@token_required
def get_tasks():
    """Get all tasks for current user"""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        completed = request.args.get('completed')
        priority = request.args.get('priority')
        
        query = Task.query.filter_by(user_id=g.current_user.id)
        
        # Apply filters
        if completed is not None:
            query = query.filter_by(completed=completed.lower() == 'true')
        
        if priority:
            query = query.filter_by(priority=priority)
        
        # Order by creation date (newest first)
        query = query.order_by(Task.created_at.desc())
        
        # Paginate
        tasks = query.paginate(page=page, per_page=per_page, error_out=False)
        
        return jsonify({
            'tasks': [task.to_dict() for task in tasks.items],
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': tasks.total,
                'pages': tasks.pages,
                'has_next': tasks.has_next,
                'has_prev': tasks.has_prev
            }
        })
        
    except Exception as e:
        logger.error(f"Get tasks failed: {e}")
        return jsonify({'error': 'Failed to retrieve tasks'}), 500

@app.route('/api/tasks', methods=['POST'])
@token_required
def create_task():
    """Create new task"""
    try:
        data = request.get_json()
        
        if not data or not data.get('title'):
            return jsonify({'error': 'Title is required'}), 400
        
        # Parse due_date if provided
        due_date = None
        if data.get('due_date'):
            try:
                due_date = datetime.fromisoformat(data['due_date'].replace('Z', '+00:00'))
            except ValueError:
                return jsonify({'error': 'Invalid due_date format'}), 400
        
        task = Task(
            title=data['title'],
            description=data.get('description', ''),
            priority=data.get('priority', 'medium'),
            due_date=due_date,
            user_id=g.current_user.id
        )
        
        db.session.add(task)
        db.session.commit()
        
        logger.info(f"Task created: {task.title} by {g.current_user.username}")
        
        return jsonify({
            'message': 'Task created successfully',
            'task': task.to_dict()
        }), 201
        
    except Exception as e:
        logger.error(f"Create task failed: {e}")
        db.session.rollback()
        return jsonify({'error': 'Failed to create task'}), 500

@app.route('/api/tasks/<int:task_id>', methods=['GET'])
@token_required
def get_task(task_id):
    """Get specific task"""
    task = Task.query.filter_by(id=task_id, user_id=g.current_user.id).first()
    
    if not task:
        return jsonify({'error': 'Task not found'}), 404
    
    return jsonify({'task': task.to_dict()})

@app.route('/api/tasks/<int:task_id>', methods=['PUT'])
@token_required
def update_task(task_id):
    """Update task"""
    try:
        task = Task.query.filter_by(id=task_id, user_id=g.current_user.id).first()
        
        if not task:
            return jsonify({'error': 'Task not found'}), 404
        
        data = request.get_json()
        
        # Update fields
        if 'title' in data:
            task.title = data['title']
        if 'description' in data:
            task.description = data['description']
        if 'completed' in data:
            task.completed = data['completed']
        if 'priority' in data:
            task.priority = data['priority']
        if 'due_date' in data:
            if data['due_date']:
                try:
                    task.due_date = datetime.fromisoformat(data['due_date'].replace('Z', '+00:00'))
                except ValueError:
                    return jsonify({'error': 'Invalid due_date format'}), 400
            else:
                task.due_date = None
        
        task.updated_at = datetime.utcnow()
        db.session.commit()
        
        logger.info(f"Task updated: {task.title} by {g.current_user.username}")
        
        return jsonify({
            'message': 'Task updated successfully',
            'task': task.to_dict()
        })
        
    except Exception as e:
        logger.error(f"Update task failed: {e}")
        db.session.rollback()
        return jsonify({'error': 'Failed to update task'}), 500

@app.route('/api/tasks/<int:task_id>', methods=['DELETE'])
@token_required
def delete_task(task_id):
    """Delete task"""
    try:
        task = Task.query.filter_by(id=task_id, user_id=g.current_user.id).first()
        
        if not task:
            return jsonify({'error': 'Task not found'}), 404
        
        db.session.delete(task)
        db.session.commit()
        
        logger.info(f"Task deleted: {task.title} by {g.current_user.username}")
        
        return jsonify({'message': 'Task deleted successfully'})
        
    except Exception as e:
        logger.error(f"Delete task failed: {e}")
        db.session.rollback()
        return jsonify({'error': 'Failed to delete task'}), 500

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return jsonify({'error': 'Internal server error'}), 500

# Initialize database
@app.before_first_request
def create_tables():
    """Create database tables"""
    db.create_all()
    
    # Create default admin user if none exists
    if not User.query.first():
        admin = User(
            username='admin',
            email='admin@example.com'
        )
        admin.set_password('admin123')
        db.session.add(admin)
        db.session.commit()
        logger.info("Default admin user created (admin/admin123)")

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_ENV') == 'development'
    
    logger.info(f"Starting Flask app on port {port}, debug={debug}")
    app.run(host='0.0.0.0', port=port, debug=debug)