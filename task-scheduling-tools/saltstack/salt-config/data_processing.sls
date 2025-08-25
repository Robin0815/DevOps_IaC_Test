# Data Processing Workflow State File

# Step 1: Extract Data
extract_data:
  cmd.run:
    - name: |
        echo "Starting data extraction..."
        mkdir -p /tmp/data_processing/{input,output,temp}
        cat > /tmp/data_processing/input/sample_data.json << 'EOF'
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
    - require: []

# Step 2: Transform Data
transform_data:
  cmd.run:
    - name: |
        echo "Starting data transformation..."
        python3 -c "
import json
import os

# Read input data
with open('/tmp/data_processing/input/sample_data.json', 'r') as f:
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
with open('/tmp/data_processing/temp/transformed_data.json', 'w') as f:
    json.dump(data, f, indent=2)

print(f'Transformed {len(data[\"records\"])} records')
"
        echo "Data transformation completed"
    - require:
      - cmd: extract_data

# Step 3: Validate Data
validate_data:
  cmd.run:
    - name: |
        echo "Starting data validation..."
        python3 -c "
import json

# Read transformed data
with open('/tmp/data_processing/temp/transformed_data.json', 'r') as f:
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
    - require:
      - cmd: transform_data

# Step 4: Load Data
load_data:
  cmd.run:
    - name: |
        echo "Starting data loading..."
        python3 -c "
import json

# Read validated data
with open('/tmp/data_processing/temp/transformed_data.json', 'r') as f:
    data = json.load(f)

# Simulate database insert
print('Loading records to database:')
for record in data['records']:
    print(f'  INSERT: ID={record[\"id\"]}, Name={record[\"name\"]}, Score={record[\"score\"]}, Grade={record[\"grade\"]}')

# Save final output
with open('/tmp/data_processing/output/processed_data.json', 'w') as f:
    json.dump(data, f, indent=2)

print(f'Successfully loaded {len(data[\"records\"])} records')
"
        echo "Data loading completed"
    - require:
      - cmd: validate_data

# Step 5: Cleanup
cleanup_temp_files:
  cmd.run:
    - name: |
        echo "Starting cleanup..."
        rm -f /tmp/data_processing/temp/*
        echo "Cleanup completed"
    - require:
      - cmd: load_data

# Schedule this workflow to run every hour
data_processing_schedule:
  schedule.present:
    - function: state.apply
    - job_args:
      - data_processing
    - seconds: 3600  # Run every hour
    - require:
      - cmd: cleanup_temp_files