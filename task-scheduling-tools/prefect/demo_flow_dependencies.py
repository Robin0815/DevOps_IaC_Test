#!/usr/bin/env python3

import asyncio
import time
from datetime import datetime
from prefect.client.orchestration import PrefectClient

async def demo_flow_dependencies():
    """
    Demonstrate different types of flow dependencies in Prefect
    """
    print("🔧 Prefect Flow Dependencies Demo")
    print("==================================")
    
    async with PrefectClient() as client:
        print("\n📋 Available Flows:")
        flows = await client.read_flows()
        for flow in flows:
            print(f"  - {flow.name}")
        
        print("\n🚀 Demo 1: Sequential Flow Execution")
        print("------------------------------------")
        
        # Run upstream flow first
        print("Starting upstream flow...")
        upstream_flows = [f for f in flows if "Upstream" in f.name]
        if upstream_flows:
            upstream_run = await client.create_flow_run(flow=upstream_flows[0])
            print(f"Created upstream run: {upstream_run.id}")
            
            # Wait a bit
            await asyncio.sleep(5)
            
            # Check status
            run_status = await client.read_flow_run(upstream_run.id)
            print(f"Upstream status: {run_status.state.type}")
        
        print("\n🚀 Demo 2: Orchestrated Flow Execution")
        print("--------------------------------------")
        
        # Run orchestrator flow
        orchestrator_flows = [f for f in flows if "Orchestrator" in f.name]
        if orchestrator_flows:
            orchestrator_run = await client.create_flow_run(flow=orchestrator_flows[0])
            print(f"Created orchestrator run: {orchestrator_run.id}")
            
            # Monitor progress
            for i in range(6):  # Check for 30 seconds
                await asyncio.sleep(5)
                run_status = await client.read_flow_run(orchestrator_run.id)
                print(f"Orchestrator status: {run_status.state.type}")
                
                if run_status.state.is_completed() or run_status.state.is_failed():
                    break
        
        print("\n📊 Recent Flow Runs:")
        print("-------------------")
        recent_runs = await client.read_flow_runs(limit=10)
        for run in recent_runs:
            print(f"  {run.flow_name}: {run.state.type} ({run.start_time})")

def demo_local_dependencies():
    """
    Demonstrate local flow dependencies (subflows)
    """
    print("\n🚀 Demo 3: Local Subflow Dependencies")
    print("-------------------------------------")
    
    # Import and run the orchestrator flow locally
    from flows.orchestrator_flow import orchestrator_flow
    
    print("Running orchestrator flow locally...")
    result = orchestrator_flow()
    
    print(f"Orchestrator result: {result['status']}")
    print(f"Flows executed: {result['flows_executed']}")
    print(f"All successful: {result['validation']['all_flows_successful']}")

async def main():
    """Main demo function"""
    try:
        await demo_flow_dependencies()
    except Exception as e:
        print(f"API demo failed (server might not be running): {e}")
        print("Running local demo instead...")
    
    demo_local_dependencies()
    
    print("\n✅ Flow Dependencies Demo Complete!")
    print("\nKey Takeaways:")
    print("==============")
    print("1. Subflows: Call flows directly within other flows")
    print("2. Deployments: Use scheduled deployments with triggers")
    print("3. State Checking: Monitor flow run states programmatically")
    print("4. Conditional Logic: Execute flows based on conditions")
    print("5. Orchestration: Coordinate multiple flows with dependencies")

if __name__ == "__main__":
    asyncio.run(main())