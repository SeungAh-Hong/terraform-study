variable "db_password" {
  type        = string
  description = "The password for the database"
}

variable "db_name" {
    type        = string
    default     = "database_prod"
}
