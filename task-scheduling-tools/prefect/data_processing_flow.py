from prefect import flow, task
from datetime import datetime, timedelta
import json
import time

@task(retries=2, retry_delay_seconds=30)
def extract_data():
    """Simulate data extraction"""
    print("Starting data extraction...")
    time.sleep(2)  # Simulate processing time
    
    data = {
        'timestamp': datetime.now().isoformat(),
        'records': [
            {'id': 1, 'name': 'Alice', 'score': 85},
            {'id': 2, 'name': 'Bob', 'score': 92},
            {'id': 3, 'name': 'Charlie', 'score': 78}
        ]
    }
    print(f"Extracted {len(data['records'])} records")
    return data

@task(retries=2, retry_delay_seconds=30)
def transform_data(data):
    """Transform the extracted data"""
    print("Starting data transformation...")
    time.sleep(1)  # Simulate processing time
    
    # Add grade based on score
    for record in data['records']:
        if record['score'] >= 90:
            record['grade'] = 'A'
        elif record['score'] >= 80:
            record['grade'] = 'B'
        else:
            record['grade'] = 'C'
    
    print(f"Transformed {len(data['records'])} records")
    return data

@task(retries=2, retry_delay_seconds=30)
def validate_data(data):
    """Validate the transformed data"""
    print("Starting data validation...")
    time.sleep(1)  # Simulate processing time
    
    # Simple validation
    for record in data['records']:
        if not all(key in record for key in ['id', 'name', 'score', 'grade']):
            raise ValueError(f"Invalid record: {record}")
    
    print("Data validation completed successfully")
    return True

@task(retries=2, retry_delay_seconds=30)
def load_data(data):
    """Load the transformed data"""
    print("Starting data loading...")
    time.sleep(2)  # Simulate processing time
    
    # Simulate saving to database
    print("Loading data to database:")
    for record in data['records']:
        print(f"  ID: {record['id']}, Name: {record['name']}, Score: {record['score']}, Grade: {record['grade']}")
    
    result = f"Successfully loaded {len(data['records'])} records"
    print(result)
    return result

@task
def cleanup():
    """Cleanup temporary resources"""
    print("Cleaning up temporary files...")
    time.sleep(1)  # Simulate cleanup time
    print("Cleanup completed")
    return "Cleanup successful"

@flow(name="Data Processing Workflow", log_prints=True)
def data_processing_workflow():
    """
    ETL workflow for data processing
    Runs: Extract -> Transform -> Validate -> Load -> Cleanup
    """
    print("Starting Data Processing Workflow")
    
    # Extract data
    raw_data = extract_data()
    
    # Transform data
    transformed_data = transform_data(raw_data)
    
    # Validate data
    validation_result = validate_data(transformed_data)
    
    # Load data (only if validation passes)
    if validation_result:
        load_result = load_data(transformed_data)
        
        # Cleanup
        cleanup_result = cleanup()
        
        print("Workflow completed successfully!")
        return {
            'status': 'success',
            'load_result': load_result,
            'cleanup_result': cleanup_result
        }
    else:
        print("Workflow failed validation!")
        return {'status': 'failed', 'reason': 'validation_failed'}

if __name__ == "__main__":
    # Run the flow locally
    result = data_processing_workflow()
    print(f"Final result: {result}")