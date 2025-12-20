variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "airline-metrics-datalake"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "glue_database_name" {
  description = "Name of the Glue database"
  type        = string
  default     = "airline_metrics"
}

variable "glue_table_name" {
  description = "Name of the Glue table"
  type        = string
  default     = "flights"
}
