provider "aws" { 
    region = "ap-northeast-2"
}

terraform {
  backend "s3" {
    # This backend configuration is filled in automatically at test time by Terratest. If you wish to run this example
    # manually, uncomment and fill in the config below.

    bucket         = "terraform-state-seungah"
    key            = "prod/data-stores/mysql/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-locks-seungah"
    encrypt        = true
  }
}

resource "aws_db_instance" "instance" {
    identifier_prefix = "terraform-up-and-running"
    engine = "mysql"
    allocated_storage = 10
    instance_class = "db.t2.micro"
    skip_final_snapshot = true
    db_name = var.db_name
    username = "admin"
    password = var.db_password

    # password = data.aws_secretsmanager_secret_version.db_password.secret_string
}

# data "aws_secretsmanager_secret_version" "db_password" {
#     secret_id = "mysql-master-password-stage"
# }
