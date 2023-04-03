provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_iam_user" "example" {
  count = 3

  name  = "${var.user_name_prefix}.${count.index}"
}

