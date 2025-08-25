#!/usr/bin/env python3

from prefect import serve
from flows.data_processing_flow import data_processing_workflow

if __name__ == "__main__":
    # Create and serve the deployment
    data_processing_workflow.serve(
        name="data-processing-hourly",
        interval=3600,  # Run every hour (3600 seconds)
        tags=["etl", "data-processing", "demo"]
    )