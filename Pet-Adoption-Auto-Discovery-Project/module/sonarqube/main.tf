#Creating SonarQube Server within an EC2 Instance
resource "aws_instance" "SonarQube_Server" {
  ami                         = var.ami
  instance_type               = "t2.medium"
  key_name                    = var.keypair
  vpc_security_group_ids      = [var.sonarqube-sg]
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  user_data                   = local.sonarqube_user_data

  tags = {
    Name = var.name
  }
}

# Create a new load balancer
resource "aws_elb" "elb-sonar" {
  name            = "elb-sonar"
  subnets         = var.elb-subnets
  security_groups = [var.sonarqube-sg]
  listener {
    instance_port      = 9000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.cert-arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:9000"
    interval            = 30
  }

  instances                   = [aws_instance.SonarQube_Server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "sonar-elb"
  }
}