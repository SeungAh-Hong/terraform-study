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

# 6단계
resource "aws_autoscaling_group" "webserver-asg" {
    launch_configuration = aws_launch_configuration.launch_config.name # name 변수는 시작 구성의 Name 값 설정
    #vpc_zone_identifier = data.aws_subnet_ids.default-subnet.ids
    availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]

    target_group_arns = [aws_lb_target_group.asg-tg.arn]
    health_check_type = "ELB"

    min_size = 2
    max_size = 10

    tag {
        key                 = "Name"
        value               = "terraform-web-asg"
        propagate_at_launch = "true"
    }
}

# 1단계. aws_alb 리소스 사용해 ALB 자체 작성 + 4단계 (sg 사용 지시))
resource "aws_lb" "webserver-alb" {
    name                    = "terraform-asg-alb"
    load_balancer_type      = "application"
    subnets                 = data.aws_subnet_ids.default-subnet.ids
    security_groups         = [aws_security_group.alb-sg.id]
}

# 2단계. aws_lb_listener 리소스 사용해 ALB 리스너 정의
resource "aws_lb_listener" "http" {
    load_balancer_arn       = aws_lb.webserver-alb.arn
    port                    = 80
    protocol                = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

# 5단계
resource "aws_lb_target_group" "asg-tg" {
    name                    = "terraform-asg-example"
    port                    = var.server_port
    protocol                = "HTTP"
    vpc_id                  = data.aws_vpc.webserver-vpc.id

    health_check {
        path        = "/"
        protocol   = "HTTP"
        matcher     = "200"
        interval    = 15
        timeout     = 3
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }
}

# 3단계
resource "aws_security_group" "alb-sg" {
    name = "terraform-example-alb"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# 7단계
resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
            values = ["*"]
        }
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg-tg.arn
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

output "alb_dns_name" {
    value = aws_lb.webserver-alb.dns_name
    description = "The domain name of the load balancer"
}
