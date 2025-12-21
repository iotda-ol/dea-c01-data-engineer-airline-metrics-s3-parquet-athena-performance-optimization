output "raw_bucket_name" {
  description = "Name of the raw data bucket"
  value       = module.raw_bucket.bucket_name
}

output "processed_bucket_name" {
  description = "Name of the processed data bucket"
  value       = module.processed_bucket.bucket_name
}

output "results_bucket_name" {
  description = "Name of the Athena results bucket"
  value       = module.results_bucket.bucket_name
}

output "glue_database_name" {
  description = "Name of the Glue database"
  value       = module.glue.database_name
}

output "glue_crawler_name" {
  description = "Name of the Glue crawler"
  value       = module.glue.crawler_name
}

output "glue_etl_job_name" {
  description = "Name of the Glue ETL job"
  value       = module.glue.etl_job_name
}

output "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = module.athena.workgroup_name
}

output "glue_role_arn" {
  description = "ARN of the Glue service role"
  value       = module.iam.glue_role_arn
}
