#!/usr/bin/env python3

from prefect import flow, task
from prefect.client.schemas import FlowRun
from prefect.deployments import run_deployment
from datetime import datetime, timedelta
import time
import json

@task(retries=2, retry_delay_seconds=10)
def prepare_data():
    """Prepare initial data"""
    print("Preparing initial data...")
    time.sleep(3)
    
    data = {
        'batch_id': f"batch_{int(time.time())}",
        'timestamp': datetime.now().isoformat(),
        'source': 'upstream_flow',
        'records_count': 1000,
        'status': 'prepared'
    }
    
    print(f"Data prepared: {data['batch_id']}")
    return data

@task(retries=2, retry_delay_seconds=10)
def validate_preparation(data):
    """Validate the prepared data"""
    print("Validating data preparation...")
    time.sleep(2)
    
    if data['records_count'] > 0:
        print("Data preparation validation successful")
        return True
    else:
        raise ValueError("No records found in prepared data")

@task
def trigger_downstream_flow(data):
    """Trigger the downstream flow"""
    print(f"Triggering downstream flow for batch: {data['batch_id']}")
    
    # In a real scenario, you would trigger the downstream deployment
    # For demo purposes, we'll just log the trigger
    trigger_data = {
        'upstream_batch_id': data['batch_id'],
        'upstream_timestamp': data['timestamp'],
        'trigger_time': datetime.now().isoformat()
    }
    
    print(f"Downstream flow triggered with data: {trigger_data}")
    return trigger_data

@flow(name="Upstream Data Preparation", log_prints=True)
def upstream_flow():
    """
    Upstream flow that prepares data and triggers downstream processing
    """
    print("Starting Upstream Data Preparation Flow")
    
    # Prepare data
    prepared_data = prepare_data()
    
    # Validate preparation
    validation_result = validate_preparation(prepared_data)
    
    if validation_result:
        # Trigger downstream flow
        trigger_result = trigger_downstream_flow(prepared_data)
        
        print("Upstream flow completed successfully!")
        return {
            'status': 'success',
            'batch_id': prepared_data['batch_id'],
            'trigger_result': trigger_result
        }
    else:
        print("Upstream flow failed validation!")
        return {'status': 'failed', 'reason': 'validation_failed'}

if __name__ == "__main__":
    result = upstream_flow()
    print(f"Final result: {result}")