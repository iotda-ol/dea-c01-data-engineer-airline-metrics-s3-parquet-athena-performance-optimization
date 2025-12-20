terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data source for AWS account ID
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# S3 Buckets
module "raw_bucket" {
  source = "../../modules/s3"

  bucket_name       = "${var.project_name}-raw-${var.environment}-${local.account_id}"
  purpose           = "RawCSVStorage"
  enable_versioning = true
  tags              = local.common_tags

  lifecycle_rules = [
    {
      id     = "TransitionToIA"
      status = "Enabled"
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
    }
  ]
}

module "processed_bucket" {
  source = "../../modules/s3"

  bucket_name       = "${var.project_name}-processed-${var.environment}-${local.account_id}"
  purpose           = "ProcessedParquetStorage"
  enable_versioning = true
  tags              = local.common_tags

  lifecycle_rules = [
    {
      id     = "TransitionToIA"
      status = "Enabled"
      transitions = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]
    }
  ]
}

module "results_bucket" {
  source = "../../modules/s3"

  bucket_name       = "${var.project_name}-athena-results-${var.environment}-${local.account_id}"
  purpose           = "AthenaQueryResults"
  enable_versioning = false
  tags              = local.common_tags

  lifecycle_rules = [
    {
      id     = "DeleteOldResults"
      status = "Enabled"
      expiration = {
        days = 30
      }
    }
  ]
}

# IAM Roles
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  s3_buckets = [
    module.raw_bucket.bucket_arn,
    module.processed_bucket.bucket_arn,
    module.results_bucket.bucket_arn
  ]
}

# Glue Resources
module "glue" {
  source = "../../modules/glue"

  project_name      = var.project_name
  environment       = var.environment
  database_name     = var.glue_database_name
  table_name        = var.glue_table_name
  glue_role_arn     = module.iam.glue_role_arn
  raw_bucket        = module.raw_bucket.bucket_name
  processed_bucket  = module.processed_bucket.bucket_name
  scripts_bucket    = module.processed_bucket.bucket_name
  catalog_id        = local.account_id
  tags              = local.common_tags
}

# Athena Resources
module "athena" {
  source = "../../modules/athena"

  project_name   = var.project_name
  environment    = var.environment
  database_name  = module.glue.database_name
  table_name     = var.glue_table_name
  results_bucket = module.results_bucket.bucket_name
  tags           = local.common_tags
}
