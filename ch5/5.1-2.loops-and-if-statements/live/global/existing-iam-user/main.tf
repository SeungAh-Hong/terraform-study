

provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_iam_user" "existing_user" {
  # terraform import 명령 사용을 연습 할 수 있도록 
  # 이미 존재하는 IAM 사용자의 사용자 이름으로 변경해야합니다.
  # "terraform apply"명령어르 사용하면 에러가 발생합니다.
  # 먼저 terraform import aws_iam_user.existing_user (EXISTING_IAM_USER_NAME) 명령어를 실행합니다.
  name = "terraform.user"
}

