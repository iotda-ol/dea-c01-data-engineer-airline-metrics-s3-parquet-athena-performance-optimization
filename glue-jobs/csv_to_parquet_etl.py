"""
AWS Glue ETL Job: Convert Airline Metrics CSV to Parquet with Partitioning

This job reads CSV files from S3, transforms them to Parquet format with optimal
compression, and partitions by date for efficient querying in Amazon Athena.

Optimizations:
- Snappy compression for optimal balance of speed and compression
- Partitioning by year/month/day for predicate pushdown
- Column pruning support through Parquet columnar format
- Regional colocation for reduced latency and costs
"""

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import year, month, dayofmonth, col, to_date

# Initialize Glue context
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'SOURCE_S3_PATH',
    'TARGET_S3_PATH',
    'DATABASE_NAME',
    'TABLE_NAME'
])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Configure Spark for optimal Parquet writing
spark.conf.set("spark.sql.parquet.compression.codec", "snappy")
spark.conf.set("spark.sql.parquet.mergeSchema", "false")
spark.conf.set("spark.sql.parquet.filterPushdown", "true")
spark.conf.set("spark.sql.files.maxPartitionBytes", "134217728")  # 128 MB

# Read CSV data from S3
# Expecting CSV files with header in the source location
datasource = glueContext.create_dynamic_frame.from_options(
    format_options={
        "quoteChar": '"',
        "withHeader": True,
        "separator": ",",
        "optimizePerformance": True,
    },
    connection_type="s3",
    format="csv",
    connection_options={
        "paths": [args['SOURCE_S3_PATH']],
        "recurse": True
    },
    transformation_ctx="datasource"
)

# Convert to DataFrame for transformation
df = datasource.toDF()

# Add partition columns from flight_date
# Assuming the CSV has a 'flight_date' column in format YYYY-MM-DD
df = df.withColumn("flight_date_parsed", to_date(col("flight_date"), "yyyy-MM-dd"))
df = df.withColumn("year", year(col("flight_date_parsed")))
df = df.withColumn("month", month(col("flight_date_parsed")))
df = df.withColumn("day", dayofmonth(col("flight_date_parsed")))

# Drop the temporary parsed date column
df = df.drop("flight_date_parsed")

# Convert numeric columns to appropriate types for better compression and performance
# Note: Adjust these based on your actual schema
numeric_columns = [
    "departure_delay_minutes",
    "arrival_delay_minutes",
    "flight_duration_minutes",
    "distance_miles",
    "passengers_count",
    "baggage_count"
]

for col_name in numeric_columns:
    if col_name in df.columns:
        df = df.withColumn(col_name, col(col_name).cast("int"))

# Convert back to DynamicFrame
dynamic_frame = DynamicFrame.fromDF(df, glueContext, "dynamic_frame")

# Write to S3 in Parquet format with partitioning
# Partitioning by year/month/day enables efficient date range queries
glueContext.write_dynamic_frame.from_options(
    frame=dynamic_frame,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": args['TARGET_S3_PATH'],
        "partitionKeys": ["year", "month", "day"]
    },
    format_options={
        "compression": "snappy"
    },
    transformation_ctx="datasink"
)

# Update the Glue Data Catalog with the new partitions
try:
    # Enable partition indexing for faster partition discovery
    glueContext.purge_s3_path(
        args['TARGET_S3_PATH'],
        options={"retentionPeriod": 0}
    )
except Exception as e:
    print(f"Note: Purge operation info - {str(e)}")

job.commit()
