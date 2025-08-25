#!/bin/bash

echo "🚀 Setting up example workflows for all scheduling tools..."

# Check if services are running
if ! docker ps | grep -q "airflow-airflow-webserver"; then
    echo "❌ Airflow is not running. Please start services first with ./start-all.sh"
    exit 1
fi

echo ""
echo "📋 Workflow Setup Status:"

# 1. Airflow - DAGs are automatically detected
echo "✅ Airflow: DAGs automatically detected from dags/ folder"
echo "   - data_processing_workflow.py"
echo "   - hello_world.py"

# 2. Prefect - Create deployment
echo "🔮 Setting up Prefect deployment..."
cd prefect
export PREFECT_API_URL="http://localhost:4200/api"

python3 -c "
try:
    from data_processing_flow import data_processing_workflow
    from prefect.deployments import Deployment
    from prefect.server.schemas.schedules import IntervalSchedule
    from datetime import timedelta
    
    deployment = Deployment.build_from_flow(
        flow=data_processing_workflow,
        name='data-processing-hourly',
        schedule=IntervalSchedule(interval=timedelta(hours=1))
    )
    deployment.apply()
    print('✅ Prefect: Deployment created successfully')
except Exception as e:
    print(f'⚠️ Prefect: {str(e)}')
"
cd ..

# 3. StackStorm - Register pack (simplified for demo)
echo "⚡ Setting up StackStorm pack..."
echo "✅ StackStorm: Pack files created (manual registration required)"
echo "   Run: docker-compose -f stackstorm/docker-compose.yml exec stackstorm st2ctl reload --register-all"

# 4. Jenkins - Manual setup required
echo "🏗️ Jenkins setup:"
echo "✅ Jenkins: Pipeline script ready"
echo "   - Open http://localhost:8081"
echo "   - Create new Pipeline job"
echo "   - Copy content from jenkins/jobs/DataProcessingPipeline.groovy"

# 5. SaltStack - States are automatically available
echo "🧂 SaltStack setup:"
echo "✅ SaltStack: State files ready in salt-config/"
echo "   - data_processing.sls"
echo "   - hello.sls"

echo ""
echo "🎉 Workflow setup completed!"
echo ""
echo "📊 Access your tools:"
echo "• Airflow:    http://localhost:8080 (airflow/airflow)"
echo "• Prefect:    http://localhost:4200"
echo "• StackStorm: https://localhost (st2admin/Ch@ngeMe)"
echo "• Jenkins:    http://localhost:8081 (admin/$(docker-compose -f jenkins/docker-compose.yml exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null | tr -d '\r'))"
echo "• SaltStack:  http://localhost:3333"
echo ""
echo "🔧 Quick test commands:"
echo "# Test Airflow DAG:"
echo "curl -X POST 'http://localhost:8080/api/v1/dags/data_processing_workflow/dagRuns' -H 'Content-Type: application/json' -u 'airflow:airflow' -d '{\"dag_run_id\": \"manual_test\"}'"
echo ""
echo "# Test Prefect Flow:"
echo "cd prefect && python data_processing_flow.py"
echo ""
echo "# Test SaltStack State:"
echo "docker-compose -f saltstack/docker-compose.yml exec salt-master salt '*' state.apply data_processing"