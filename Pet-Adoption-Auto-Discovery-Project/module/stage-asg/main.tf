# Create a Launch Template to define instance configuration for the production ASG.
resource "aws_launch_template" "lt-stg" {
  name                   = "lt-stg"
  image_id               = var.ami-stg
  instance_type          = "t2.medium"
  key_name               = var.key-name
  vpc_security_group_ids = [var.asg-sg]
  user_data = base64encode(templatefile("./module/stage-asg/docker-script.sh", {
    nexus-ip             = var.nexus-ip-stg
    newrelic-license-key = var.nr-key-stg
    newrelic-account-id  = var.nr-acc-id-stg
    newrelic-region      = var.nr-region-stg
  }))
  tags = {
    Name = "lt-stg"
  }
}

# Create an Auto Scaling Group (ASG) for the production environment
resource "aws_autoscaling_group" "asg-stg" {
  name                      = var.asg-stg-name
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1
  force_delete              = true
  vpc_zone_identifier       = var.vpc-zone-id-stg
  target_group_arns         = [var.tg-arn]
  launch_template {
    id = aws_launch_template.lt-stg.id
  }
  tag {
    key                 = "Name"
    value               = var.asg-stg-name
    propagate_at_launch = true
  }
}

# Create a production autoscaling policy for dynamic scaling based on CPU utilization.
resource "aws_autoscaling_policy" "asp-stg" {
  name                   = "stg-asg-policy"
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.asg-stg.name
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}