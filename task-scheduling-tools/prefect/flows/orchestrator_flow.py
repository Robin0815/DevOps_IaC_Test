#!/usr/bin/env python3

from prefect import flow, task
from datetime import datetime, timedelta
import time
import json

# Import the other flows
from data_processing_flow import data_processing_workflow
from upstream_flow import upstream_flow
from downstream_flow import downstream_flow

@task
def prepare_orchestration():
    """Prepare the orchestration environment"""
    print("Preparing orchestration environment...")
    time.sleep(1)
    
    orchestration_config = {
        'orchestration_id': f"orch_{int(time.time())}",
        'start_time': datetime.now().isoformat(),
        'flows_to_execute': ['upstream', 'data_processing', 'downstream'],
        'status': 'prepared'
    }
    
    print(f"Orchestration prepared: {orchestration_config['orchestration_id']}")
    return orchestration_config

@task
def validate_orchestration_results(upstream_result, data_processing_result, downstream_result):
    """Validate all orchestration results"""
    print("Validating orchestration results...")
    
    results = {
        'upstream': upstream_result,
        'data_processing': data_processing_result,
        'downstream': downstream_result
    }
    
    # Check if all flows completed successfully
    all_successful = all(
        result.get('status') == 'success' 
        for result in results.values()
    )
    
    validation_result = {
        'all_flows_successful': all_successful,
        'validation_time': datetime.now().isoformat(),
        'individual_results': results
    }
    
    print(f"Orchestration validation: {'PASSED' if all_successful else 'FAILED'}")
    return validation_result

@flow(name="Flow Orchestrator", log_prints=True)
def orchestrator_flow():
    """
    Orchestrator flow that coordinates multiple flows as subflows
    Demonstrates flow composition and dependencies
    """
    print("Starting Flow Orchestrator")
    
    # Prepare orchestration
    config = prepare_orchestration()
    
    # Execute flows in sequence (with dependencies)
    print("Executing upstream flow...")
    upstream_result = upstream_flow()
    
    print("Executing data processing flow...")
    data_processing_result = data_processing_workflow()
    
    print("Executing downstream flow...")
    # Pass upstream batch ID to downstream flow
    upstream_batch_id = upstream_result.get('batch_id') if upstream_result.get('status') == 'success' else None
    downstream_result = downstream_flow(upstream_batch_id)
    
    # Validate all results
    validation = validate_orchestration_results(
        upstream_result, 
        data_processing_result, 
        downstream_result
    )
    
    final_result = {
        'orchestration_id': config['orchestration_id'],
        'status': 'success' if validation['all_flows_successful'] else 'partial_failure',
        'flows_executed': 3,
        'validation': validation,
        'completion_time': datetime.now().isoformat()
    }
    
    print("Flow orchestration completed!")
    return final_result

if __name__ == "__main__":
    result = orchestrator_flow()
    print(f"Final orchestration result: {json.dumps(result, indent=2)}")