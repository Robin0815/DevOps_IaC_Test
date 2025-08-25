pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target environment'
        )
        string(
            name: 'BATCH_SIZE',
            defaultValue: '100',
            description: 'Number of records to process'
        )
    }
    
    environment {
        TIMESTAMP = sh(script: 'date +%Y%m%d_%H%M%S', returnStdout: true).trim()
        WORKSPACE_DIR = "${WORKSPACE}"
    }
    
    stages {
        stage('Setup') {
            steps {
                echo "Setting up Data Processing Pipeline"
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Batch Size: ${params.BATCH_SIZE}"
                echo "Timestamp: ${env.TIMESTAMP}"
                
                // Create working directory
                sh '''
                    mkdir -p data/input data/output data/temp
                    echo "Workspace prepared"
                '''
            }
        }
        
        stage('Extract Data') {
            steps {
                echo "Starting data extraction..."
                sh '''
                    echo "Extracting data from source..."
                    cat > data/input/sample_data.json << 'EOF'
{
  "timestamp": "$(date -Iseconds)",
  "records": [
    {"id": 1, "name": "Alice", "score": 85},
    {"id": 2, "name": "Bob", "score": 92},
    {"id": 3, "name": "Charlie", "score": 78},
    {"id": 4, "name": "Diana", "score": 95},
    {"id": 5, "name": "Eve", "score": 88}
  ]
}
EOF
                    echo "Data extraction completed"
                    ls -la data/input/
                '''
            }
        }
        
        stage('Transform Data') {
            steps {
                echo "Starting data transformation..."
                sh '''
                    echo "Transforming data..."
                    # Simulate data transformation
                    python3 -c "
import json
import sys

# Read input data
with open('data/input/sample_data.json', 'r') as f:
    data = json.load(f)

# Transform data - add grades
for record in data['records']:
    score = record['score']
    if score >= 90:
        record['grade'] = 'A'
    elif score >= 80:
        record['grade'] = 'B'
    elif score >= 70:
        record['grade'] = 'C'
    else:
        record['grade'] = 'F'

# Save transformed data
with open('data/temp/transformed_data.json', 'w') as f:
    json.dump(data, f, indent=2)

print(f'Transformed {len(data[\"records\"])} records')
"
                    echo "Data transformation completed"
                '''
            }
        }
        
        stage('Validate Data') {
            steps {
                echo "Starting data validation..."
                sh '''
                    echo "Validating transformed data..."
                    python3 -c "
import json

# Read transformed data
with open('data/temp/transformed_data.json', 'r') as f:
    data = json.load(f)

# Validate data
required_fields = ['id', 'name', 'score', 'grade']
valid_grades = ['A', 'B', 'C', 'D', 'F']

for record in data['records']:
    # Check required fields
    for field in required_fields:
        if field not in record:
            raise ValueError(f'Missing field {field} in record {record}')
    
    # Check grade validity
    if record['grade'] not in valid_grades:
        raise ValueError(f'Invalid grade {record[\"grade\"]} in record {record}')

print('Data validation passed')
"
                    echo "Data validation completed successfully"
                '''
            }
        }
        
        stage('Load Data') {
            steps {
                echo "Starting data loading..."
                sh '''
                    echo "Loading data to destination..."
                    # Simulate loading to database
                    python3 -c "
import json

# Read validated data
with open('data/temp/transformed_data.json', 'r') as f:
    data = json.load(f)

# Simulate database insert
print('Loading records to database:')
for record in data['records']:
    print(f'  INSERT: ID={record[\"id\"]}, Name={record[\"name\"]}, Score={record[\"score\"]}, Grade={record[\"grade\"]}')

# Save final output
with open('data/output/processed_data.json', 'w') as f:
    json.dump(data, f, indent=2)

print(f'Successfully loaded {len(data[\"records\"])} records')
"
                    echo "Data loading completed"
                '''
            }
        }
        
        stage('Cleanup') {
            steps {
                echo "Starting cleanup..."
                sh '''
                    echo "Cleaning up temporary files..."
                    rm -f data/temp/*
                    echo "Cleanup completed"
                '''
            }
        }
    }
    
    post {
        always {
            echo "Pipeline execution completed"
            // Archive artifacts
            archiveArtifacts artifacts: 'data/output/*.json', allowEmptyArchive: true
        }
        success {
            echo "✅ Data Processing Pipeline completed successfully!"
        }
        failure {
            echo "❌ Data Processing Pipeline failed!"
        }
        cleanup {
            // Clean workspace
            sh 'rm -rf data/'
        }
    }
    
    triggers {
        // Run every hour
        cron('0 * * * *')
    }
}