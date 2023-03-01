provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_instance" "example" {
  ami = "ami-0e38c97339cddf4bd"
  instance_type	= "t2.micro"

  tags = {
    Name = "terraform-example"
  }

}
