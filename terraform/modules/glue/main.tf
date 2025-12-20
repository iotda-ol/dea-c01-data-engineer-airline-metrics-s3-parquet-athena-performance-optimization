/**
 * Glue Module
 * Creates AWS Glue resources: database, crawler, and ETL jobs
 */

# Glue Database
resource "aws_glue_catalog_database" "this" {
  name        = var.database_name
  description = "Database for ${var.project_name} ${var.environment} airline metrics"

  catalog_id = var.catalog_id
}

# Glue Crawler
resource "aws_glue_crawler" "this" {
  name          = "${var.project_name}-crawler-${var.environment}"
  role          = var.glue_role_arn
  database_name = aws_glue_catalog_database.this.name
  description   = "Crawler for discovering schema in processed data"

  s3_target {
    path = "s3://${var.processed_bucket}/data/"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
    }
  })

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  tags = var.tags
}

# Glue ETL Job
resource "aws_glue_job" "etl_job" {
  name     = "${var.project_name}-etl-job-${var.environment}"
  role_arn = var.glue_role_arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.scripts_bucket}/scripts/glue_job_main.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"            = "python"
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--enable-metrics"          = "true"
    "--enable-spark-ui"         = "true"
    "--spark-event-logs-path"   = "s3://${var.scripts_bucket}/spark-logs/"
    "--TempDir"                 = "s3://${var.scripts_bucket}/temp/"
    "--SOURCE_S3_PATH"          = "s3://${var.raw_bucket}/data/"
    "--TARGET_S3_PATH"          = "s3://${var.processed_bucket}/data/"
    "--DATABASE_NAME"           = aws_glue_catalog_database.this.name
    "--TABLE_NAME"              = var.table_name
    "--enable-continuous-cloudwatch-log" = "true"
  }

  max_retries       = var.max_retries
  timeout           = var.timeout_minutes
  glue_version      = "4.0"
  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers

  tags = var.tags
}
