#!/usr/bin/env python3

from prefect import serve
from prefect.deployments import Deployment
from prefect.server.schemas.schedules import IntervalSchedule, CronSchedule
from datetime import timedelta

# Import all flows
from flows.data_processing_flow import data_processing_workflow
from flows.upstream_flow import upstream_flow
from flows.downstream_flow import downstream_flow
from flows.orchestrator_flow import orchestrator_flow
from flows.advanced_dependencies import advanced_dependencies_flow

def create_all_deployments():
    """Create deployments for all flows with different scheduling strategies"""
    
    deployments = []
    
    # 1. Upstream flow - runs every 2 hours
    upstream_deployment = Deployment.build_from_flow(
        flow=upstream_flow,
        name="upstream-data-preparation",
        schedule=IntervalSchedule(interval=timedelta(hours=2)),
        tags=["upstream", "data-prep", "etl"],
        description="Upstream data preparation that triggers downstream processing"
    )
    deployments.append(upstream_deployment)
    
    # 2. Data processing flow - runs every hour
    data_processing_deployment = Deployment.build_from_flow(
        flow=data_processing_workflow,
        name="data-processing-hourly",
        schedule=IntervalSchedule(interval=timedelta(hours=1)),
        tags=["etl", "data-processing", "core"],
        description="Core data processing workflow"
    )
    deployments.append(data_processing_deployment)
    
    # 3. Downstream flow - no schedule (triggered by upstream)
    downstream_deployment = Deployment.build_from_flow(
        flow=downstream_flow,
        name="downstream-processing",
        schedule=None,  # No automatic schedule - triggered by other flows
        tags=["downstream", "dependent", "processing"],
        description="Downstream processing that waits for upstream completion"
    )
    deployments.append(downstream_deployment)
    
    # 4. Orchestrator flow - runs daily at 2 AM
    orchestrator_deployment = Deployment.build_from_flow(
        flow=orchestrator_flow,
        name="daily-orchestration",
        schedule=CronSchedule(cron="0 2 * * *"),  # Daily at 2 AM
        tags=["orchestrator", "daily", "coordination"],
        description="Daily orchestration of multiple dependent flows"
    )
    deployments.append(orchestrator_deployment)
    
    # 5. Advanced dependencies flow - runs every 4 hours
    advanced_deployment = Deployment.build_from_flow(
        flow=advanced_dependencies_flow,
        name="advanced-dependencies",
        schedule=IntervalSchedule(interval=timedelta(hours=4)),
        tags=["advanced", "conditional", "dependencies"],
        description="Advanced flow with conditional dependencies and state checking"
    )
    deployments.append(advanced_deployment)
    
    return deployments

def deploy_all():
    """Deploy all flows"""
    deployments = create_all_deployments()
    
    print("Creating deployments...")
    for deployment in deployments:
        deployment.apply()
        print(f"✅ Created deployment: {deployment.name}")
    
    print(f"\n🎉 Successfully created {len(deployments)} deployments!")
    print("\nDeployment Summary:")
    print("==================")
    print("1. upstream-data-preparation - Every 2 hours")
    print("2. data-processing-hourly - Every hour") 
    print("3. downstream-processing - Triggered by upstream")
    print("4. daily-orchestration - Daily at 2 AM")
    print("5. advanced-dependencies - Every 4 hours")
    print("\nTo start workers:")
    print("docker-compose exec prefect-server prefect agent start -q 'default'")

if __name__ == "__main__":
    deploy_all()