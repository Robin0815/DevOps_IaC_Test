from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
import json

def extract_data():
    """Simulate data extraction"""
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

def transform_data(**context):
    """Transform the extracted data"""
    data = context['task_instance'].xcom_pull(task_ids='extract')
    
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

def load_data(**context):
    """Load the transformed data"""
    data = context['task_instance'].xcom_pull(task_ids='transform')
    
    # Simulate saving to database
    print("Loading data to database:")
    for record in data['records']:
        print(f"  ID: {record['id']}, Name: {record['name']}, Score: {record['score']}, Grade: {record['grade']}")
    
    return f"Successfully loaded {len(data['records'])} records"

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'data_processing_workflow',
    default_args=default_args,
    description='ETL workflow for data processing',
    schedule_interval=timedelta(hours=1),  # Run every hour
    catchup=False,
    tags=['etl', 'data-processing'],
)

# Task 1: Extract data
extract_task = PythonOperator(
    task_id='extract',
    python_callable=extract_data,
    dag=dag,
)

# Task 2: Transform data
transform_task = PythonOperator(
    task_id='transform',
    python_callable=transform_data,
    dag=dag,
)

# Task 3: Validate data
validate_task = BashOperator(
    task_id='validate',
    bash_command='echo "Data validation completed successfully"',
    dag=dag,
)

# Task 4: Load data
load_task = PythonOperator(
    task_id='load',
    python_callable=load_data,
    dag=dag,
)

# Task 5: Cleanup
cleanup_task = BashOperator(
    task_id='cleanup',
    bash_command='echo "Cleaning up temporary files..." && sleep 2 && echo "Cleanup completed"',
    dag=dag,
)

# Define task dependencies
extract_task >> transform_task >> validate_task >> load_task >> cleanup_task