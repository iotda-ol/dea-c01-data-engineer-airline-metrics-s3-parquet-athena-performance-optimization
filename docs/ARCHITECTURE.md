# Architecture Overview

## Solution Architecture

This data lake solution implements a modern, serverless architecture for airline metrics analytics using AWS managed services. The architecture follows DEA-C01 (AWS Certified Data Engineer - Associate) best practices for data engineering on AWS.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Data Ingestion Layer                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  CSV Files → S3 Raw Bucket (airline_metrics_YYYY-MM-DD.csv)            │
│                    └── Partitioned by date                              │
│                    └── Lifecycle: STANDARD → IA → GLACIER               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                      ETL Processing Layer                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  AWS Glue ETL Job (PySpark)                                             │
│    • Read CSV from S3                                                   │
│    • Transform to Parquet with Snappy compression                       │
│    • Add partition columns (year, month, day)                           │
│    • Cast numeric columns to appropriate types                          │
│    • Write to S3 Processed Bucket with partitioning                     │
│                                                                          │
│  Job Configuration:                                                      │
│    • Glue Version: 4.0                                                  │
│    • Worker Type: G.1X (10 workers)                                     │
│    • Job Bookmarks: Enabled (incremental processing)                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                        Storage Layer                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  S3 Processed Bucket (Parquet Files)                                    │
│    └── airline_metrics/                                                 │
│         └── year=2024/                                                  │
│             └── month=01/                                               │
│                 └── day=15/                                             │
│                     └── part-00000.snappy.parquet                       │
│                                                                          │
│  Features:                                                               │
│    • Columnar storage (Parquet)                                         │
│    • Snappy compression (optimal speed/size)                            │
│    • Partitioned by year/month/day                                      │
│    • Server-side encryption (SSE-S3)                                    │
│    • Versioning enabled                                                 │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                      Catalog Layer                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  AWS Glue Data Catalog                                                   │
│    • Database: airline_metrics_dev                                      │
│    • Table: airline_metrics                                             │
│    • Schema: 37 columns + 3 partition columns                           │
│    • Partition Projection: Enabled for fast queries                     │
│                                                                          │
│  AWS Glue Crawler                                                        │
│    • Discovers schema automatically                                     │
│    • Updates partition metadata                                         │
│    • Runs on-demand or scheduled                                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                       Query Layer                                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Amazon Athena                                                           │
│    • Serverless SQL queries                                             │
│    • Query Parquet files directly in S3                                 │
│    • Optimizations:                                                      │
│      - Column pruning (read only needed columns)                        │
│      - Predicate pushdown (filter at storage level)                     │
│      - Partition pruning (skip irrelevant partitions)                   │
│      - Partition projection (no catalog overhead)                       │
│    • Workgroup configuration:                                            │
│      - Query results in dedicated S3 bucket                             │
│      - 10 GB per-query scan limit                                       │
│      - CloudWatch metrics enabled                                       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                    Analytics & Visualization                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  • Amazon QuickSight (BI dashboards)                                    │
│  • Direct SQL queries via Athena                                        │
│  • JDBC/ODBC connections                                                │
│  • Python/R notebooks (via PyAthena, AWS Data Wrangler)                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. S3 Buckets

#### Raw Data Bucket
- **Purpose**: Store original CSV files
- **Naming**: `{project-name}-raw-{env}-{account-id}`
- **Structure**: `s3://bucket/airline_metrics/YYYY-MM-DD/file.csv`
- **Lifecycle**: STANDARD (0-30d) → STANDARD_IA (30-90d) → GLACIER (90d+)
- **Security**: Server-side encryption, versioning enabled

#### Processed Data Bucket
- **Purpose**: Store transformed Parquet files
- **Naming**: `{project-name}-processed-{env}-{account-id}`
- **Structure**: `s3://bucket/airline_metrics/year=YYYY/month=MM/day=DD/`
- **Format**: Parquet with Snappy compression
- **Lifecycle**: STANDARD (0-90d) → STANDARD_IA (90d+)

#### Athena Results Bucket
- **Purpose**: Store Athena query results
- **Naming**: `{project-name}-athena-results-{env}-{account-id}`
- **Lifecycle**: Auto-delete after 30 days

### 2. AWS Glue Components

#### Glue Database
- **Name**: `airline_metrics_{environment}`
- **Purpose**: Logical grouping for tables
- **Location**: Points to processed data bucket

#### Glue ETL Job
- **Name**: `airline-metrics-csv-to-parquet`
- **Language**: PySpark (Python 3)
- **Version**: Glue 4.0
- **Workers**: 10 x G.1X (4 vCPU, 16 GB memory each)
- **Features**:
  - Job bookmarks for incremental processing
  - Spark UI enabled for debugging
  - Job insights for monitoring

#### Glue Crawler
- **Name**: `airline-metrics-parquet-crawler`
- **Schedule**: On-demand or scheduled (e.g., daily)
- **Target**: Processed data bucket
- **Purpose**: Auto-discover schema and partitions

### 3. IAM Roles

#### Glue Service Role
- **Permissions**:
  - Read from raw data bucket
  - Write to processed data bucket
  - Access to Glue Data Catalog
  - CloudWatch Logs access

#### Athena Workgroup Role (for service-level access)
- **Permissions**:
  - Read from processed data bucket
  - Write to Athena results bucket
  - Access to Glue Data Catalog

### 4. Amazon Athena

#### Workgroup Configuration
- **Name**: `airline-metrics-workgroup-{env}`
- **Results Location**: Dedicated S3 bucket
- **Encryption**: SSE-S3
- **Bytes Scanned Limit**: 10 GB per query
- **Metrics**: CloudWatch enabled

## Data Flow

### Ingestion
1. CSV files uploaded to raw data bucket
2. Files organized by date: `airline_metrics/2024-01-15/file.csv`
3. Lifecycle policies automatically transition older data

### Transformation
1. Glue ETL job triggered (manual, scheduled, or event-driven)
2. Job reads CSV files from raw bucket
3. Transforms data:
   - Converts to Parquet format
   - Applies Snappy compression
   - Adds partition columns (year, month, day)
   - Casts numeric columns to proper types
4. Writes partitioned Parquet files to processed bucket
5. Job bookmarks track processed files

### Cataloging
1. Glue crawler scans processed bucket
2. Discovers schema from Parquet metadata
3. Creates/updates table in Glue Data Catalog
4. Adds partition information

### Querying
1. Users run SQL queries via Athena
2. Athena reads metadata from Glue Data Catalog
3. Queries are optimized:
   - Partition pruning skips irrelevant partitions
   - Column pruning reads only needed columns
   - Predicate pushdown filters at storage level
4. Results stored in Athena results bucket

## Regional Colocation

**Critical**: All resources must be deployed in the **same AWS Region** to:
- Minimize data transfer latency
- Eliminate inter-region data transfer costs
- Ensure optimal performance for Athena queries
- Comply with data residency requirements

### Region Selection Criteria
- **Data Source Location**: Choose region closest to data sources
- **User Location**: Consider where analysts are located
- **Service Availability**: Ensure all services available in region
- **Cost**: Some regions have different pricing
- **Compliance**: Data sovereignty requirements

## Security

### Encryption
- **At Rest**: S3 server-side encryption (SSE-S3)
- **In Transit**: TLS/HTTPS for all data transfers
- **Athena Results**: Encrypted query results

### Access Control
- **IAM Roles**: Least privilege principle
- **S3 Bucket Policies**: Block public access
- **Glue Data Catalog**: Fine-grained access control
- **VPC**: Optional VPC endpoints for private connectivity

### Monitoring & Auditing
- **CloudTrail**: API call logging
- **CloudWatch**: Metrics and logs
- **S3 Access Logs**: Bucket access tracking
- **Glue Job Metrics**: ETL job monitoring

## Scalability

### Data Volume
- **Daily Ingestion**: 100 MB - 10 GB per day
- **Total Storage**: Scales to petabytes
- **Partition Count**: Millions of partitions supported

### Query Performance
- **Concurrent Queries**: Athena supports 20+ concurrent queries
- **Workers**: Automatically scales based on query complexity
- **Caching**: Athena caches query results for 24 hours

### Cost Optimization
- **Parquet**: 3-5x smaller than CSV
- **Compression**: Additional 2-3x reduction
- **Partitioning**: 10-100x faster queries
- **Column Pruning**: 5-20x data scan reduction
- **Result Caching**: Free repeated queries within 24 hours

## High Availability & Disaster Recovery

### Data Durability
- **S3**: 99.999999999% (11 9's) durability
- **Versioning**: Enabled for accidental deletion protection
- **Cross-Region Replication**: Optional for DR

### Service Availability
- **Athena**: 99.9% SLA
- **Glue**: 99.9% SLA
- **S3**: 99.99% SLA

### Backup Strategy
- **S3 Versioning**: Enabled on all buckets
- **Lifecycle Policies**: Transition to Glacier for long-term retention
- **Glue Catalog**: Backup using CloudFormation/Terraform

## Performance Benchmarks

### Query Performance (Typical)
- **Simple SELECT**: 1-5 seconds
- **Aggregations**: 5-15 seconds
- **Complex Joins**: 15-60 seconds
- **Full Table Scan**: Varies by data size

### ETL Performance
- **Processing Rate**: 10-50 MB/s per worker
- **10 GB Dataset**: 5-10 minutes with 10 workers
- **100 GB Dataset**: 30-60 minutes with 10 workers

### Cost Examples (us-east-1)
- **Athena**: $5 per TB scanned
- **Glue**: $0.44 per DPU-hour
- **S3 Standard**: $0.023 per GB/month
- **S3 Glacier**: $0.004 per GB/month

With optimizations:
- **Parquet vs CSV**: 5x cost reduction
- **Partitioning**: 10x cost reduction
- **Column Pruning**: 3x cost reduction
- **Combined**: Up to 150x cost reduction
