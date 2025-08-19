#!/usr/bin/env python3
"""
Test suite for Flask backend
"""

import pytest
import json
from datetime import datetime
from app import app, db, User, Task

@pytest.fixture
def client():
    """Test client fixture"""
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.drop_all()

@pytest.fixture
def auth_headers(client):
    """Authenticated user headers fixture"""
    # Register a test user
    response = client.post('/api/auth/register', 
                          json={
                              'username': 'testuser',
                              'email': 'test@example.com',
                              'password': 'testpass123'
                          })
    
    data = json.loads(response.data)
    token = data['token']
    
    return {'Authorization': f'Bearer {token}'}

class TestHealthEndpoints:
    """Test health check endpoints"""
    
    def test_health_check(self, client):
        """Test basic health check"""
        response = client.get('/health')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['status'] == 'healthy'
        assert 'timestamp' in data
        assert data['version'] == '1.0.0'
    
    def test_readiness_check(self, client):
        """Test readiness check"""
        response = client.get('/health/ready')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['status'] == 'ready'
        assert data['database'] == 'connected'
    
    def test_metrics(self, client):
        """Test metrics endpoint"""
        response = client.get('/api/metrics')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert 'users' in data
        assert 'tasks' in data
        assert 'timestamp' in data

class TestAuthentication:
    """Test authentication endpoints"""
    
    def test_register_success(self, client):
        """Test successful user registration"""
        response = client.post('/api/auth/register',
                              json={
                                  'username': 'newuser',
                                  'email': 'new@example.com',
                                  'password': 'password123'
                              })
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['message'] == 'User created successfully'
        assert 'user' in data
        assert 'token' in data
        assert data['user']['username'] == 'newuser'
    
    def test_register_missing_fields(self, client):
        """Test registration with missing fields"""
        response = client.post('/api/auth/register',
                              json={'username': 'incomplete'})
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data
    
    def test_register_duplicate_username(self, client):
        """Test registration with duplicate username"""
        # First registration
        client.post('/api/auth/register',
                   json={
                       'username': 'duplicate',
                       'email': 'first@example.com',
                       'password': 'password123'
                   })
        
        # Second registration with same username
        response = client.post('/api/auth/register',
                              json={
                                  'username': 'duplicate',
                                  'email': 'second@example.com',
                                  'password': 'password123'
                              })
        
        assert response.status_code == 409
        data = json.loads(response.data)
        assert 'Username already exists' in data['error']
    
    def test_login_success(self, client):
        """Test successful login"""
        # Register user first
        client.post('/api/auth/register',
                   json={
                       'username': 'loginuser',
                       'email': 'login@example.com',
                       'password': 'loginpass123'
                   })
        
        # Login
        response = client.post('/api/auth/login',
                              json={
                                  'username': 'loginuser',
                                  'password': 'loginpass123'
                              })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['message'] == 'Login successful'
        assert 'user' in data
        assert 'token' in data
    
    def test_login_invalid_credentials(self, client):
        """Test login with invalid credentials"""
        response = client.post('/api/auth/login',
                              json={
                                  'username': 'nonexistent',
                                  'password': 'wrongpass'
                              })
        
        assert response.status_code == 401
        data = json.loads(response.data)
        assert 'Invalid credentials' in data['error']
    
    def test_get_profile(self, client, auth_headers):
        """Test getting user profile"""
        response = client.get('/api/auth/profile', headers=auth_headers)
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'user' in data
        assert data['user']['username'] == 'testuser'
    
    def test_get_profile_no_token(self, client):
        """Test getting profile without token"""
        response = client.get('/api/auth/profile')
        
        assert response.status_code == 401
        data = json.loads(response.data)
        assert 'Token is missing' in data['error']

class TestTasks:
    """Test task CRUD operations"""
    
    def test_create_task(self, client, auth_headers):
        """Test creating a new task"""
        response = client.post('/api/tasks',
                              headers=auth_headers,
                              json={
                                  'title': 'Test Task',
                                  'description': 'This is a test task',
                                  'priority': 'high'
                              })
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['message'] == 'Task created successfully'
        assert data['task']['title'] == 'Test Task'
        assert data['task']['priority'] == 'high'
        assert data['task']['completed'] == False
    
    def test_create_task_missing_title(self, client, auth_headers):
        """Test creating task without title"""
        response = client.post('/api/tasks',
                              headers=auth_headers,
                              json={'description': 'No title'})
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'Title is required' in data['error']
    
    def test_get_tasks(self, client, auth_headers):
        """Test getting tasks list"""
        # Create a test task first
        client.post('/api/tasks',
                   headers=auth_headers,
                   json={'title': 'Test Task 1'})
        
        response = client.get('/api/tasks', headers=auth_headers)
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'tasks' in data
        assert 'pagination' in data
        assert len(data['tasks']) == 1
        assert data['tasks'][0]['title'] == 'Test Task 1'
    
    def test_get_task_by_id(self, client, auth_headers):
        """Test getting specific task"""
        # Create a test task
        create_response = client.post('/api/tasks',
                                     headers=auth_headers,
                                     json={'title': 'Specific Task'})
        
        task_data = json.loads(create_response.data)
        task_id = task_data['task']['id']
        
        # Get the task
        response = client.get(f'/api/tasks/{task_id}', headers=auth_headers)
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['task']['title'] == 'Specific Task'
    
    def test_get_nonexistent_task(self, client, auth_headers):
        """Test getting non-existent task"""
        response = client.get('/api/tasks/999', headers=auth_headers)
        
        assert response.status_code == 404
        data = json.loads(response.data)
        assert 'Task not found' in data['error']
    
    def test_update_task(self, client, auth_headers):
        """Test updating a task"""
        # Create a test task
        create_response = client.post('/api/tasks',
                                     headers=auth_headers,
                                     json={'title': 'Original Title'})
        
        task_data = json.loads(create_response.data)
        task_id = task_data['task']['id']
        
        # Update the task
        response = client.put(f'/api/tasks/{task_id}',
                             headers=auth_headers,
                             json={
                                 'title': 'Updated Title',
                                 'completed': True,
                                 'priority': 'low'
                             })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['message'] == 'Task updated successfully'
        assert data['task']['title'] == 'Updated Title'
        assert data['task']['completed'] == True
        assert data['task']['priority'] == 'low'
    
    def test_delete_task(self, client, auth_headers):
        """Test deleting a task"""
        # Create a test task
        create_response = client.post('/api/tasks',
                                     headers=auth_headers,
                                     json={'title': 'Task to Delete'})
        
        task_data = json.loads(create_response.data)
        task_id = task_data['task']['id']
        
        # Delete the task
        response = client.delete(f'/api/tasks/{task_id}', headers=auth_headers)
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['message'] == 'Task deleted successfully'
        
        # Verify task is deleted
        get_response = client.get(f'/api/tasks/{task_id}', headers=auth_headers)
        assert get_response.status_code == 404
    
    def test_task_filtering(self, client, auth_headers):
        """Test task filtering"""
        # Create tasks with different properties
        client.post('/api/tasks',
                   headers=auth_headers,
                   json={'title': 'Completed Task', 'completed': True})
        
        client.post('/api/tasks',
                   headers=auth_headers,
                   json={'title': 'High Priority', 'priority': 'high'})
        
        # Test completed filter
        response = client.get('/api/tasks?completed=true', headers=auth_headers)
        data = json.loads(response.data)
        assert len(data['tasks']) == 1
        assert data['tasks'][0]['completed'] == True
        
        # Test priority filter
        response = client.get('/api/tasks?priority=high', headers=auth_headers)
        data = json.loads(response.data)
        assert len(data['tasks']) == 1
        assert data['tasks'][0]['priority'] == 'high'

class TestModels:
    """Test database models"""
    
    def test_user_password_hashing(self):
        """Test user password hashing"""
        with app.app_context():
            user = User(username='testuser', email='test@example.com')
            user.set_password('testpassword')
            
            assert user.password_hash != 'testpassword'
            assert user.check_password('testpassword') == True
            assert user.check_password('wrongpassword') == False
    
    def test_user_token_generation(self):
        """Test JWT token generation"""
        with app.app_context():
            db.create_all()
            
            user = User(username='tokenuser', email='token@example.com')
            user.set_password('password')
            db.session.add(user)
            db.session.commit()
            
            token = user.generate_token()
            assert token is not None
            assert isinstance(token, str)
    
    def test_task_to_dict(self):
        """Test task serialization"""
        with app.app_context():
            db.create_all()
            
            user = User(username='taskuser', email='task@example.com')
            user.set_password('password')
            db.session.add(user)
            db.session.commit()
            
            task = Task(
                title='Test Task',
                description='Test Description',
                priority='high',
                user_id=user.id
            )
            db.session.add(task)
            db.session.commit()
            
            task_dict = task.to_dict()
            assert task_dict['title'] == 'Test Task'
            assert task_dict['description'] == 'Test Description'
            assert task_dict['priority'] == 'high'
            assert task_dict['completed'] == False
            assert 'created_at' in task_dict
            assert 'updated_at' in task_dict

if __name__ == '__main__':
    pytest.main([__file__, '-v'])