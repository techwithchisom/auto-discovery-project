resource "aws_instance" "teamjenkins" {
  ami                         = var.ami-redhat
  instance_type               = "t2.medium"
  subnet_id                   = var.subnet-id
  vpc_security_group_ids      = [var.jenkins-sg]
  associate_public_ip_address = true
  key_name                    = var.key-name
  user_data                   = local.jenkins_user_data

  tags = {
    Name = var.jenkins-name
  }
}

resource "aws_elb" "jenkins_lb" {
  name            = "jenkins-lb"
  subnets         = var.subnet-elb
  security_groups = [var.jenkins-sg]
  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.cert-arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8080"
    interval            = 30
  }

  instances                   = [aws_instance.teamjenkins.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "jenkins-elb"
  }

}
