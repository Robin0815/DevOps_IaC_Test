# 🐬 Apache DolphinScheduler Guide

Apache DolphinScheduler is a distributed and extensible workflow scheduler platform with powerful DAG visual interfaces, dedicated to solving complex job dependencies in the data pipeline and providing various types of jobs available out of the box.

**✅ Status: Fully Working**  
**✅ Architecture: Standalone Server (1 container)**  
**✅ Platform: ARM64/AMD64 compatible**

## 🎯 **Key Features**

### **Visual Workflow Designer**
- **Drag & Drop Interface** - Create workflows visually without coding
- **Real-time DAG Visualization** - See workflow dependencies and execution status
- **Rich Task Types** - Shell, SQL, Python, Spark, Flink, HTTP, and more
- **Conditional Logic** - Support for complex branching and decision making

### **Enterprise-Grade Capabilities**
- **Multi-tenancy** - Project-based isolation and user management
- **High Availability** - Master-worker architecture with failover
- **Scalability** - Horizontal scaling of workers and masters
- **Resource Management** - CPU, memory, and worker group allocation

### **Advanced Scheduling**
- **Cron Scheduling** - Flexible time-based scheduling
- **Dependency Management** - Complex inter-workflow dependencies
- **Backfill Support** - Historical data processing
- **Priority Queues** - Task prioritization and resource allocation

## 🚀 **Getting Started**

### **1. Start DolphinScheduler**
```bash
cd dolphinscheduler
./start.sh
```

### **2. Access the Web UI**
- **URL**: http://localhost:12346
- **Username**: `admin`
- **Password**: `dolphinscheduler123`

### **3. Initial Setup**
1. **Create a Tenant** - Go to Security → Tenant Management
2. **Create a Project** - Go to Project Management → Create Project
3. **Import Example Workflows** - Use the provided JSON files

## 📊 **Architecture Overview**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web UI        │    │   API Server    │    │   Alert Server  │
│   (Port 12346)  │    │   (Port 12345)  │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Master Node   │    │   Worker Node   │    │   PostgreSQL    │
│                 │    │                 │    │   Database      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   ZooKeeper     │
                    │   (Registry)    │
                    └─────────────────┘
```

### **Component Roles**
- **Web UI** - Visual workflow designer and monitoring interface
- **API Server** - RESTful API for workflow management
- **Master Node** - Workflow scheduling and coordination
- **Worker Node** - Task execution engine
- **Alert Server** - Notification and alerting system
- **PostgreSQL** - Metadata and workflow definition storage
- **ZooKeeper** - Service discovery and coordination

## 🎨 **Visual Workflow Builder**

### **Creating Workflows**
1. **Navigate to Project** → Select your project
2. **Workflow Definition** → Create new workflow
3. **Drag & Drop Tasks** → Add tasks from the toolbar
4. **Connect Tasks** → Draw dependencies between tasks
5. **Configure Parameters** → Set task properties and global parameters
6. **Save & Run** → Save workflow and execute

### **Task Types Available**
- **🐚 Shell** - Execute shell scripts and commands
- **🗄️ SQL** - Database queries and operations
- **🐍 Python** - Python script execution
- **⚡ Spark** - Apache Spark jobs
- **🌊 Flink** - Apache Flink streaming jobs
- **🌐 HTTP** - REST API calls and web requests
- **📁 DataX** - Data synchronization tasks
- **🔄 Sub Process** - Nested workflow execution
- **⏰ Dependent** - Wait for external conditions
- **🔀 Conditions** - Conditional branching logic

## 📋 **Example Workflows**

### **1. Simple Data Processing**
**File**: `flows/simple_data_processing.json`

A basic ETL pipeline demonstrating:
- Sequential task execution
- Parameter passing between tasks
- Error handling and retries
- Shell script task types

**Workflow Steps**:
1. **Data Extraction** → Extract data from source
2. **Data Validation** → Validate data quality
3. **Data Transformation** → Clean and transform data
4. **Data Loading** → Load to destination
5. **Generate Report** → Create summary report

### **2. Advanced ETL Pipeline**
**File**: `flows/advanced_etl_pipeline.json`

A complex ETL workflow featuring:
- Parallel data extraction from multiple sources
- Data quality checks with failure handling
- Conditional processing based on data quality
- Customer data aggregation and analytics
- Comprehensive error handling and notifications

**Workflow Features**:
- **Parallel Extraction** - Customer, Order, and Product data
- **Quality Gates** - Data validation with configurable thresholds
- **Transformation Pipeline** - Multi-stage data processing
- **Aggregation Logic** - Customer summary generation
- **Warehouse Loading** - Final data persistence

### **3. Conditional Processing Workflow**
**File**: `flows/conditional_workflow.json`

Demonstrates advanced conditional logic:
- Dynamic path selection based on parameters
- Parallel processing branches
- Quality-based routing decisions
- Error handling with fallback processing
- Multi-path workflow convergence

**Conditional Features**:
- **Source Selection** - API, Database, or File-based processing
- **Mode Selection** - Batch vs. Stream processing
- **Quality Routing** - High-quality vs. fallback processing
- **Parallel Analytics** - Simultaneous processing and analysis
- **Error Recovery** - Graceful degradation and fallback

## 🔧 **Configuration & Management**

### **Global Parameters**
Configure workflow-wide variables:
```json
{
  "globalParams": [
    {
      "prop": "environment",
      "value": "production",
      "type": "VARCHAR"
    },
    {
      "prop": "batch_size",
      "value": "1000",
      "type": "INTEGER"
    }
  ]
}
```

### **Task Configuration**
Each task supports:
- **Retry Logic** - Configurable retry attempts and intervals
- **Timeout Settings** - Task execution time limits
- **Priority Levels** - HIGH, MEDIUM, LOW priority
- **Worker Groups** - Specific worker assignment
- **Environment Variables** - Task-specific environment setup

### **Scheduling Options**
- **Cron Expressions** - Standard cron scheduling
- **Time Zones** - Global timezone support
- **Date Ranges** - Start and end date constraints
- **Dependency Scheduling** - Cross-workflow dependencies

## 📊 **Monitoring & Observability**

### **Workflow Monitoring**
- **Real-time Status** - Live workflow execution tracking
- **Task Progress** - Individual task status and logs
- **Execution History** - Historical run data and statistics
- **Performance Metrics** - Execution times and resource usage

### **Alerting & Notifications**
- **Email Alerts** - Success/failure notifications
- **Webhook Integration** - Custom notification endpoints
- **Slack Integration** - Team collaboration alerts
- **Custom Scripts** - Flexible notification logic

### **Log Management**
- **Centralized Logging** - All task logs in one place
- **Log Levels** - Configurable logging verbosity
- **Log Retention** - Automatic log cleanup policies
- **Log Search** - Full-text search capabilities

## 🛠️ **Advanced Features**

### **Resource Management**
- **Worker Groups** - Logical worker grouping
- **Resource Quotas** - CPU and memory limits
- **Queue Management** - Task queue prioritization
- **Load Balancing** - Automatic task distribution

### **Security & Access Control**
- **User Management** - Role-based access control
- **Project Isolation** - Multi-tenant security
- **Resource Permissions** - Fine-grained access control
- **Audit Logging** - Complete action audit trail

### **Integration Capabilities**
- **REST API** - Complete programmatic access
- **SDK Support** - Python, Java client libraries
- **Plugin System** - Custom task type development
- **External Systems** - Database, message queue integration

## 🔍 **Troubleshooting**

### **Common Issues**

#### **Startup Problems**
```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f dolphinscheduler-api
docker-compose logs -f dolphinscheduler-master

# Restart services
docker-compose restart
```

#### **Database Connection Issues**
```bash
# Check PostgreSQL status
docker-compose logs dolphinscheduler-postgresql

# Verify database initialization
docker-compose exec dolphinscheduler-postgresql psql -U root -d dolphinscheduler -c "\\dt"
```

#### **UI Access Problems**
```bash
# Check UI container
docker-compose logs dolphinscheduler-ui

# Verify API server
curl http://localhost:12345/dolphinscheduler/actuator/health

# Check port availability
netstat -an | grep 12346
```

### **Performance Tuning**

#### **Master Node Optimization**
```yaml
environment:
  - MASTER_EXEC_THREADS=200        # Increase for more concurrent workflows
  - MASTER_EXEC_TASK_NUM=40        # More tasks per workflow
  - MASTER_DISPATCH_TASK_NUM=6     # Faster task dispatching
```

#### **Worker Node Optimization**
```yaml
environment:
  - WORKER_EXEC_THREADS=200        # More concurrent task execution
  - WORKER_HOST_WEIGHT=200         # Higher worker priority
  - WORKER_MAX_CPU_LOAD_AVG=0.8    # CPU usage threshold
```

## 📚 **Best Practices**

### **Workflow Design**
1. **Modular Tasks** - Keep tasks focused and reusable
2. **Error Handling** - Always include failure paths
3. **Resource Planning** - Consider CPU and memory requirements
4. **Dependency Management** - Minimize complex dependencies
5. **Parameter Usage** - Use global parameters for flexibility

### **Performance Optimization**
1. **Parallel Execution** - Leverage parallel task execution
2. **Resource Allocation** - Right-size worker resources
3. **Batch Processing** - Process data in optimal batch sizes
4. **Caching Strategy** - Cache intermediate results when possible
5. **Monitoring Setup** - Implement comprehensive monitoring

### **Security Considerations**
1. **Access Control** - Implement proper user permissions
2. **Secret Management** - Secure credential storage
3. **Network Security** - Proper firewall configuration
4. **Audit Logging** - Enable comprehensive audit trails
5. **Regular Updates** - Keep DolphinScheduler updated

## 🔗 **Integration Examples**

### **Database Integration**
```bash
# MySQL connection example
MYSQL_HOST=mysql-server
MYSQL_PORT=3306
MYSQL_USER=dolphin_user
MYSQL_PASSWORD=secure_password
MYSQL_DATABASE=analytics_db
```

### **Cloud Storage Integration**
```bash
# AWS S3 integration
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
S3_BUCKET=your-data-bucket
S3_REGION=us-west-2
```

### **Message Queue Integration**
```bash
# Apache Kafka integration
KAFKA_BROKERS=kafka1:9092,kafka2:9092
KAFKA_TOPIC=data-processing-events
KAFKA_GROUP_ID=dolphinscheduler-consumer
```

## 🎉 **Summary**

DolphinScheduler provides:
- ✅ **Visual Workflow Designer** with drag-and-drop interface
- ✅ **Enterprise-Grade Features** with high availability
- ✅ **Rich Task Types** supporting various technologies
- ✅ **Advanced Scheduling** with complex dependencies
- ✅ **Comprehensive Monitoring** and alerting
- ✅ **Multi-tenancy Support** for team collaboration
- ✅ **Extensible Architecture** with plugin system

Perfect for organizations needing a robust, scalable, and user-friendly workflow orchestration platform with strong visual capabilities and enterprise features.

---

**🚀 Ready to orchestrate your workflows visually!** Start with `./start.sh` and explore the powerful DAG editor at http://localhost:12346