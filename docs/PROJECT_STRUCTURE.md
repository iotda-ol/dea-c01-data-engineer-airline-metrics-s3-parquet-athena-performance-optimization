# Modular Project Structure Documentation

This document explains the newly reorganized, modular project structure that maximizes code reusability and follows best practices.

## 📁 Project Structure

```
.
├── terraform/                      # Infrastructure as Code (Terraform modules)
│   ├── modules/                    # Reusable Terraform modules
│   │   ├── s3/                     # S3 bucket module
│   │   │   ├── main.tf            # S3 resource definitions
│   │   │   ├── variables.tf       # Module inputs
│   │   │   └── outputs.tf         # Module outputs
│   │   ├── glue/                   # AWS Glue module
│   │   │   ├── main.tf            # Glue resources (database, crawler, jobs)
│   │   │   ├── variables.tf       # Module inputs
│   │   │   └── outputs.tf         # Module outputs
│   │   ├── iam/                    # IAM roles and policies module
│   │   │   ├── main.tf            # IAM resource definitions
│   │   │   ├── variables.tf       # Module inputs
│   │   │   └── outputs.tf         # Module outputs
│   │   └── athena/                 # Amazon Athena module
│   │       ├── main.tf            # Athena workgroup configuration
│   │       ├── variables.tf       # Module inputs
│   │       └── outputs.tf         # Module outputs
│   └── environments/               # Environment-specific configurations
│       ├── dev/                    # Development environment
│       │   ├── main.tf            # Module composition for dev
│       │   ├── variables.tf       # Dev-specific variables
│       │   └── outputs.tf         # Dev outputs
│       ├── staging/                # Staging environment (future)
│       └── prod/                   # Production environment (future)
│
├── python/                         # Python codebase
│   ├── src/                        # Source code
│   │   ├── __init__.py            # Package initialization
│   │   ├── config/                 # Configuration management
│   │   │   ├── __init__.py        # Config package
│   │   │   └── settings.py        # Configuration classes
│   │   ├── etl/                    # ETL modules
│   │   │   ├── __init__.py        # ETL package
│   │   │   ├── csv_to_parquet.py  # Modular ETL class
│   │   │   └── glue_job_main.py   # Glue job entry point
│   │   ├── utils/                  # Utility modules
│   │   │   ├── __init__.py        # Utils package
│   │   │   └── s3_utils.py        # S3 operations utilities
│   │   └── validators/             # Data validation modules
│   │       ├── __init__.py        # Validators package
│   │       └── data_validator.py  # Data quality validators
│   └── tests/                      # Test suites
│       ├── __init__.py            # Test package
│       ├── unit/                   # Unit tests
│       └── integration/            # Integration tests
│
├── scripts/                        # Automation scripts
├── data/                           # Data storage
│   ├── raw/                        # Raw CSV files (gitignored)
│   ├── processed/                  # Processed Parquet files (gitignored)
│   └── sample/                     # Sample data files
│
├── docs/                           # Documentation
│   ├── 100_STEP_GUIDE.md          # Comprehensive 100-step guide
│   ├── ARCHITECTURE.md             # Architecture documentation
│   ├── DEPLOYMENT.md               # Deployment guide
│   ├── PERFORMANCE.md              # Performance optimization guide
│   ├── COST_OPTIMIZATION.md        # Cost optimization strategies
│   └── DEA_C01_BEST_PRACTICES.md  # AWS DEA-C01 best practices
│
├── notebooks/                      # Jupyter notebooks (for analysis)
├── sql/                            # SQL queries
│   ├── create_table.sql           # Table DDL
│   └── sample_queries.sql         # Sample analytical queries
│
├── requirements.txt                # Python dependencies
├── Makefile                        # Common automation tasks
├── .gitignore                      # Git ignore patterns
└── README.md                       # Main project documentation
```

## 🎯 Key Improvements

### 1. Maximum Modularity
- **Terraform Modules**: Each AWS service has its own reusable module (S3, Glue, IAM, Athena)
- **Python Modules**: Organized by function (etl, utils, config, validators)
- **Environment Separation**: Dev/Staging/Prod environments use same modules with different configs

### 2. Reusable Code
- **Terraform**: Modules can be reused across environments
- **Python**: Classes and functions designed for maximum reusability
- **Configuration**: Centralized configuration management

### 3. Organized Structure
- **Limited Loose Files**: All files in appropriate folders
- **Clear Separation**: Infrastructure, code, data, docs, scripts separated
- **Package Structure**: Proper Python package hierarchy with `__init__.py`

### 4. Python & Terraform Focus
- **Terraform**: 100% of infrastructure (converted from CloudFormation)
- **Python**: All ETL code, utilities, and tooling
- **Minimal Other Types**: Only essential SQL and Markdown docs

## 🚀 Usage

### Terraform Module Usage

```hcl
# Example: Use S3 module in your environment
module "my_bucket" {
  source = "../../modules/s3"
  
  bucket_name       = "my-data-bucket"
  purpose           = "DataStorage"
  enable_versioning = true
  tags              = { Environment = "dev" }
}
```

### Python Module Usage

```python
# Example: Use ETL module
from src.etl import CSVToParquetETL
from pyspark.sql import SparkSession

spark = SparkSession.builder.getOrCreate()
etl = CSVToParquetETL(spark)
etl.process("s3://raw-bucket/data/", "s3://processed-bucket/data/")
```

```python
# Example: Use S3 utilities
from src.utils import S3Utils

s3 = S3Utils(region='us-east-1')
s3.upload_file('local.csv', 'my-bucket', 'data/file.csv')
files = s3.list_objects('my-bucket', 'data/')
```

```python
# Example: Use data validator
from src.validators import DataValidator

validator = DataValidator()
null_counts = validator.check_nulls(df, ['column1', 'column2'])
duplicates = validator.check_duplicates(df, ['id'])
```

## 🛠️ Development Workflow

```bash
# 1. Install dependencies
make install

# 2. Initialize Terraform
make init

# 3. Plan infrastructure changes
make plan

# 4. Apply infrastructure
make apply

# 5. Run tests
make test

# 6. Format code
make format

# 7. Lint code
make lint

# 8. Clean temporary files
make clean

# 9. Destroy infrastructure (when done)
make destroy
```

## 📚 Module Documentation

### Terraform Modules

#### S3 Module
**Purpose**: Create S3 buckets with encryption, versioning, and lifecycle policies

**Inputs**:
- `bucket_name`: Globally unique bucket name
- `purpose`: Bucket purpose (RawStorage, ProcessedStorage, etc.)
- `enable_versioning`: Enable/disable versioning
- `lifecycle_rules`: List of lifecycle rules
- `tags`: Additional tags

**Outputs**:
- `bucket_id`: Bucket ID
- `bucket_arn`: Bucket ARN
- `bucket_name`: Bucket name

#### Glue Module
**Purpose**: Create Glue database, crawler, and ETL jobs

**Inputs**:
- `database_name`: Glue database name
- `table_name`: Glue table name
- `glue_role_arn`: IAM role ARN for Glue
- `raw_bucket`: Raw data bucket name
- `processed_bucket`: Processed data bucket name
- `scripts_bucket`: Scripts bucket name

**Outputs**:
- `database_name`: Database name
- `crawler_name`: Crawler name
- `etl_job_name`: ETL job name

#### IAM Module
**Purpose**: Create IAM roles and policies for AWS services

**Inputs**:
- `project_name`: Project name
- `environment`: Environment (dev/staging/prod)
- `s3_buckets`: List of S3 bucket ARNs for access

**Outputs**:
- `glue_role_arn`: Glue service role ARN
- `glue_role_name`: Glue service role name

#### Athena Module
**Purpose**: Configure Athena workgroup and named queries

**Inputs**:
- `database_name`: Glue database name
- `table_name`: Table name for queries
- `results_bucket`: S3 bucket for query results

**Outputs**:
- `workgroup_name`: Athena workgroup name
- `workgroup_arn`: Athena workgroup ARN

### Python Modules

#### Config Module
**Purpose**: Centralized configuration management

**Classes**:
- `AWSConfig`: AWS-specific settings
- `S3Config`: S3 bucket configuration
- `GlueConfig`: Glue configuration
- `AppConfig`: Complete application configuration

**Functions**:
- `load_config()`: Load configuration from environment variables
- `get_config()`: Get application configuration

#### ETL Module
**Purpose**: ETL transformations and processing

**Classes**:
- `CSVToParquetETL`: Convert CSV to Parquet with partitioning

**Methods**:
- `read_csv()`: Read CSV from S3
- `add_partition_columns()`: Add year/month/day partitions
- `cast_numeric_columns()`: Cast columns for optimization
- `write_parquet()`: Write to Parquet format
- `process()`: Complete ETL pipeline

#### Utils Module
**Purpose**: Reusable utility functions

**Classes**:
- `S3Utils`: S3 operations wrapper

**Methods**:
- `upload_file()`: Upload file to S3
- `download_file()`: Download file from S3
- `list_objects()`: List S3 objects
- `delete_object()`: Delete S3 object
- `object_exists()`: Check if object exists

#### Validators Module
**Purpose**: Data quality validation

**Classes**:
- `DataValidator`: Data quality checks

**Methods**:
- `check_nulls()`: Check for null values
- `check_duplicates()`: Check for duplicates
- `check_range()`: Validate value ranges
- `check_format()`: Validate data formats
- `get_data_quality_report()`: Generate quality report

## 🎓 Learning Resources

1. **100-Step Guide**: See `docs/100_STEP_GUIDE.md` for comprehensive novice-to-expert tutorial
2. **Architecture**: See `docs/ARCHITECTURE.md` for system design
3. **Deployment**: See `docs/DEPLOYMENT.md` for deployment instructions
4. **Performance**: See `docs/PERFORMANCE.md` for optimization techniques
5. **Cost Optimization**: See `docs/COST_OPTIMIZATION.md` for cost-saving strategies

## 🔄 Migration from Old Structure

The project has been refactored from:
- CloudFormation → Terraform modules
- Monolithic Python scripts → Modular Python packages
- Flat file structure → Organized folder hierarchy
- Limited reusability → Maximum code reuse

All functionality remains the same but is now better organized and more maintainable.

## 🤝 Contributing

When adding new features:
1. Add infrastructure to appropriate Terraform module
2. Add code to appropriate Python module
3. Write tests in `python/tests/`
4. Update documentation
5. Run `make format` and `make lint`
6. Run `make test` before committing

## 📝 License

This project is provided for educational and reference purposes.
