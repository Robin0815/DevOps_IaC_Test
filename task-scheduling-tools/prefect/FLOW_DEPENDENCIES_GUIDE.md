# Prefect Flow Dependencies Guide

This guide demonstrates various approaches to handling dependencies between flows in Prefect.

## 🔧 Dependency Patterns

### 1. **Subflows (Flow Composition)**
The simplest approach - call flows directly within other flows.

```python
from prefect import flow
from other_flow import my_other_flow

@flow
def orchestrator_flow():
    # Execute flows in sequence
    result1 = upstream_flow()
    result2 = data_processing_flow()
    result3 = downstream_flow(result1['batch_id'])
    return {'all_results': [result1, result2, result3]}
```

**Pros**: Simple, direct control, easy to debug
**Cons**: Tight coupling, runs in same process

### 2. **Deployment-Based Dependencies**
Use separate deployments with programmatic triggering.

```python
from prefect.deployments import run_deployment

@task
async def trigger_downstream():
    flow_run = await run_deployment(
        name="downstream-processing",
        parameters={"upstream_batch_id": "batch_123"}
    )
    return flow_run.id
```

**Pros**: Loose coupling, independent scaling, better observability
**Cons**: More complex setup, async handling

### 3. **State-Based Dependencies**
Monitor flow run states and react accordingly.

```python
from prefect.client.orchestration import PrefectClient

@task
async def wait_for_flow_completion(flow_name: str):
    async with PrefectClient() as client:
        # Poll for flow completion
        while True:
            runs = await client.read_flow_runs(
                flow_filter={"name": {"any_": [flow_name]}},
                limit=1
            )
            if runs and runs[0].state.is_completed():
                return runs[0]
            await asyncio.sleep(10)
```

**Pros**: Flexible, can handle complex conditions
**Cons**: Requires polling, more complex error handling

### 4. **Event-Driven Dependencies**
Use Prefect's automation and webhooks (Prefect Cloud/Server 2.0+).

```python
# Automation rule (configured in UI or API)
{
    "trigger": {
        "type": "flow-run-state-change",
        "match": {"flow.name": "upstream-flow"},
        "expect": ["Completed"]
    },
    "actions": [
        {
            "type": "run-deployment",
            "deployment_id": "downstream-deployment-id"
        }
    ]
}
```

**Pros**: True event-driven, no polling, highly scalable
**Cons**: Requires Prefect Cloud or advanced server setup

## 📋 Available Example Flows

### Core Flows
- **`data_processing_flow.py`** - Basic ETL workflow
- **`upstream_flow.py`** - Prepares data and triggers downstream
- **`downstream_flow.py`** - Waits for upstream completion
- **`orchestrator_flow.py`** - Coordinates multiple flows as subflows
- **`advanced_dependencies.py`** - State checking and conditional logic

### Deployments Created
- **`upstream-data-preparation`** - Runs every 2 hours
- **`downstream-processing`** - Triggered by upstream (no schedule)
- **`data-processing-demo`** - Runs hourly

## 🚀 Testing Dependencies

### Option 1: Run Orchestrator Flow
```bash
docker-compose exec prefect-server python /opt/prefect/flows/orchestrator_flow.py
```

### Option 2: Trigger Deployments
```bash
# Trigger upstream flow
docker-compose exec prefect-server prefect deployment run "Upstream Data Preparation/upstream-data-preparation"

# Trigger downstream flow with parameters
docker-compose exec prefect-server prefect deployment run "Downstream Data Processing/downstream-processing" --param upstream_batch_id=batch_123
```

### Option 3: Use the Demo Script
```bash
docker-compose exec prefect-server python /opt/prefect/demo_flow_dependencies.py
```

## 🎯 Best Practices

### 1. **Choose the Right Pattern**
- **Subflows**: For tightly coupled, sequential processing
- **Deployments**: For independent, scalable workflows
- **State-based**: For complex conditional logic
- **Event-driven**: For high-scale, reactive systems

### 2. **Error Handling**
```python
@task(retries=3, retry_delay_seconds=60)
async def wait_for_upstream():
    try:
        result = await check_upstream_completion()
        return result
    except TimeoutError:
        # Handle timeout gracefully
        logger.warning("Upstream flow timed out")
        raise
```

### 3. **Parameter Passing**
```python
@flow
def downstream_flow(upstream_batch_id: str = None):
    if not upstream_batch_id:
        # Get latest successful upstream run
        upstream_batch_id = get_latest_upstream_batch()
    
    return process_batch(upstream_batch_id)
```

### 4. **Monitoring and Observability**
- Use tags to group related flows
- Add meaningful descriptions to deployments
- Log key decision points and state transitions
- Use Prefect UI to visualize flow relationships

## 📊 Monitoring Dependencies

### View Flow Runs
```bash
# List recent runs
docker-compose exec prefect-server prefect flow-run ls --limit 10

# View specific flow run
docker-compose exec prefect-server prefect flow-run inspect <flow-run-id>
```

### Check Deployment Status
```bash
# List all deployments
docker-compose exec prefect-server prefect deployment ls

# View deployment details
docker-compose exec prefect-server prefect deployment inspect <deployment-name>
```

### Web UI
Access the Prefect UI at http://localhost:4200 to:
- View flow run graphs
- Monitor execution status
- Trigger manual runs
- Configure schedules

## 🔄 Advanced Patterns

### Conditional Dependencies
```python
@flow
def conditional_flow():
    upstream_results = check_multiple_upstreams()
    
    success_rate = calculate_success_rate(upstream_results)
    
    if success_rate >= 0.8:  # 80% success threshold
        return proceed_with_processing()
    else:
        return skip_processing_and_alert()
```

### Fan-out/Fan-in
```python
@flow
def fan_out_flow():
    # Trigger multiple parallel flows
    tasks = []
    for partition in data_partitions:
        task = process_partition.submit(partition)
        tasks.append(task)
    
    # Wait for all to complete
    results = [task.result() for task in tasks]
    
    # Fan-in: aggregate results
    return aggregate_results(results)
```

### Circuit Breaker Pattern
```python
@task
def circuit_breaker_check():
    failure_rate = get_recent_failure_rate()
    
    if failure_rate > 0.5:  # 50% failure rate
        raise Exception("Circuit breaker open - too many failures")
    
    return "Circuit closed - proceeding"
```

## 🎉 Summary

Prefect provides multiple powerful patterns for handling flow dependencies:

1. **Subflows** for simple composition
2. **Deployments** for scalable, independent flows  
3. **State monitoring** for complex conditions
4. **Event-driven** for reactive architectures

Choose the pattern that best fits your use case, and don't hesitate to combine approaches for complex workflows!