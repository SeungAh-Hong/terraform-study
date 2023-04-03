provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_iam_user" "example" {

  name = var.user_name

}
