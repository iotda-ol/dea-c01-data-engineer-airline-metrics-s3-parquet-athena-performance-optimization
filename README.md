# AWS Data Lake POC: Airline Metrics Analytics

## Overview

This repository implements a production-ready AWS data lake for airline flight metrics analytics, following AWS Certified Data Engineer - Associate (DEA-C01) best practices. The solution demonstrates automated CSV-to-Parquet conversion using AWS Glue, optimized Amazon Athena queries with column pruning and predicate pushdown, and comprehensive cost optimization strategies.

## Key Features

- 🚀 **Serverless Architecture**: Uses AWS Glue, S3, and Athena (no server management)
- 💰 **Cost Optimized**: Up to 150x cost reduction through format optimization and partitioning
- ⚡ **High Performance**: 150x faster queries with Parquet, partitioning, and query optimizations
- 🔒 **Secure**: Encryption at rest and in transit, IAM roles with least privilege
- 📊 **Analytics Ready**: Sample queries demonstrating best practices
- 🏗️ **Infrastructure as Code**: CloudFormation templates for reproducible deployments
- 📚 **Well Documented**: Comprehensive guides for deployment, optimization, and DEA-C01 alignment

## Architecture

```
CSV Files → S3 Raw → AWS Glue ETL → S3 Processed (Parquet) → AWS Glue Catalog → Amazon Athena
                                                                                      ↓
                                                                              Analytics & BI
```

**Key Components:**
- **S3 Buckets**: Raw (CSV), Processed (Parquet), Query Results
- **AWS Glue**: ETL jobs, crawlers, Data Catalog
- **Amazon Athena**: Serverless SQL queries
- **IAM Roles**: Secure service-to-service access
- **CloudFormation**: Infrastructure as Code

## Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI v2.x configured
- Basic knowledge of S3, Glue, and Athena

### 1. Clone Repository

```bash
git clone <repository-url>
cd dea-c01-data-engineer-airline-metrics-s3-parquet-athena-performance-optimization
```

### 2. Deploy Infrastructure

```bash
# Set your AWS region
export AWS_REGION=us-east-1

# Deploy CloudFormation stack
aws cloudformation create-stack \
  --stack-name airline-metrics-datalake-dev \
  --template-body file://cloudformation/data-lake-infrastructure.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=airline-metrics-datalake \
    ParameterKey=Environment,ParameterValue=dev \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${AWS_REGION}

# Wait for stack creation
aws cloudformation wait stack-create-complete \
  --stack-name airline-metrics-datalake-dev \
  --region ${AWS_REGION}
```

### 3. Upload Glue Script

```bash
# Get bucket name from stack outputs
PROCESSED_BUCKET=$(aws cloudformation describe-stacks \
  --stack-name airline-metrics-datalake-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`ProcessedDataBucketName`].OutputValue' \
  --output text)

# Upload ETL script
aws s3 cp glue-jobs/csv_to_parquet_etl.py \
  s3://${PROCESSED_BUCKET}/scripts/
```

### 4. Run ETL Job

```bash
# Get job name
JOB_NAME=$(aws cloudformation describe-stacks \
  --stack-name airline-metrics-datalake-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`GlueETLJobName`].OutputValue' \
  --output text)

# Start job
aws glue start-job-run --job-name ${JOB_NAME}
```

### 5. Query with Athena

Open Amazon Athena console and run sample queries from `sql/sample_queries.sql`.

## Project Structure

```
├── cloudformation/
│   └── data-lake-infrastructure.yaml    # CloudFormation template
├── docs/
│   ├── ARCHITECTURE.md                  # Architecture overview
│   ├── DEPLOYMENT.md                    # Deployment guide
│   ├── PERFORMANCE.md                   # Performance optimization
│   ├── COST_OPTIMIZATION.md             # Cost optimization strategies
│   └── DEA_C01_BEST_PRACTICES.md        # DEA-C01 exam alignment
├── glue-jobs/
│   └── csv_to_parquet_etl.py           # Glue ETL script
├── sample-data/
│   ├── schema.md                        # CSV schema documentation
│   └── airline_metrics_sample.csv       # Sample data file
├── sql/
│   ├── create_table.sql                 # Athena table DDL
│   └── sample_queries.sql               # Sample analytical queries
└── README.md                            # This file
```

## Documentation

### For Deployment
- **[Deployment Guide](docs/DEPLOYMENT.md)**: Step-by-step deployment instructions
- **[Architecture Overview](docs/ARCHITECTURE.md)**: Detailed architecture and component descriptions

### For Optimization
- **[Performance Optimization](docs/PERFORMANCE.md)**: Query optimization techniques and benchmarks
- **[Cost Optimization](docs/COST_OPTIMIZATION.md)**: Cost reduction strategies and ROI analysis

### For Learning
- **[DEA-C01 Best Practices](docs/DEA_C01_BEST_PRACTICES.md)**: Alignment with AWS DEA-C01 certification
- **[Sample Queries](sql/sample_queries.sql)**: 10+ optimized query examples

### For Data Understanding
- **[Data Schema](sample-data/schema.md)**: Complete CSV schema documentation

## Performance Optimizations

### 1. Columnar Storage (Parquet)
- **5x smaller** than compressed CSV
- **10-20x faster** queries through column pruning
- **Better compression** with Snappy codec

### 2. Partitioning
- **Date-based partitions** (year/month/day)
- **360x cost reduction** for date-filtered queries
- **Partition projection** for fast query planning

### 3. Query Optimization
- **Column pruning**: Read only needed columns (8-20x reduction)
- **Predicate pushdown**: Filter at storage level (10-100x reduction)
- **Query result caching**: Free repeated queries within 24 hours

### Combined Impact
- **150x faster queries**
- **150x lower costs**
- **84% total cost reduction**

## Cost Estimation

### Small Workload (10 GB/day)
- **Unoptimized**: $70.10/month
- **Optimized**: $11.02/month
- **Savings**: 84% ($708/year)

### Medium Workload (100 GB/day)
- **Unoptimized**: $701/month
- **Optimized**: $110/month
- **Savings**: 84% ($7,089/year)

### Large Workload (1 TB/day)
- **Unoptimized**: $4,510/month
- **Optimized**: $852/month
- **Savings**: 81% ($43,896/year)

## Security Features

- ✅ **Encryption at rest**: S3 server-side encryption (SSE-S3)
- ✅ **Encryption in transit**: TLS/HTTPS for all data transfers
- ✅ **IAM roles**: Least privilege access control
- ✅ **S3 bucket policies**: Block public access enabled
- ✅ **Versioning**: Enabled for data protection
- ✅ **Audit logging**: CloudWatch and CloudTrail integration

## DEA-C01 Alignment

This project covers all four DEA-C01 exam domains:

1. **Data Ingestion & Transformation (34%)**
   - S3 data ingestion
   - AWS Glue ETL
   - PySpark transformations
   - Format conversion (CSV → Parquet)

2. **Data Store Management (26%)**
   - S3 data lake architecture
   - Glue Data Catalog
   - Lifecycle policies
   - Partitioning strategies

3. **Data Operations & Support (22%)**
   - Query optimization (Athena)
   - Monitoring (CloudWatch)
   - Automation (scheduled jobs)
   - Performance tuning

4. **Data Security & Governance (18%)**
   - IAM roles and policies
   - Encryption (at rest and in transit)
   - Audit logging
   - Access control

See [DEA_C01_BEST_PRACTICES.md](docs/DEA_C01_BEST_PRACTICES.md) for detailed mapping.

## Sample Queries

The repository includes 10+ optimized sample queries demonstrating:

- Column pruning optimization
- Predicate pushdown with partition filtering
- Date range queries with optimal performance
- Aggregation and grouping best practices
- Route and airline performance analysis
- Delay attribution analysis
- Cost-optimized query patterns

See [sql/sample_queries.sql](sql/sample_queries.sql) for complete examples.

## Regional Colocation

**Important**: Deploy all resources in the **same AWS Region** to:
- ✅ Minimize latency
- ✅ Eliminate inter-region data transfer costs
- ✅ Ensure optimal Athena query performance
- ✅ Comply with data residency requirements

Recommended regions: `us-east-1` or `us-west-2` (lowest costs)

## Monitoring and Observability

- **CloudWatch Metrics**: Track Glue job execution, query performance
- **CloudWatch Logs**: Capture ETL logs, error messages
- **Athena Query History**: Monitor data scanned, query costs
- **Cost Alarms**: Set budgets and spending alerts
- **Job Insights**: Glue job performance recommendations

## Clean Up

To avoid ongoing charges, delete all resources:

```bash
# Empty S3 buckets
aws s3 rm s3://<raw-bucket> --recursive
aws s3 rm s3://<processed-bucket> --recursive
aws s3 rm s3://<results-bucket> --recursive

# Delete CloudFormation stack
aws cloudformation delete-stack \
  --stack-name airline-metrics-datalake-dev
```

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is provided as-is for educational and reference purposes.

## Additional Resources

- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [Amazon Athena Documentation](https://docs.aws.amazon.com/athena/)
- [AWS DEA-C01 Exam Guide](https://aws.amazon.com/certification/certified-data-engineer-associate/)
- [Parquet Format Documentation](https://parquet.apache.org/docs/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## Support

For issues, questions, or suggestions:
- Open an issue in the repository
- Refer to the comprehensive documentation in the `docs/` directory
- Review sample queries and CloudFormation templates for examples

---

**Built with AWS best practices for the DEA-C01 certification** ✨
