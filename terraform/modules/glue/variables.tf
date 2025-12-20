variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "database_name" {
  description = "Name of the Glue catalog database"
  type        = string
}

variable "table_name" {
  description = "Name of the Glue table"
  type        = string
}

variable "glue_role_arn" {
  description = "ARN of the Glue service role"
  type        = string
}

variable "raw_bucket" {
  description = "Raw data S3 bucket name"
  type        = string
}

variable "processed_bucket" {
  description = "Processed data S3 bucket name"
  type        = string
}

variable "scripts_bucket" {
  description = "Scripts S3 bucket name"
  type        = string
}

variable "catalog_id" {
  description = "AWS account ID for Glue catalog"
  type        = string
  default     = null
}

variable "max_retries" {
  description = "Maximum number of retries for Glue job"
  type        = number
  default     = 1
}

variable "timeout_minutes" {
  description = "Timeout for Glue job in minutes"
  type        = number
  default     = 60
}

variable "worker_type" {
  description = "Type of Glue worker (G.1X, G.2X, G.4X, G.8X)"
  type        = string
  default     = "G.1X"
}

variable "number_of_workers" {
  description = "Number of Glue workers"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
