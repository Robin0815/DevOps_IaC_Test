#!/usr/bin/env python3

from prefect import flow, task, get_run_logger
from prefect.client.orchestration import PrefectClient
from prefect.client.schemas import FlowRun
from prefect.states import Completed, Failed, Running
from datetime import datetime, timedelta
import asyncio
import time
import json

@task
async def wait_for_flow_completion(flow_name: str, timeout_minutes: int = 30):
    """
    Wait for a specific flow to complete successfully
    This demonstrates how to check flow run states
    """
    logger = get_run_logger()
    logger.info(f"Waiting for flow '{flow_name}' to complete...")
    
    async with PrefectClient() as client:
        timeout = datetime.now() + timedelta(minutes=timeout_minutes)
        
        while datetime.now() < timeout:
            # Get recent flow runs for the specified flow
            flow_runs = await client.read_flow_runs(
                flow_filter={"name": {"any_": [flow_name]}},
                limit=5,
                sort="EXPECTED_START_TIME_DESC"
            )
            
            if flow_runs:
                latest_run = flow_runs[0]
                logger.info(f"Latest run state: {latest_run.state.type}")
                
                if latest_run.state.is_completed():
                    logger.info(f"Flow '{flow_name}' completed successfully!")
                    return {
                        'flow_name': flow_name,
                        'run_id': str(latest_run.id),
                        'state': latest_run.state.type.value,
                        'completion_time': latest_run.end_time.isoformat() if latest_run.end_time else None
                    }
                elif latest_run.state.is_failed():
                    raise Exception(f"Flow '{flow_name}' failed!")
            
            # Wait before checking again
            await asyncio.sleep(10)
        
        raise TimeoutError(f"Timeout waiting for flow '{flow_name}' to complete")

@task
async def trigger_flow_run(flow_name: str, parameters: dict = None):
    """
    Trigger a flow run programmatically
    """
    logger = get_run_logger()
    logger.info(f"Triggering flow run for '{flow_name}'")
    
    async with PrefectClient() as client:
        # Find the flow
        flows = await client.read_flows(flow_filter={"name": {"any_": [flow_name]}})
        
        if not flows:
            raise ValueError(f"Flow '{flow_name}' not found")
        
        flow = flows[0]
        
        # Create a flow run
        flow_run = await client.create_flow_run(
            flow=flow,
            parameters=parameters or {}
        )
        
        logger.info(f"Created flow run: {flow_run.id}")
        return {
            'flow_name': flow_name,
            'run_id': str(flow_run.id),
            'parameters': parameters or {}
        }

@task
def process_conditional_logic(upstream_results: list):
    """
    Process conditional logic based on upstream flow results
    """
    logger = get_run_logger()
    logger.info("Processing conditional logic...")
    
    successful_flows = [
        result for result in upstream_results 
        if result.get('state') == 'COMPLETED'
    ]
    
    failed_flows = [
        result for result in upstream_results 
        if result.get('state') == 'FAILED'
    ]
    
    logic_result = {
        'total_flows': len(upstream_results),
        'successful_flows': len(successful_flows),
        'failed_flows': len(failed_flows),
        'success_rate': len(successful_flows) / len(upstream_results) if upstream_results else 0,
        'should_proceed': len(successful_flows) >= len(upstream_results) * 0.8  # 80% success rate
    }
    
    logger.info(f"Conditional logic result: {logic_result}")
    return logic_result

@flow(name="Advanced Flow Dependencies", log_prints=True)
async def advanced_dependencies_flow():
    """
    Demonstrates advanced flow dependencies with state checking and conditional logic
    """
    logger = get_run_logger()
    logger.info("Starting Advanced Flow Dependencies")
    
    # Define prerequisite flows
    prerequisite_flows = [
        "Data Processing Workflow",
        "Upstream Data Preparation"
    ]
    
    # Wait for all prerequisite flows to complete
    logger.info("Waiting for prerequisite flows...")
    prerequisite_results = []
    
    for flow_name in prerequisite_flows:
        try:
            result = await wait_for_flow_completion(flow_name, timeout_minutes=5)
            prerequisite_results.append(result)
        except Exception as e:
            logger.warning(f"Flow '{flow_name}' failed or timed out: {e}")
            prerequisite_results.append({
                'flow_name': flow_name,
                'state': 'FAILED',
                'error': str(e)
            })
    
    # Process conditional logic
    logic_result = process_conditional_logic(prerequisite_results)
    
    if logic_result['should_proceed']:
        logger.info("Conditions met - proceeding with dependent processing")
        
        # Trigger dependent flow
        dependent_trigger = await trigger_flow_run(
            "Downstream Data Processing",
            parameters={'triggered_by': 'advanced_dependencies_flow'}
        )
        
        # Wait for dependent flow to complete
        dependent_result = await wait_for_flow_completion(
            "Downstream Data Processing", 
            timeout_minutes=10
        )
        
        final_result = {
            'status': 'success',
            'prerequisite_results': prerequisite_results,
            'logic_result': logic_result,
            'dependent_trigger': dependent_trigger,
            'dependent_result': dependent_result,
            'completion_time': datetime.now().isoformat()
        }
    else:
        logger.warning("Conditions not met - skipping dependent processing")
        final_result = {
            'status': 'skipped',
            'reason': 'prerequisite_conditions_not_met',
            'prerequisite_results': prerequisite_results,
            'logic_result': logic_result,
            'completion_time': datetime.now().isoformat()
        }
    
    logger.info("Advanced dependencies flow completed!")
    return final_result

if __name__ == "__main__":
    # Note: This needs to be run in an async context
    import asyncio
    result = asyncio.run(advanced_dependencies_flow())
    print(f"Final result: {json.dumps(result, indent=2)}")