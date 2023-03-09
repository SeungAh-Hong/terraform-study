data "aws_vpc" "webserver-vpc" {
  default = true
}

data "aws_subnet_ids" "default-subnet" {
  vpc_id = data.aws_vpc.webserver-vpc.id
}