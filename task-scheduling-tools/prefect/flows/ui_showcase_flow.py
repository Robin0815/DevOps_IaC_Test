#!/usr/bin/env python3
"""
Prefect UI Showcase Flow - Demonstrates visual workflow features
"""

from prefect import flow, task
from prefect.logging import get_run_logger
from pydantic import BaseModel
import time
import random
from typing import List, Dict, Any

class DataProcessingConfig(BaseModel):
    """Configuration model for the data processing pipeline"""
    batch_size: int = 100
    max_retries: int = 3
    environment: str = "development"
    enable_validation: bool = True

@task(name="🔍 Data Discovery", description="Discover available data sources")
def discover_data_sources() -> List[str]:
    """Simulate discovering data sources"""
    logger = get_run_logger()
    
    sources = ["customers.csv", "orders.json", "products.xml", "inventory.db"]
    logger.info(f"Discovered {len(sources)} data sources", extra={"sources": sources})
    
    # Simulate processing time
    time.sleep(2)
    
    return sources

@task(name="📥 Extract Data", description="Extract data from source")
def extract_data(source: str, batch_size: int = 100) -> Dict[str, Any]:
    """Extract data from a given source"""
    logger = get_run_logger()
    
    # Simulate extraction
    record_count = random.randint(50, 500)
    logger.info(f"Extracting from {source}", extra={
        "source": source,
        "batch_size": batch_size,
        "estimated_records": record_count
    })
    
    time.sleep(1)
    
    extracted_data = {
        "source": source,
        "records": record_count,
        "extraction_time": time.time(),
        "status": "success"
    }
    
    logger.info(f"Extracted {record_count} records from {source}")
    return extracted_data

@task(name="🔍 Validate Data", description="Validate data quality and schema")
def validate_data(data: Dict[str, Any]) -> Dict[str, Any]:
    """Validate extracted data"""
    logger = get_run_logger()
    
    # Simulate validation
    validation_score = random.uniform(0.8, 1.0)
    is_valid = validation_score > 0.85
    
    logger.info(f"Validating data from {data['source']}", extra={
        "validation_score": validation_score,
        "is_valid": is_valid,
        "record_count": data["records"]
    })
    
    time.sleep(1)
    
    validation_result = {
        **data,
        "validation_score": validation_score,
        "is_valid": is_valid,
        "validation_time": time.time()
    }
    
    if is_valid:
        logger.info(f"✅ Data validation passed with score {validation_score:.2f}")
    else:
        logger.warning(f"⚠️ Data validation failed with score {validation_score:.2f}")
    
    return validation_result

@task(name="🔄 Transform Data", description="Clean and transform data")
def transform_data(validated_data: Dict[str, Any]) -> Dict[str, Any]:
    """Transform validated data"""
    logger = get_run_logger()
    
    if not validated_data["is_valid"]:
        logger.warning("Skipping transformation for invalid data")
        return {**validated_data, "transformed": False}
    
    # Simulate transformation
    original_count = validated_data["records"]
    transformed_count = int(original_count * random.uniform(0.9, 0.98))
    
    logger.info(f"Transforming data from {validated_data['source']}", extra={
        "original_records": original_count,
        "transformed_records": transformed_count,
        "transformation_rate": transformed_count / original_count
    })
    
    time.sleep(2)
    
    transformed_data = {
        **validated_data,
        "original_records": original_count,
        "transformed_records": transformed_count,
        "transformation_time": time.time(),
        "transformed": True
    }
    
    logger.info(f"✅ Transformed {original_count} → {transformed_count} records")
    return transformed_data

@task(name="📤 Load Data", description="Load transformed data to destination")
def load_data(transformed_data: Dict[str, Any], destination: str = "warehouse") -> Dict[str, Any]:
    """Load transformed data to destination"""
    logger = get_run_logger()
    
    if not transformed_data.get("transformed", False):
        logger.warning("Skipping load for untransformed data")
        return {**transformed_data, "loaded": False}
    
    # Simulate loading
    records_to_load = transformed_data["transformed_records"]
    
    logger.info(f"Loading {records_to_load} records to {destination}", extra={
        "destination": destination,
        "records": records_to_load,
        "source": transformed_data["source"]
    })
    
    time.sleep(1)
    
    # Simulate occasional load failures
    load_success = random.random() > 0.1  # 90% success rate
    
    result = {
        **transformed_data,
        "destination": destination,
        "load_time": time.time(),
        "loaded": load_success,
        "load_status": "success" if load_success else "failed"
    }
    
    if load_success:
        logger.info(f"✅ Successfully loaded {records_to_load} records to {destination}")
    else:
        logger.error(f"❌ Failed to load records to {destination}")
    
    return result

@task(name="📊 Generate Report", description="Generate processing summary report")
def generate_report(results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Generate a summary report of all processing results"""
    logger = get_run_logger()
    
    total_sources = len(results)
    total_records = sum(r.get("original_records", 0) for r in results)
    successful_loads = sum(1 for r in results if r.get("loaded", False))
    failed_loads = total_sources - successful_loads
    
    report = {
        "total_sources": total_sources,
        "total_records": total_records,
        "successful_loads": successful_loads,
        "failed_loads": failed_loads,
        "success_rate": successful_loads / total_sources if total_sources > 0 else 0,
        "report_time": time.time()
    }
    
    logger.info("📊 Processing Summary", extra=report)
    logger.info(f"✅ Processed {total_sources} sources with {successful_loads} successful loads")
    
    return report

@flow(name="🎨 UI Showcase Pipeline", 
      description="Comprehensive data pipeline showcasing Prefect UI features")
def ui_showcase_pipeline(config: DataProcessingConfig = DataProcessingConfig()) -> Dict[str, Any]:
    """
    A comprehensive data processing pipeline that demonstrates Prefect's UI capabilities.
    
    This flow includes:
    - Dynamic task generation
    - Conditional logic
    - Parallel processing
    - Rich logging with structured data
    - Parameter validation
    - Error handling
    
    Args:
        config: Configuration object with pipeline settings
    """
    logger = get_run_logger()
    
    logger.info("🚀 Starting UI Showcase Pipeline", extra={
        "config": config.dict(),
        "pipeline_version": "1.0.0"
    })
    
    # Step 1: Discover data sources
    sources = discover_data_sources()
    
    # Step 2: Process each source in parallel
    extraction_results = []
    for source in sources:
        # Extract data
        extracted = extract_data(source, config.batch_size)
        extraction_results.append(extracted)
    
    # Step 3: Conditional validation (if enabled)
    validation_results = []
    if config.enable_validation:
        logger.info("🔍 Validation enabled - validating all sources")
        for extracted in extraction_results:
            validated = validate_data(extracted)
            validation_results.append(validated)
    else:
        logger.info("⚠️ Validation disabled - skipping validation step")
        validation_results = [{**r, "is_valid": True, "validation_score": 1.0} 
                            for r in extraction_results]
    
    # Step 4: Transform valid data
    transformation_results = []
    for validated in validation_results:
        transformed = transform_data(validated)
        transformation_results.append(transformed)
    
    # Step 5: Load transformed data
    load_results = []
    destination = f"{config.environment}_warehouse"
    
    for transformed in transformation_results:
        loaded = load_data(transformed, destination)
        load_results.append(loaded)
    
    # Step 6: Generate final report
    final_report = generate_report(load_results)
    
    # Step 7: Environment-specific actions
    if config.environment == "production":
        logger.info("🏭 Production environment - enabling additional monitoring")
        final_report["monitoring_enabled"] = True
    else:
        logger.info("🧪 Development environment - skipping production features")
        final_report["monitoring_enabled"] = False
    
    logger.info("✅ Pipeline completed successfully", extra={
        "total_runtime": time.time(),
        "final_report": final_report
    })
    
    return {
        "pipeline_status": "completed",
        "config": config.dict(),
        "results": load_results,
        "summary": final_report
    }

# Subflow example
@flow(name="🔄 Data Quality Check", description="Comprehensive data quality validation")
def data_quality_subflow(data_batch: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Subflow for comprehensive data quality checks"""
    logger = get_run_logger()
    
    logger.info(f"🔍 Running quality checks on {len(data_batch)} data sources")
    
    quality_scores = []
    for data in data_batch:
        score = data.get("validation_score", 0.0)
        quality_scores.append(score)
    
    avg_quality = sum(quality_scores) / len(quality_scores) if quality_scores else 0
    
    quality_report = {
        "average_quality": avg_quality,
        "total_sources": len(data_batch),
        "quality_threshold": 0.85,
        "passed_quality": avg_quality >= 0.85
    }
    
    logger.info("📊 Quality Check Results", extra=quality_report)
    
    return quality_report

@flow(name="🎯 Advanced Showcase Pipeline", 
      description="Advanced pipeline with subflows and complex logic")
def advanced_showcase_pipeline(config: DataProcessingConfig = DataProcessingConfig()) -> Dict[str, Any]:
    """
    Advanced pipeline demonstrating subflows and complex orchestration
    """
    logger = get_run_logger()
    
    # Run main pipeline
    main_result = ui_showcase_pipeline(config)
    
    # Run quality check subflow
    quality_result = data_quality_subflow(main_result["results"])
    
    # Conditional logic based on quality
    if quality_result["passed_quality"]:
        logger.info("✅ Quality checks passed - proceeding with advanced processing")
        advanced_status = "approved"
    else:
        logger.warning("⚠️ Quality checks failed - flagging for review")
        advanced_status = "needs_review"
    
    return {
        "main_pipeline": main_result,
        "quality_check": quality_result,
        "final_status": advanced_status,
        "timestamp": time.time()
    }

if __name__ == "__main__":
    # Example configurations for testing
    dev_config = DataProcessingConfig(
        batch_size=50,
        environment="development",
        enable_validation=True
    )
    
    prod_config = DataProcessingConfig(
        batch_size=200,
        environment="production",
        enable_validation=True,
        max_retries=5
    )
    
    print("🎨 Running UI Showcase Pipeline...")
    print("=" * 50)
    
    # Run the basic showcase
    result = ui_showcase_pipeline(dev_config)
    print(f"✅ Basic pipeline completed: {result['pipeline_status']}")
    
    # Run the advanced showcase
    advanced_result = advanced_showcase_pipeline(prod_config)
    print(f"✅ Advanced pipeline completed: {advanced_result['final_status']}")
    
    print("\n🌐 View the results in the Prefect UI at: http://localhost:4200")
    print("📊 Check the Flow Runs section to see the visual workflow graphs!")