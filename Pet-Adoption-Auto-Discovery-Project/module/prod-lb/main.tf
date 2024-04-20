# Creating LB target group
resource "aws_lb_target_group" "prod-tg" {
  name = "prog-tg"
  port = 8080
  protocol = "HTTP"
  vpc_id = var.vpc_id
  health_check {
    interval = 30
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 5
  }
}
# Creating prod load balancer
resource "aws_lb" "prod-alb" {
  name                       = "prod-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = var.prod-sg
  subnets                    = var.prod-subnet
  enable_deletion_protection = false
  tags = {
    Name = var.prod-alb-name
  }
}

# Creating load balancer listeners http
resource "aws_lb_listener" "prod-listener-http" {
  load_balancer_arn = aws_lb.prod-alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod-tg.arn
  }
}

# Creating load balancer listeners https
resource "aws_lb_listener" "prod-listener-https" {
  load_balancer_arn = aws_lb.prod-alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn =aws_lb_target_group.prod-tg.arn
  }
}