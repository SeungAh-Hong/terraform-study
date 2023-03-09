provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_launch_configuration" "launch_config" {
    image_id = "ami-0e38c97339cddf4bd"                 # EC2 인스턴스에서는 ami 였었습니다 
    instance_type = "t2.micro"
    security_groups = [aws_security_group.webserver-sg.id] # EC2 인스턴스에서는 vpc_security_group_ids 였었습니다.

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
    
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "webserver-asg" {
    launch_configuration = aws_launch_configuration.launch_config.name # name 변수는 시작 구성의 Name 값 설정
    vpc_zone_identifier = data.aws_subnet_ids.default-subnet.ids
    min_size = 2
    max_size = 10

    tag {
        key                 = "Name"
        value               = "terraform-web-asg"
        propagate_at_launch = "true"
    }
}

resource "aws_security_group" "webserver-sg" {
    name = "terraform-example-instance"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

variable "server_port" {
    description = "The port the server will user for HTTP requests"
    type        = number
    default     = 8080
}
