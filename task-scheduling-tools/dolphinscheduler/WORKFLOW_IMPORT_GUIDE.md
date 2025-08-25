# 🐬 DolphinScheduler Workflow Import Guide

This guide explains how to import and use the example workflows provided in the `flows/` directory.

## 📁 **Available Example Workflows**

### **1. Simple Data Processing** (`simple_data_processing.json`)
- **Purpose**: Basic ETL pipeline demonstration
- **Complexity**: Beginner
- **Tasks**: 5 sequential tasks
- **Features**: Parameter passing, error handling, shell scripts

### **2. Advanced ETL Pipeline** (`advanced_etl_pipeline.json`)
- **Purpose**: Complex multi-source data processing
- **Complexity**: Advanced
- **Tasks**: 11 tasks with parallel execution
- **Features**: Parallel extraction, quality gates, aggregations

### **3. Conditional Workflow** (`conditional_workflow.json`)
- **Purpose**: Conditional logic and branching
- **Complexity**: Expert
- **Tasks**: 9 tasks with conditional paths
- **Features**: Dynamic routing, parallel branches, error recovery

## 🚀 **Import Process**

### **Method 1: Manual Import via UI**

#### **Step 1: Access DolphinScheduler**
```bash
# Start DolphinScheduler
./start.sh

# Access UI at: http://localhost:12346
# Login: admin / dolphinscheduler123
```

#### **Step 2: Create Project**
1. Navigate to **Project Management**
2. Click **Create Project**
3. Enter project details:
   - **Project Name**: `Example Workflows`
   - **Description**: `Imported example workflows`
4. Click **Submit**

#### **Step 3: Import Workflow**
1. Enter your project
2. Go to **Workflow Definition**
3. Click **Import Workflow**
4. Select JSON file from `flows/` directory
5. Configure import settings:
   - **Workflow Name**: Keep or modify
   - **Description**: Add custom description
   - **Global Parameters**: Review and adjust
6. Click **Import**

#### **Step 4: Configure Workflow**
1. Open the imported workflow
2. Review task configurations
3. Adjust parameters if needed:
   - **Worker Groups**: Set to `default`
   - **Environment**: Configure as needed
   - **Timeouts**: Adjust based on your environment
4. **Save** the workflow

### **Method 2: Programmatic Import via API**

#### **Using curl**
```bash
# Get authentication token
TOKEN=$(curl -X POST "http://localhost:12345/dolphinscheduler/login" \
  -H "Content-Type: application/json" \
  -d '{"userName":"admin","userPassword":"dolphinscheduler123"}' \
  | jq -r '.data.token')

# Import workflow
curl -X POST "http://localhost:12345/dolphinscheduler/projects/1/process/import-definition" \
  -H "token: $TOKEN" \
  -F "file=@flows/simple_data_processing.json"
```

#### **Using Python**
```python
import requests
import json

# Login and get token
login_response = requests.post(
    "http://localhost:12345/dolphinscheduler/login",
    json={"userName": "admin", "userPassword": "dolphinscheduler123"}
)
token = login_response.json()["data"]["token"]

# Import workflow
with open("flows/simple_data_processing.json", "rb") as f:
    response = requests.post(
        "http://localhost:12345/dolphinscheduler/projects/1/process/import-definition",
        headers={"token": token},
        files={"file": f}
    )
print(response.json())
```

## ⚙️ **Configuration Guide**

### **Global Parameters**
Each workflow includes configurable global parameters:

#### **Simple Data Processing**
```json
{
  "input_path": "/tmp/input",      # Data input directory
  "output_path": "/tmp/output"     # Data output directory
}
```

#### **Advanced ETL Pipeline**
```json
{
  "source_database": "production_db",      # Source database name
  "target_warehouse": "analytics_warehouse", # Target warehouse
  "batch_size": "1000",                    # Processing batch size
  "environment": "production"              # Environment setting
}
```

#### **Conditional Workflow**
```json
{
  "data_source": "api",           # Data source type (api/database/file)
  "processing_mode": "batch",     # Processing mode (batch/stream)
  "quality_threshold": "0.8"      # Data quality threshold
}
```

### **Task Configuration**
Review and adjust these settings for each task:

#### **Retry Settings**
```json
{
  "failRetryTimes": 2,      # Number of retry attempts
  "failRetryInterval": 1    # Retry interval in minutes
}
```

#### **Timeout Settings**
```json
{
  "timeoutFlag": "OPEN",           # Enable timeout
  "timeout": 600,                  # Timeout in seconds
  "timeoutNotifyStrategy": "WARN"  # Notification strategy
}
```

#### **Priority Settings**
```json
{
  "taskPriority": "MEDIUM",  # Task priority (HIGH/MEDIUM/LOW)
  "workerGroup": "default"   # Worker group assignment
}
```

## 🔧 **Customization Guide**

### **Modifying Shell Scripts**
Each workflow uses shell scripts that can be customized:

#### **Example: Data Extraction Task**
```bash
#!/bin/bash
echo "🔍 Starting data extraction..."

# Customize data source
DATA_SOURCE="${input_path}/source_data.csv"

# Add your extraction logic here
# Example: Connect to database, API, or file system
mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASS} \
  -e "SELECT * FROM customers" > ${DATA_SOURCE}

echo "✅ Data extraction completed"
```

### **Adding New Tasks**
To add custom tasks to existing workflows:

1. **Open Workflow Editor**
2. **Drag New Task** from toolbar
3. **Configure Task Properties**:
   - **Task Name**: Descriptive name
   - **Task Type**: Shell, SQL, Python, etc.
   - **Script Content**: Your custom logic
   - **Dependencies**: Connect to other tasks
4. **Save Workflow**

### **Environment-Specific Configuration**

#### **Development Environment**
```json
{
  "environment": "development",
  "batch_size": "100",
  "timeout": 300,
  "failRetryTimes": 1
}
```

#### **Production Environment**
```json
{
  "environment": "production",
  "batch_size": "5000",
  "timeout": 1800,
  "failRetryTimes": 3
}
```

## 🚀 **Running Workflows**

### **Manual Execution**
1. **Navigate to Workflow Definition**
2. **Select Workflow**
3. **Click "Run"**
4. **Configure Run Parameters**:
   - **Execution Date**: Set execution date
   - **Parameters**: Override global parameters
   - **Worker Group**: Select worker group
5. **Submit Execution**

### **Scheduled Execution**
1. **Open Workflow**
2. **Go to "Schedule"**
3. **Configure Schedule**:
   - **Cron Expression**: `0 2 * * *` (daily at 2 AM)
   - **Start Date**: Schedule start date
   - **End Date**: Schedule end date
   - **Timezone**: Set appropriate timezone
4. **Enable Schedule**

### **API Execution**
```bash
# Execute workflow via API
curl -X POST "http://localhost:12345/dolphinscheduler/projects/1/executors/start-process-instance" \
  -H "token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "processDefinitionId": 1,
    "scheduleTime": "2024-01-01 00:00:00",
    "failureStrategy": "CONTINUE",
    "warningType": "NONE"
  }'
```

## 📊 **Monitoring Execution**

### **Real-time Monitoring**
1. **Go to Workflow Instance**
2. **Select Running Instance**
3. **View DAG Status**:
   - **Green**: Completed successfully
   - **Red**: Failed
   - **Blue**: Running
   - **Gray**: Waiting

### **Log Analysis**
1. **Click on Task Node**
2. **View Task Details**
3. **Check Logs**:
   - **Execution Logs**: Task output
   - **Error Logs**: Failure details
   - **System Logs**: System messages

### **Performance Metrics**
- **Execution Time**: Task and workflow duration
- **Success Rate**: Historical success percentage
- **Resource Usage**: CPU and memory consumption
- **Queue Time**: Time waiting in queue

## 🛠️ **Troubleshooting**

### **Common Import Issues**

#### **JSON Format Errors**
```bash
# Validate JSON format
cat flows/simple_data_processing.json | jq .
```

#### **Parameter Validation**
- Check parameter types (VARCHAR, INTEGER, DOUBLE)
- Verify parameter names don't contain special characters
- Ensure required parameters are provided

#### **Task Configuration Issues**
- Verify worker group exists
- Check timeout values are reasonable
- Ensure retry settings are appropriate

### **Execution Issues**

#### **Task Failures**
1. **Check Task Logs** for error details
2. **Verify Parameters** are correctly set
3. **Test Scripts Manually** in shell environment
4. **Check Resource Availability** (CPU, memory, disk)

#### **Dependency Issues**
1. **Review Task Dependencies** in DAG view
2. **Check Prerequisite Tasks** completed successfully
3. **Verify Conditional Logic** is correct
4. **Test with Simplified Workflow** first

## 📚 **Best Practices**

### **Workflow Design**
1. **Start Simple** - Begin with basic workflows
2. **Test Incrementally** - Add complexity gradually
3. **Use Parameters** - Make workflows configurable
4. **Document Tasks** - Add clear descriptions
5. **Handle Errors** - Include failure scenarios

### **Performance Optimization**
1. **Optimize Scripts** - Efficient shell/SQL scripts
2. **Right-size Timeouts** - Appropriate timeout values
3. **Use Parallel Tasks** - Leverage parallel execution
4. **Monitor Resources** - Track CPU and memory usage
5. **Clean Up Data** - Remove temporary files

### **Maintenance**
1. **Version Control** - Export workflows regularly
2. **Backup Configurations** - Save parameter settings
3. **Monitor Execution** - Regular health checks
4. **Update Dependencies** - Keep scripts current
5. **Review Logs** - Regular log analysis

## 🎉 **Next Steps**

After importing and running the example workflows:

1. **Explore the UI** - Familiarize yourself with all features
2. **Create Custom Workflows** - Build your own workflows
3. **Set Up Monitoring** - Configure alerts and notifications
4. **Integrate Systems** - Connect to your data sources
5. **Scale Up** - Add more workers and resources

---

**🚀 Happy workflow orchestration!** The example workflows provide a solid foundation for building your own complex data processing pipelines.