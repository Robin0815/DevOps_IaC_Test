#!/usr/bin/env python3
"""
Create deployments for the UI Showcase flows
"""

from prefect.deployments import Deployment
from flows.ui_showcase_flow import ui_showcase_pipeline, advanced_showcase_pipeline, DataProcessingConfig

# Create deployment for basic UI showcase
basic_deployment = Deployment.build_from_flow(
    flow=ui_showcase_pipeline,
    name="ui-showcase-basic",
    description="Basic UI showcase pipeline demonstrating visual workflow features",
    parameters={
        "config": DataProcessingConfig(
            batch_size=100,
            environment="development",
            enable_validation=True,
            max_retries=3
        ).model_dump()
    },
    work_pool_name="default-agent-pool",
    tags=["demo", "ui-showcase", "development"]
)

# Create deployment for advanced UI showcase
advanced_deployment = Deployment.build_from_flow(
    flow=advanced_showcase_pipeline,
    name="ui-showcase-advanced",
    description="Advanced UI showcase with subflows and complex orchestration",
    parameters={
        "config": DataProcessingConfig(
            batch_size=200,
            environment="production",
            enable_validation=True,
            max_retries=5
        ).model_dump()
    },
    work_pool_name="default-agent-pool",
    tags=["demo", "ui-showcase", "production", "subflows"]
)

if __name__ == "__main__":
    print("🚀 Creating UI Showcase Deployments...")
    print("=" * 50)
    
    # Apply deployments
    basic_deployment.apply()
    print("✅ Created basic UI showcase deployment")
    
    advanced_deployment.apply()
    print("✅ Created advanced UI showcase deployment")
    
    print("\n🎨 Deployments created successfully!")
    print("📊 View them in the Prefect UI at: http://localhost:4200")
    print("🔧 Navigate to 'Deployments' section to run them manually")
    print("\n💡 These deployments showcase:")
    print("   • Visual flow graphs with real-time updates")
    print("   • Interactive task nodes with detailed logs")
    print("   • Parameter forms for easy configuration")
    print("   • Subflow hierarchy visualization")
    print("   • Conditional logic representation")
    print("   • Parallel task execution visualization")