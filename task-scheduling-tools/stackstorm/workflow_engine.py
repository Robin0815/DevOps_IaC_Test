#!/usr/bin/env python3

import os
import json
import yaml
import time
import logging
import threading
from datetime import datetime
from flask import Flask, render_template, request, jsonify
from pathlib import Path
import subprocess
import requests

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/workflow.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

class WorkflowEngine:
    def __init__(self):
        self.workflows = {}
        self.executions = []
        self.load_workflows()
    
    def load_workflows(self):
        """Load workflow definitions from YAML files"""
        workflows_dir = Path('/app/workflows')
        workflows_dir.mkdir(exist_ok=True)
        
        for workflow_file in workflows_dir.glob('*.yml'):
            try:
                with open(workflow_file, 'r') as f:
                    workflow_data = yaml.safe_load(f)
                    self.workflows[workflow_data['name']] = workflow_data
                    logger.info(f"Loaded workflow: {workflow_data['name']}")
            except Exception as e:
                logger.error(f"Error loading workflow {workflow_file}: {e}")
    
    def execute_workflow(self, workflow_name, parameters=None):
        """Execute a workflow"""
        if workflow_name not in self.workflows:
            raise ValueError(f"Workflow '{workflow_name}' not found")
        
        workflow = self.workflows[workflow_name]
        execution_id = f"{workflow_name}_{int(time.time())}"
        
        execution = {
            'id': execution_id,
            'workflow_name': workflow_name,
            'status': 'running',
            'start_time': datetime.now().isoformat(),
            'parameters': parameters or {},
            'steps': [],
            'logs': []
        }
        
        self.executions.append(execution)
        logger.info(f"Starting workflow execution: {execution_id}")
        
        try:
            for step in workflow.get('steps', []):
                step_result = self.execute_step(step, parameters, execution)
                execution['steps'].append(step_result)
                
                if not step_result['success']:
                    execution['status'] = 'failed'
                    execution['end_time'] = datetime.now().isoformat()
                    return execution
            
            execution['status'] = 'completed'
            execution['end_time'] = datetime.now().isoformat()
            logger.info(f"Workflow execution completed: {execution_id}")
            
        except Exception as e:
            execution['status'] = 'failed'
            execution['error'] = str(e)
            execution['end_time'] = datetime.now().isoformat()
            logger.error(f"Workflow execution failed: {execution_id} - {e}")
        
        return execution
    
    def execute_step(self, step, parameters, execution):
        """Execute a single workflow step"""
        step_name = step.get('name', 'unnamed_step')
        action = step.get('action')
        
        logger.info(f"Executing step: {step_name}")
        execution['logs'].append(f"Executing step: {step_name}")
        
        step_result = {
            'name': step_name,
            'action': action,
            'start_time': datetime.now().isoformat(),
            'success': False,
            'output': '',
            'error': ''
        }
        
        try:
            if action == 'shell':
                result = self.execute_shell_command(step.get('command', ''))
                step_result['output'] = result
                step_result['success'] = True
                
            elif action == 'http_request':
                result = self.execute_http_request(step)
                step_result['output'] = result
                step_result['success'] = True
                
            elif action == 'log':
                message = step.get('message', 'Log message')
                logger.info(f"Workflow log: {message}")
                step_result['output'] = message
                step_result['success'] = True
                
            elif action == 'delay':
                delay_seconds = step.get('seconds', 1)
                time.sleep(delay_seconds)
                step_result['output'] = f"Delayed for {delay_seconds} seconds"
                step_result['success'] = True
                
            elif action == 'wait_for_workflow':
                result = self.wait_for_workflow_completion(step)
                step_result['output'] = result
                step_result['success'] = True
                
            elif action == 'trigger_workflow':
                result = self.trigger_workflow(step)
                step_result['output'] = result
                step_result['success'] = True
                
            else:
                raise ValueError(f"Unknown action: {action}")
                
        except Exception as e:
            step_result['error'] = str(e)
            step_result['success'] = False
            logger.error(f"Step failed: {step_name} - {e}")
        
        step_result['end_time'] = datetime.now().isoformat()
        return step_result
    
    def wait_for_workflow_completion(self, step):
        """Wait for another workflow to complete successfully"""
        target_workflow = step.get('workflow_name')
        timeout_seconds = step.get('timeout', 300)  # 5 minutes default
        check_interval = step.get('check_interval', 5)  # 5 seconds default
        
        logger.info(f"Waiting for workflow '{target_workflow}' to complete successfully")
        
        start_time = time.time()
        while time.time() - start_time < timeout_seconds:
            # Check recent executions for successful completion
            recent_executions = [e for e in self.executions if e['workflow_name'] == target_workflow]
            if recent_executions:
                latest_execution = max(recent_executions, key=lambda x: x['start_time'])
                if latest_execution['status'] == 'completed':
                    return f"Workflow '{target_workflow}' completed successfully at {latest_execution['end_time']}"
                elif latest_execution['status'] == 'failed':
                    raise Exception(f"Workflow '{target_workflow}' failed")
            
            time.sleep(check_interval)
        
        raise Exception(f"Timeout waiting for workflow '{target_workflow}' to complete")
    
    def trigger_workflow(self, step):
        """Trigger another workflow execution"""
        target_workflow = step.get('workflow_name')
        parameters = step.get('parameters', {})
        
        if target_workflow not in self.workflows:
            raise ValueError(f"Target workflow '{target_workflow}' not found")
        
        # Execute workflow in background thread
        def run_target_workflow():
            self.execute_workflow(target_workflow, parameters)
        
        thread = threading.Thread(target=run_target_workflow)
        thread.start()
        
        return f"Triggered workflow '{target_workflow}' with parameters: {parameters}"
    
    def execute_shell_command(self, command):
        """Execute a shell command"""
        try:
            result = subprocess.run(
                command, 
                shell=True, 
                capture_output=True, 
                text=True, 
                timeout=30
            )
            return {
                'stdout': result.stdout,
                'stderr': result.stderr,
                'returncode': result.returncode
            }
        except subprocess.TimeoutExpired:
            raise Exception("Command timed out")
    
    def execute_http_request(self, step):
        """Execute an HTTP request"""
        url = step.get('url')
        method = step.get('method', 'GET').upper()
        headers = step.get('headers', {})
        data = step.get('data', {})
        
        response = requests.request(
            method=method,
            url=url,
            headers=headers,
            json=data if method in ['POST', 'PUT', 'PATCH'] else None,
            timeout=30
        )
        
        return {
            'status_code': response.status_code,
            'headers': dict(response.headers),
            'body': response.text[:1000]  # Limit response size
        }

# Initialize the workflow engine
engine = WorkflowEngine()

@app.route('/')
def index():
    return render_template('index.html', workflows=list(engine.workflows.keys()))

@app.route('/api/workflows')
def list_workflows():
    return jsonify(list(engine.workflows.keys()))

@app.route('/api/workflows/<workflow_name>')
def get_workflow(workflow_name):
    if workflow_name in engine.workflows:
        return jsonify(engine.workflows[workflow_name])
    return jsonify({'error': 'Workflow not found'}), 404

@app.route('/api/workflows/<workflow_name>/execute', methods=['POST'])
def execute_workflow(workflow_name):
    parameters = request.json or {}
    
    def run_workflow():
        engine.execute_workflow(workflow_name, parameters)
    
    # Run workflow in background thread
    thread = threading.Thread(target=run_workflow)
    thread.start()
    
    return jsonify({'message': f'Workflow {workflow_name} started'})

@app.route('/api/executions')
def list_executions():
    return jsonify(engine.executions[-10:])  # Return last 10 executions

@app.route('/api/executions/<execution_id>')
def get_execution(execution_id):
    for execution in engine.executions:
        if execution['id'] == execution_id:
            return jsonify(execution)
    return jsonify({'error': 'Execution not found'}), 404

def create_templates():
    """Create templates directory and basic template"""
    templates_dir = Path('/app/templates')
    templates_dir.mkdir(exist_ok=True)
    
    template_content = '''<!DOCTYPE html>
<html>
<head>
    <title>Workflow Engine Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #007cba; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .workflow { margin: 15px 0; padding: 20px; border: 1px solid #ddd; border-radius: 8px; background: #fafafa; }
        .workflow h3 { margin: 0 0 10px 0; color: #333; }
        .workflow p { margin: 5px 0; color: #666; font-size: 14px; }
        button { padding: 12px 24px; margin: 5px; background: #007cba; color: white; border: none; border-radius: 5px; cursor: pointer; font-size: 14px; }
        button:hover { background: #005a87; }
        .executions { margin-top: 40px; }
        .execution { margin: 10px 0; padding: 15px; background: #f9f9f9; border-radius: 5px; border-left: 4px solid #007cba; }
        .execution.completed { border-left-color: #28a745; }
        .execution.failed { border-left-color: #dc3545; }
        .execution.running { border-left-color: #ffc107; }
        .status { font-weight: bold; text-transform: uppercase; font-size: 12px; }
        .status.completed { color: #28a745; }
        .status.failed { color: #dc3545; }
        .status.running { color: #ffc107; }
        .api-section { margin-top: 40px; padding: 20px; background: #e9ecef; border-radius: 8px; }
        .api-endpoint { margin: 10px 0; font-family: monospace; background: #fff; padding: 8px; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔧 Workflow Engine Dashboard</h1>
        <p>A lightweight workflow automation engine for task scheduling and orchestration.</p>
        
        <h2>📋 Available Workflows</h2>
        {% for workflow in workflows %}
        <div class="workflow">
            <h3>{{ workflow }}</h3>
            <p>Click execute to run this workflow</p>
            <button onclick="executeWorkflow('{{ workflow }}')">▶️ Execute Workflow</button>
            <button onclick="viewWorkflow('{{ workflow }}')">👁️ View Definition</button>
        </div>
        {% endfor %}
        
        <div class="executions">
            <h2>📊 Recent Executions</h2>
            <div id="executions-list">Loading executions...</div>
        </div>
        
        <div class="api-section">
            <h2>🔌 API Endpoints</h2>
            <div class="api-endpoint">GET /api/workflows - List all workflows</div>
            <div class="api-endpoint">POST /api/workflows/{name}/execute - Execute a workflow</div>
            <div class="api-endpoint">GET /api/executions - List recent executions</div>
        </div>
    </div>
    
    <script>
        function executeWorkflow(workflowName) {
            if (confirm(`Execute workflow: ${workflowName}?`)) {
                fetch(`/api/workflows/${workflowName}/execute`, {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({})
                })
                .then(response => response.json())
                .then(data => {
                    alert(data.message);
                    setTimeout(loadExecutions, 1000); // Reload after 1 second
                })
                .catch(error => {
                    alert('Error executing workflow: ' + error);
                });
            }
        }
        
        function viewWorkflow(workflowName) {
            fetch(`/api/workflows/${workflowName}`)
            .then(response => response.json())
            .then(workflow => {
                alert(`Workflow: ${workflow.name}\\n\\nDescription: ${workflow.description}\\n\\nSteps: ${workflow.steps.length}`);
            })
            .catch(error => {
                alert('Error loading workflow: ' + error);
            });
        }
        
        function loadExecutions() {
            fetch('/api/executions')
            .then(response => response.json())
            .then(executions => {
                const list = document.getElementById('executions-list');
                if (executions.length === 0) {
                    list.innerHTML = '<p>No executions yet. Try running a workflow!</p>';
                } else {
                    list.innerHTML = executions.reverse().map(exec => 
                        `<div class="execution ${exec.status}">
                            <div><strong>${exec.workflow_name}</strong></div>
                            <div>Status: <span class="status ${exec.status}">${exec.status}</span></div>
                            <div>Started: ${new Date(exec.start_time).toLocaleString()}</div>
                            ${exec.end_time ? `<div>Ended: ${new Date(exec.end_time).toLocaleString()}</div>` : ''}
                            ${exec.error ? `<div style="color: red;">Error: ${exec.error}</div>` : ''}
                        </div>`
                    ).join('');
                }
            })
            .catch(error => {
                document.getElementById('executions-list').innerHTML = '<p>Error loading executions</p>';
            });
        }
        
        // Load executions on page load
        loadExecutions();
        
        // Refresh executions every 3 seconds
        setInterval(loadExecutions, 3000);
    </script>
</body>
</html>'''
    
    with open(templates_dir / 'index.html', 'w') as f:
        f.write(template_content)

if __name__ == '__main__':
    # Create necessary directories
    Path('/app/workflows').mkdir(exist_ok=True)
    Path('/app/logs').mkdir(exist_ok=True)
    Path('/app/templates').mkdir(exist_ok=True)
    
    # Create templates
    create_templates()
    
    app.run(host='0.0.0.0', port=8080, debug=True)