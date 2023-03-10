provider "aws" {
    region = "ap-northeast-2"
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "terraform-state-seungah"

    force_destroy = true ####

    # # 실수로 S3 버킷 삭제를 방지
    # lifecycle {
    #     prevent_destroy = true
    # }

    # 코드 이력 관리 위해 상태 파일 버전 관리 활성화
    versioning {
        enabled = true
    }

    # 서버 측 암호화 활성화

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}

resource "aws_dynamodb_table" "terraform_locks" {
    name = "terraform-locks-seungah"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}

terraform {
    backend "s3" {
        bucket          = "terraform-state-seungah"
        key             = "global/s3/terraform.tfstate"
        region          = "ap-northeast-2"
        dynamodb_table  = "terraform-locks-seungah"
        encrypt         = true ####
    }
}

output "s3_bucket_arn" {
    value               = aws_s3_bucket.terraform_state.arn
    description         = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
    value               = aws_dynamodb_table.terraform_locks.name
    description         = "The name of the DynamoDB table"
}