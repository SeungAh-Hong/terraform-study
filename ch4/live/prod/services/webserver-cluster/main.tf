provider "aws" {
    region = "ap-northeast-2"
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"
    # source = "github.com/foo/modules//webserver-cluster?ref=v0.0.1"
    cluster_name = "webservers-prod"
    db_remote_state_bucket = "terraform-state-seungah"
    db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"
    
    # instance_type ="m4.large" ## 예제에서 권장
    # 돈없으니까 예제는 t2.micro
    instance_type = "t2.micro"
    min_size = 1
    max_size = 10
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
    scheduled_action_name = "scale-out-during-business-hours"
    min_size = 1 # 예제 2
    max_size = 10
    desired_capacity = 2 # 예제 10
    recurrence = "0 9 * * *"

    autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
    scheduled_action_name = "scale-in-at-night"
    min_size = 1 # 예제 2
    max_size = 10
    desired_capacity = 1 # 예제 2
    recurrence = "0 17 * * *"
    
    autoscaling_group_name = module.webserver_cluster.asg_name
}