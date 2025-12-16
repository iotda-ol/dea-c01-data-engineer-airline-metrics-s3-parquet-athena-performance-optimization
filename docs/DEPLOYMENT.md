# Deployment Guide

## Prerequisites

### AWS Account Requirements
- AWS Account with appropriate permissions
- AWS CLI installed and configured
- IAM permissions to create:
  - S3 buckets
  - IAM roles and policies
  - Glue databases, crawlers, and jobs
  - Athena workgroups
  - CloudFormation stacks

### Local Development Tools
- AWS CLI v2.x or higher
- Python 3.9 or higher (for testing Glue scripts locally)
- Git (for version control)
- Text editor or IDE

### AWS Service Limits
Check the following service limits in your account:
- S3 buckets: Default 100 per account
- Glue concurrent jobs: Default 25 per account
- Glue DPUs: Default 100 per account
- Athena concurrent queries: Default 20 per workgroup

## Step 1: Clone the Repository

```bash
git clone <repository-url>
cd dea-c01-data-engineer-airline-metrics-s3-parquet-athena-performance-optimization
```

## Step 2: Configure AWS CLI

```bash
# Configure AWS CLI with your credentials
aws configure

# Verify configuration
aws sts get-caller-identity

# Set your AWS region (choose one close to your data/users)
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

## Step 3: Deploy Infrastructure with CloudFormation

### Option A: Deploy via AWS Console

1. Open AWS CloudFormation Console
2. Click "Create stack" → "With new resources"
3. Choose "Upload a template file"
4. Upload `cloudformation/data-lake-infrastructure.yaml`
5. Enter stack name: `airline-metrics-datalake-dev`
6. Configure parameters:
   - **ProjectName**: `airline-metrics-datalake`
   - **Environment**: `dev` (or `staging`, `prod`)
7. Review and create stack
8. Wait for stack creation (typically 5-10 minutes)

### Option B: Deploy via AWS CLI

```bash
# Set parameters
PROJECT_NAME="airline-metrics-datalake"
ENVIRONMENT="dev"
STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}"

# Deploy CloudFormation stack
aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-body file://cloudformation/data-lake-infrastructure.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=${PROJECT_NAME} \
    ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${AWS_REGION}

# Wait for stack creation to complete
aws cloudformation wait stack-create-complete \
  --stack-name ${STACK_NAME} \
  --region ${AWS_REGION}

# Get stack outputs
aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query 'Stacks[0].Outputs' \
  --region ${AWS_REGION}
```

### Verify Stack Creation

```bash
# Check stack status
aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query 'Stacks[0].StackStatus' \
  --region ${AWS_REGION}

# List created resources
aws cloudformation list-stack-resources \
  --stack-name ${STACK_NAME} \
  --region ${AWS_REGION}
```

## Step 4: Upload Glue ETL Script

```bash
# Get bucket names from stack outputs
PROCESSED_BUCKET=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query 'Stacks[0].Outputs[?OutputKey==`ProcessedDataBucketName`].OutputValue' \
  --output text \
  --region ${AWS_REGION})

# Create scripts directory in S3
aws s3 mb s3://${PROCESSED_BUCKET}/scripts/

# Upload Glue ETL script
aws s3 cp glue-jobs/csv_to_parquet_etl.py \
  s3://${PROCESSED_BUCKET}/scripts/csv_to_parquet_etl.py \
  --region ${AWS_REGION}

# Verify upload
aws s3 ls s3://${PROCESSED_BUCKET}/scripts/
```

## Step 5: Upload Sample Data (Optional)

```bash
# Get raw bucket name
RAW_BUCKET=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query 'Stacks[0].Outputs[?OutputKey==`RawDataBucketName`].OutputValue' \
  --output text \
  --region ${AWS_REGION})

# Create directory for today's date
TODAY=$(date +%Y-%m-%d)
aws s3 mb s3://${RAW_BUCKET}/airline_metrics/${TODAY}/

# Upload sample CSV file
aws s3 cp sample-data/airline_metrics_sample.csv \
  s3://${RAW_BUCKET}/airline_metrics/${TODAY}/ \
  --region ${AWS_REGION}

# Verify upload
aws s3 ls s3://${RAW_BUCKET}/airline_metrics/${TODAY}/
```

## Step 6: Run Glue ETL Job

### Option A: Via AWS Console

1. Open AWS Glue Console
2. Navigate to "ETL jobs" → "Jobs"
3. Find job: `airline-metrics-csv-to-parquet-dev`
4. Click "Run job"
5. Monitor job execution in "Runs" tab
6. Check CloudWatch Logs for details

### Option B: Via AWS CLI

```bash
# Get job name
JOB_NAME=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query 'Stacks[0].Outputs[?OutputKey==`GlueETLJobName`].OutputValue' \
  --output text \
  --region ${AWS_REGION})

# Start Glue job
JOB_RUN_ID=$(aws glue start-job-run \
  --job-name ${JOB_NAME} \
  --region ${AWS_REGION} \
  --query 'JobRunId' \
  --output text)

echo "Job started with ID: ${JOB_RUN_ID}"

# Monitor job status
aws glue get-job-run \
  --job-name ${JOB_NAME} \
  --run-id ${JOB_RUN_ID} \
  --query 'JobRun.JobRunState' \
  --region ${AWS_REGION}

# Wait for job completion (check every 30 seconds)
while true; do
  STATUS=$(aws glue get-job-run \
    --job-name ${JOB_NAME} \
    --run-id ${JOB_RUN_ID} \
    --query 'JobRun.JobRunState' \
    --output text \
    --region ${AWS_REGION})
  
  echo "Job status: ${STATUS}"
  
  if [[ "${STATUS}" == "SUCCEEDED" ]]; then
    echo "Job completed successfully!"
    break
  elif [[ "${STATUS}" == "FAILED" || "${STATUS}" == "ERROR" ]]; then
    echo "Job failed!"
    exit 1
  fi
  
  sleep 30
done
```

## Step 7: Run Glue Crawler

```bash
# Get crawler name
CRAWLER_NAME=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query 'Stacks[0].Outputs[?OutputKey==`GlueCrawlerName`].OutputValue' \
  --output text \
  --region ${AWS_REGION})

# Start crawler
aws glue start-crawler \
  --name ${CRAWLER_NAME} \
  --region ${AWS_REGION}

# Monitor crawler status
aws glue get-crawler \
  --name ${CRAWLER_NAME} \
  --query 'Crawler.State' \
  --region ${AWS_REGION}

# Wait for crawler to complete
while true; do
  STATUS=$(aws glue get-crawler \
    --name ${CRAWLER_NAME} \
    --query 'Crawler.State' \
    --output text \
    --region ${AWS_REGION})
  
  echo "Crawler status: ${STATUS}"
  
  if [[ "${STATUS}" == "READY" ]]; then
    echo "Crawler completed!"
    break
  fi
  
  sleep 10
done
```

## Step 8: Create Athena Table

### Option A: Via AWS Console

1. Open Amazon Athena Console
2. Select workgroup: `airline-metrics-workgroup-dev`
3. Open Query Editor
4. Copy SQL from `sql/create_table.sql`
5. Replace `<PROCESSED_BUCKET_NAME>` with your bucket name
6. Replace `<DATABASE_NAME>` with your database name
7. Execute query

### Option B: Via AWS CLI

```bash
# Get database name
DATABASE_NAME=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query 'Stacks[0].Outputs[?OutputKey==`GlueDatabaseName`].OutputValue' \
  --output text \
  --region ${AWS_REGION})

# Get workgroup name
WORKGROUP_NAME=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query 'Stacks[0].Outputs[?OutputKey==`AthenaWorkgroupName`].OutputValue' \
  --output text \
  --region ${AWS_REGION})

# Create SQL file with replaced values
sed "s/<PROCESSED_BUCKET_NAME>/${PROCESSED_BUCKET}/g; s/<DATABASE_NAME>/${DATABASE_NAME}/g" \
  sql/create_table.sql > /tmp/create_table_updated.sql

# Execute query (Note: AWS CLI doesn't directly support query execution)
# Use AWS SDK or boto3 for programmatic execution
echo "Table creation SQL prepared. Execute manually via Athena Console or use boto3."
```

### Option C: Use boto3 (Python)

```python
import boto3
import time

# Initialize clients
athena = boto3.client('athena', region_name='us-east-1')

# Read SQL file
with open('sql/create_table.sql', 'r') as f:
    sql = f.read()

# Replace placeholders
sql = sql.replace('<PROCESSED_BUCKET_NAME>', processed_bucket)
sql = sql.replace('<DATABASE_NAME>', database_name)

# Execute query
response = athena.start_query_execution(
    QueryString=sql,
    QueryExecutionContext={'Database': database_name},
    WorkGroup=workgroup_name
)

query_execution_id = response['QueryExecutionId']
print(f"Query started: {query_execution_id}")

# Wait for completion
while True:
    status = athena.get_query_execution(QueryExecutionId=query_execution_id)
    state = status['QueryExecution']['Status']['State']
    
    if state in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
        print(f"Query {state}")
        break
    
    time.sleep(2)
```

## Step 9: Verify Deployment

### Check S3 Buckets

```bash
# List all created buckets
echo "Raw Bucket:"
aws s3 ls s3://${RAW_BUCKET}/airline_metrics/ --recursive --region ${AWS_REGION}

echo "Processed Bucket:"
aws s3 ls s3://${PROCESSED_BUCKET}/airline_metrics/ --recursive --region ${AWS_REGION}
```

### Check Glue Catalog

```bash
# List databases
aws glue get-databases --region ${AWS_REGION}

# Get table details
aws glue get-table \
  --database-name ${DATABASE_NAME} \
  --name airline_metrics \
  --region ${AWS_REGION}

# List partitions
aws glue get-partitions \
  --database-name ${DATABASE_NAME} \
  --table-name airline_metrics \
  --max-results 10 \
  --region ${AWS_REGION}
```

### Run Test Query in Athena

```sql
-- Simple test query
SELECT COUNT(*) AS total_flights
FROM airline_metrics
WHERE year = 2024 AND month = 1
LIMIT 10;
```

## Step 10: Configure Scheduled Jobs (Optional)

### Schedule Glue ETL Job

```bash
# Create CloudWatch Events rule for daily execution at 2 AM UTC
aws events put-rule \
  --name "${PROJECT_NAME}-daily-etl-${ENVIRONMENT}" \
  --schedule-expression "cron(0 2 * * ? *)" \
  --state ENABLED \
  --region ${AWS_REGION}

# Add Glue job as target
JOB_ARN="arn:aws:glue:${AWS_REGION}:${AWS_ACCOUNT_ID}:job/${JOB_NAME}"

aws events put-targets \
  --rule "${PROJECT_NAME}-daily-etl-${ENVIRONMENT}" \
  --targets "Id=1,Arn=${JOB_ARN},RoleArn=<GLUE_ROLE_ARN>" \
  --region ${AWS_REGION}
```

### Schedule Glue Crawler

```bash
# Update crawler schedule
aws glue update-crawler \
  --name ${CRAWLER_NAME} \
  --schedule "cron(0 3 * * ? *)" \
  --region ${AWS_REGION}
```

## Troubleshooting

### Glue Job Failures

```bash
# Get job run details
aws glue get-job-run \
  --job-name ${JOB_NAME} \
  --run-id ${JOB_RUN_ID} \
  --region ${AWS_REGION}

# View CloudWatch Logs
LOG_GROUP="/aws-glue/jobs/output"
aws logs tail ${LOG_GROUP} --follow --region ${AWS_REGION}
```

### Athena Query Failures

1. Check query execution details in Athena Console
2. Verify S3 bucket permissions
3. Ensure Glue table schema matches Parquet files
4. Check partition existence: `SHOW PARTITIONS airline_metrics;`

### Permission Issues

```bash
# Verify IAM role trust relationships
aws iam get-role --role-name ${PROJECT_NAME}-glue-service-role-${ENVIRONMENT}

# Check role policies
aws iam list-attached-role-policies \
  --role-name ${PROJECT_NAME}-glue-service-role-${ENVIRONMENT}
```

## Clean Up (Delete All Resources)

```bash
# Empty S3 buckets first
aws s3 rm s3://${RAW_BUCKET} --recursive --region ${AWS_REGION}
aws s3 rm s3://${PROCESSED_BUCKET} --recursive --region ${AWS_REGION}
aws s3 rm s3://${ATHENA_RESULTS_BUCKET} --recursive --region ${AWS_REGION}

# Delete CloudFormation stack
aws cloudformation delete-stack \
  --stack-name ${STACK_NAME} \
  --region ${AWS_REGION}

# Wait for deletion
aws cloudformation wait stack-delete-complete \
  --stack-name ${STACK_NAME} \
  --region ${AWS_REGION}

echo "All resources deleted successfully!"
```

## Post-Deployment Steps

1. **Test Queries**: Run sample queries from `sql/sample_queries.sql`
2. **Monitor Costs**: Set up AWS Cost Explorer and budgets
3. **Enable Alerts**: Configure CloudWatch alarms for job failures
4. **Document**: Update configurations and share with team
5. **Backup**: Export CloudFormation template and scripts

## Security Best Practices

- Enable MFA for AWS account
- Use IAM roles instead of access keys where possible
- Enable CloudTrail for audit logging
- Implement least privilege access
- Regularly rotate credentials
- Enable S3 access logging
- Use VPC endpoints for private connectivity

## Next Steps

- Explore sample queries in `sql/sample_queries.sql`
- Review performance optimization guide in `docs/PERFORMANCE.md`
- Check cost optimization strategies in `docs/COST_OPTIMIZATION.md`
- Read DEA-C01 best practices in `docs/DEA_C01_BEST_PRACTICES.md`
