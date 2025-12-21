variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "database_name" {
  description = "Name of the Glue database for queries"
  type        = string
}

variable "table_name" {
  description = "Name of the table to query"
  type        = string
}

variable "results_bucket" {
  description = "S3 bucket name for query results"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
