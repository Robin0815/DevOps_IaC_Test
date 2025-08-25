#!/usr/bin/env python3

from prefect import flow, task
from prefect.client.schemas import FlowRun
from prefect.states import Completed, Failed
from datetime import datetime, timedelta
import time
import json

@task(retries=2, retry_delay_seconds=10)
def wait_for_upstream(upstream_batch_id=None, timeout_minutes=10):
    """Wait for upstream flow to complete"""
    print(f"Waiting for upstream flow completion (batch: {upstream_batch_id})")
    
    # In a real scenario, you would check the Prefect API for flow run status
    # For demo purposes, we'll simulate the wait
    wait_time = 5  # seconds
    print(f"Simulating wait for upstream completion... ({wait_time}s)")
    time.sleep(wait_time)
    
    # Simulate successful upstream completion
    upstream_result = {
        'batch_id': upstream_batch_id or f"upstream_batch_{int(time.time())}",
        'status': 'completed',
        'completion_time': datetime.now().isoformat()
    }
    
    print(f"Upstream flow completed: {upstream_result}")
    return upstream_result

@task(retries=2, retry_delay_seconds=10)
def process_downstream_data(upstream_result):
    """Process data from upstream flow"""
    print(f"Processing downstream data for batch: {upstream_result['batch_id']}")
    time.sleep(3)
    
    processed_data = {
        'downstream_batch_id': f"downstream_{upstream_result['batch_id']}",
        'upstream_batch_id': upstream_result['batch_id'],
        'processing_time': datetime.now().isoformat(),
        'records_processed': 1000,
        'status': 'processed'
    }
    
    print(f"Downstream processing completed: {processed_data['downstream_batch_id']}")
    return processed_data

@task(retries=2, retry_delay_seconds=10)
def finalize_processing(processed_data):
    """Finalize the downstream processing"""
    print("Finalizing downstream processing...")
    time.sleep(2)
    
    final_result = {
        'final_batch_id': processed_data['downstream_batch_id'],
        'total_records': processed_data['records_processed'],
        'finalization_time': datetime.now().isoformat(),
        'status': 'finalized'
    }
    
    print(f"Processing finalized: {final_result}")
    return final_result

@flow(name="Downstream Data Processing", log_prints=True)
def downstream_flow(upstream_batch_id=None):
    """
    Downstream flow that waits for upstream completion and processes the data
    """
    print("Starting Downstream Data Processing Flow")
    
    # Wait for upstream flow to complete
    upstream_result = wait_for_upstream(upstream_batch_id)
    
    # Process the downstream data
    processed_data = process_downstream_data(upstream_result)
    
    # Finalize processing
    final_result = finalize_processing(processed_data)
    
    print("Downstream flow completed successfully!")
    return {
        'status': 'success',
        'upstream_batch': upstream_result['batch_id'],
        'downstream_batch': final_result['final_batch_id'],
        'total_records': final_result['total_records']
    }

if __name__ == "__main__":
    result = downstream_flow()
    print(f"Final result: {result}")