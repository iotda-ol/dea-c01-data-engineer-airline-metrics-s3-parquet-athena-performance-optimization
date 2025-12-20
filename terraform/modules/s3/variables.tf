variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
}

variable "purpose" {
  description = "Purpose of the bucket (e.g., RawStorage, ProcessedStorage)"
  type        = string
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type        = any
  default     = null
}

variable "tags" {
  description = "Additional tags for the bucket"
  type        = map(string)
  default     = {}
}
