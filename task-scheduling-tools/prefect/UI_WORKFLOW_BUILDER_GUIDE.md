# 🔮 Prefect UI & Workflow Builder Guide

## Prefect 3.x UI Features

Prefect 3.4.14 includes a modern, comprehensive web UI with advanced workflow management capabilities.

### 🎯 **Core UI Features**

#### **1. Flow Visualization**
- **Flow Graph View**: Visual representation of task dependencies
- **Real-time Execution**: Live updates during flow runs
- **Interactive Nodes**: Click on tasks to see details, logs, and state
- **Dependency Mapping**: Clear visualization of task relationships

#### **2. Workflow Management**
- **Flow Browser**: Browse and search all registered flows
- **Run History**: Complete execution history with filtering
- **State Management**: View and manage flow/task states
- **Parameter Input**: Set flow parameters through the UI

#### **3. Monitoring & Observability**
- **Real-time Dashboard**: Live metrics and status updates
- **Log Streaming**: Real-time log viewing during execution
- **Performance Metrics**: Execution times, success rates, resource usage
- **Alert Configuration**: Set up notifications for failures/successes

## 🛠️ **Workflow Builder Capabilities**

### **Visual Flow Editor (Prefect 3.x)**
While Prefect doesn't have a traditional drag-and-drop builder like some tools, it offers:

#### **1. Code-First with Visual Feedback**
```python
from prefect import flow, task
from prefect.deployments import Deployment

@task
def extract_data():
    return {"data": "extracted"}

@task  
def transform_data(data):
    return {"transformed": data}

@task
def load_data(data):
    print(f"Loading: {data}")

@flow
def etl_pipeline():
    raw_data = extract_data()
    clean_data = transform_data(raw_data)
    load_data(clean_data)

# The UI automatically visualizes this as a graph
```

#### **2. Interactive Flow Builder Features**
- **Parameter Forms**: Auto-generated UI forms for flow parameters
- **Conditional Logic**: Visual representation of conditional branches
- **Subflow Integration**: Nested flows shown hierarchically
- **Dynamic Task Generation**: Tasks created at runtime are visualized

#### **3. Deployment Builder**
```python
# Create deployments through code or UI
deployment = Deployment.build_from_flow(
    flow=etl_pipeline,
    name="production-etl",
    schedule="0 2 * * *",  # Daily at 2 AM
    work_pool_name="default-agent-pool"
)
```

### **Advanced UI Workflow Features**

#### **1. Flow Run Management**
- **Manual Triggers**: Start flows with custom parameters
- **Scheduled Runs**: View and manage scheduled executions
- **Retry Logic**: Configure and monitor retry attempts
- **Cancellation**: Stop running flows through the UI

#### **2. Work Pool Management**
- **Worker Status**: Monitor worker health and capacity
- **Queue Management**: View and manage work queues
- **Resource Allocation**: Monitor resource usage per worker

#### **3. Block Management**
- **Configuration Blocks**: Manage secrets, connections, and configs
- **Storage Blocks**: Configure flow storage locations
- **Infrastructure Blocks**: Manage deployment infrastructure

## 🚀 **Enhanced UI Features in Prefect 3.x**

### **New in Version 3.x:**
1. **Improved Flow Graph**: Better visualization with zoom and pan
2. **Enhanced Filtering**: Advanced search and filter capabilities
3. **Real-time Updates**: WebSocket-based live updates
4. **Mobile Responsive**: Works well on tablets and mobile devices
5. **Dark Mode**: Built-in dark theme support

### **Workflow Creation Methods**

#### **1. Code-First Approach (Recommended)**
```python
@flow(name="data-pipeline", description="ETL workflow")
def data_pipeline(source: str = "database"):
    # Tasks are automatically visualized
    data = extract_task(source)
    processed = transform_task(data)
    result = load_task(processed)
    return result
```

#### **2. UI-Assisted Development**
- **Flow Templates**: Pre-built flow patterns
- **Parameter Validation**: UI validates parameter types
- **Deployment Wizard**: Step-by-step deployment creation
- **Testing Interface**: Run flows with test parameters

#### **3. API-Driven Workflows**
```python
# Create flows programmatically
from prefect.client.orchestration import PrefectClient

async def create_flow_via_api():
    async with PrefectClient() as client:
        flow_run = await client.create_flow_run_from_deployment(
            deployment_id="your-deployment-id",
            parameters={"param1": "value1"}
        )
```

## 🎨 **Visual Workflow Components**

### **Flow Graph Elements**
- **Task Nodes**: Colored by state (pending, running, completed, failed)
- **Dependency Edges**: Show data flow between tasks
- **Conditional Branches**: Visual representation of if/else logic
- **Parallel Execution**: Tasks that run concurrently are grouped

### **Interactive Features**
- **Click to Expand**: View task details, logs, and artifacts
- **Zoom and Pan**: Navigate large workflow graphs
- **State Filtering**: Show only tasks in specific states
- **Time Scrubbing**: View workflow state at different points in time

## 🔧 **Setting Up Enhanced UI Features**

### **1. Enable All UI Features**
```yaml
# In your docker-compose.yml (already updated)
environment:
  - PREFECT_UI_URL=http://127.0.0.1:4200/api
  - PREFECT_API_URL=http://127.0.0.1:4200/api
  - PREFECT_SERVER_API_HOST=0.0.0.0
  - PREFECT_UI_SERVE_BASE=/  # Serve UI at root path
```

### **2. Create Visual-Friendly Flows**
```python
from prefect import flow, task
from prefect.logging import get_run_logger

@task(name="Data Extraction", description="Extract data from source")
def extract_data(source: str):
    logger = get_run_logger()
    logger.info(f"Extracting from {source}")
    return {"records": 100, "source": source}

@task(name="Data Transformation", description="Clean and transform data")
def transform_data(raw_data: dict):
    logger = get_run_logger()
    logger.info(f"Transforming {raw_data['records']} records")
    return {"clean_records": raw_data["records"] * 0.9}

@task(name="Data Loading", description="Load data to destination")
def load_data(clean_data: dict):
    logger = get_run_logger()
    logger.info(f"Loading {clean_data['clean_records']} clean records")
    return {"status": "success", "loaded": clean_data["clean_records"]}

@flow(name="ETL Pipeline", description="Complete ETL workflow with monitoring")
def etl_workflow(source: str = "database", destination: str = "warehouse"):
    """
    A comprehensive ETL pipeline that extracts, transforms, and loads data.
    
    Args:
        source: Data source location
        destination: Data destination location
    """
    # Extract phase
    raw_data = extract_data(source)
    
    # Transform phase
    clean_data = transform_data(raw_data)
    
    # Load phase
    result = load_data(clean_data)
    
    return result
```

### **3. Access Enhanced UI**
```bash
# Start Prefect with latest version
cd prefect && ./start.sh

# Access the enhanced UI
open http://localhost:4200
```

## 📊 **UI Navigation Guide**

### **Main Sections**
1. **Flows**: Browse and manage all flows
2. **Flow Runs**: View execution history and status
3. **Deployments**: Manage scheduled and triggered deployments
4. **Work Pools**: Monitor workers and queues
5. **Blocks**: Manage configuration and secrets
6. **Notifications**: Set up alerts and webhooks

### **Flow Run Details**
- **Graph View**: Visual representation of the flow
- **Logs**: Real-time and historical logs
- **Parameters**: Input parameters and their values
- **Artifacts**: Generated files and data
- **Timeline**: Execution timeline with durations

## 🎯 **Best Practices for UI Workflows**

### **1. Descriptive Naming**
```python
@task(name="Validate Customer Data", description="Check data quality and completeness")
def validate_data(data):
    pass

@flow(name="Customer Onboarding Pipeline", description="Process new customer registrations")
def customer_onboarding():
    pass
```

### **2. Structured Logging**
```python
@task
def process_records():
    logger = get_run_logger()
    logger.info("Starting record processing", extra={"count": 1000})
    logger.info("Processing complete", extra={"processed": 950, "errors": 50})
```

### **3. Parameter Validation**
```python
from pydantic import BaseModel

class PipelineConfig(BaseModel):
    source_table: str
    batch_size: int = 1000
    max_retries: int = 3

@flow
def data_pipeline(config: PipelineConfig):
    # Parameters are validated and shown in UI forms
    pass
```

## 🚀 **Advanced Workflow Patterns**

### **1. Conditional Workflows**
```python
@flow
def conditional_pipeline(environment: str):
    if environment == "production":
        result = production_task()
    else:
        result = development_task()
    
    return result
```

### **2. Dynamic Task Generation**
```python
@flow
def dynamic_workflow(file_list: list):
    results = []
    for file in file_list:
        # Creates tasks dynamically - all shown in UI
        result = process_file.submit(file)
        results.append(result)
    
    return [r.result() for r in results]
```

### **3. Subflow Orchestration**
```python
@flow
def data_validation_subflow(data):
    return validate_schema(data)

@flow
def main_pipeline():
    data = extract_data()
    
    # Subflows are shown hierarchically in UI
    validation_result = data_validation_subflow(data)
    
    if validation_result:
        return process_data(data)
    else:
        return handle_invalid_data(data)
```

---

## 🎉 **Summary**

Prefect 3.4.14 provides:
- ✅ **Rich Visual UI** with interactive flow graphs
- ✅ **Real-time Monitoring** with live updates
- ✅ **Parameter Forms** for easy flow execution
- ✅ **Comprehensive Logging** with structured output
- ✅ **Deployment Management** through the UI
- ✅ **Mobile-Responsive** design
- ✅ **Code-First** approach with visual feedback

While not a traditional drag-and-drop builder, Prefect's UI provides excellent visualization and management capabilities for code-defined workflows!