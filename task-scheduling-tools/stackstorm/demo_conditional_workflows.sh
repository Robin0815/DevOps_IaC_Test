#!/bin/bash

echo "🔧 Conditional Workflow Demonstration"
echo "======================================"
echo ""

BASE_URL="http://localhost:8090"

echo "📋 Available workflows:"
curl -s $BASE_URL/api/workflows | jq -r '.[]' | sed 's/^/  - /'
echo ""

echo "🚀 Demo 1: Primary workflow triggers dependent workflow automatically"
echo "----------------------------------------------------------------------"
echo "Starting primary_data_processing workflow..."
curl -X POST -H "Content-Type: application/json" -d '{}' $BASE_URL/api/workflows/primary_data_processing/execute
echo ""
echo "⏳ Waiting for workflows to complete..."
sleep 15

echo "📊 Execution results:"
curl -s $BASE_URL/api/executions | jq '.[] | select(.workflow_name == "primary_data_processing" or .workflow_name == "dependent_cleanup") | {workflow: .workflow_name, status: .status, duration: (.end_time // "running")}'
echo ""

echo "🚀 Demo 2: Conditional workflow waits for prerequisite"
echo "-----------------------------------------------------"
echo "Starting data_backup workflow..."
curl -X POST -H "Content-Type: application/json" -d '{}' $BASE_URL/api/workflows/data_backup/execute
sleep 8

echo "Starting conditional_workflow_chain (waits for data_backup to complete)..."
curl -X POST -H "Content-Type: application/json" -d '{}' $BASE_URL/api/workflows/conditional_workflow_chain/execute
echo ""
echo "⏳ Waiting for conditional workflow to complete..."
sleep 12

echo "📊 Final execution results:"
curl -s $BASE_URL/api/executions | jq '.[] | select(.workflow_name == "data_backup" or .workflow_name == "conditional_workflow_chain") | {workflow: .workflow_name, status: .status, start_time: .start_time}'
echo ""

echo "✅ Demo completed! Check the web dashboard at http://localhost:8090"