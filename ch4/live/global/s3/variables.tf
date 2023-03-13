variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  default     = "terraform-state-seungah"
  type        = string
}

variable "table_name" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  default     = "terraform-locks-seungah"
  type        = string
}