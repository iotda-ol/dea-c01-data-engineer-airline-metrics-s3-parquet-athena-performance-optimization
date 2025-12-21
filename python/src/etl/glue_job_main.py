"""
Glue Job Main Entry Point
AWS Glue job entry point that uses the modular ETL classes
"""

import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from csv_to_parquet import CSVToParquetETL


def main():
    """Main entry point for AWS Glue ETL job"""
    
    # Get job parameters
    args = getResolvedOptions(sys.argv, [
        'JOB_NAME',
        'SOURCE_S3_PATH',
        'TARGET_S3_PATH'
    ])
    
    # Initialize Glue context
    sc = SparkContext()
    glue_context = GlueContext(sc)
    spark = glue_context.spark_session
    job = Job(glue_context)
    job.init(args['JOB_NAME'], args)
    
    print(f"🚀 Starting Glue Job: {args['JOB_NAME']}")
    print(f"📂 Source: {args['SOURCE_S3_PATH']}")
    print(f"📂 Target: {args['TARGET_S3_PATH']}")
    
    # Run ETL using modular class
    etl = CSVToParquetETL(spark)
    etl.process(
        source_path=args['SOURCE_S3_PATH'],
        target_path=args['TARGET_S3_PATH']
    )
    
    # Commit job
    job.commit()
    print(f"✅ Glue Job completed successfully!")


if __name__ == '__main__':
    main()
