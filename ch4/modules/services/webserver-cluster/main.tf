# provider "aws" {
#   region = "ap-northeast-2"
# }

data "template_file" "user_data" {
    # template = file("user-data.sh")
    template = file("${path.module}/user-data.sh")

    vars = {
        server_port = var.server_port
        db_address  = data.terraform_remote_state.db.outputs.address
        db_port     = data.terraform_remote_state.db.outputs.port
    }
}

# launch configuration
resource "aws_launch_configuration" "launch_config" {
    image_id = "ami-0e38c97339cddf4bd"
    instance_type = var.instance_type
    security_groups = [aws_security_group.webserver-sg.id]
    user_data = data.template_file.user_data.rendered
  
    lifecycle {
        create_before_destroy = true
    }
}

# web server의 autoscaling group
resource "aws_autoscaling_group" "webserver-asg" {
    launch_configuration = aws_launch_configuration.launch_config.name # name 변수는 시작 구성의 Name 값 설정
    #vpc_zone_identifier = data.aws_subnet_ids.default-subnet.ids
    availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]

    target_group_arns = [aws_lb_target_group.asg-tg.arn]
    health_check_type = "ELB"

    min_size = var.min_size
    max_size = var.max_size

    tag {
        key                 = "Name"
        # value               = "terraform-web-asg"
        value               = var.cluster_name
        propagate_at_launch = true
    }
}

# 1단계. aws_alb 리소스 사용해 ALB 자체 작성
# 4단계. 3단계에서 만든 sg 사용하도록 지시
resource "aws_lb" "webserver-alb" {
    # name                    = "terraform-asg-alb"
    name                    = var.cluster_name
    load_balancer_type      = "application"
    subnets                 = data.aws_subnet_ids.default-subnet.ids
    security_groups         = [aws_security_group.alb-sg.id]
}

# 2단계. aws_lb_listener 리소스 사용해 ALB 리스너 정의
resource "aws_lb_listener" "http" {
    load_balancer_arn       = aws_lb.webserver-alb.arn
    port                    = local.http_port
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

# 3단계. ALB가 사용할 보안 그룹 작성
resource "aws_security_group" "alb-sg" {
    name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb-sg.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb-sg.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

# 5단계. ALB의 타겟 그룹 작성
resource "aws_lb_target_group" "asg-tg" {
    # name                    = "terraform-asg-alb"
    name                    = var.cluster_name
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

# 7단계. 리스너 rule 생성
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

# 웹 서버의 기본 보안 그룹 작성
resource "aws_security_group" "webserver-sg" {
    # name = "terraform-example-instance"
    name = "${var.cluster_name}-instance"
    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = local.tcp_protocol
        cidr_blocks = local.all_ips
    }
}

data "terraform_remote_state" "db" {
    backend = "s3"
    config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "ap-northeast-2"
    }
}

data "aws_vpc" "webserver-vpc" {
  default = true
}

data "aws_subnet_ids" "default-subnet" {
  vpc_id = data.aws_vpc.webserver-vpc.id
}

locals {
    http_port = 80
    any_port = 0
    any_protocol = "-1"
    tcp_protocol = "tcp"
    all_ips = ["0.0.0.0/0"]
}