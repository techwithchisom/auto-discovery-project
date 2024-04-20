locals {
  name = "petclinic"
}

provider "aws" {
  region = var.region
  profile = var.profile
}

resource "aws_instance" "vault" {
  ami                         = var.ami-ubuntu
  instance_type               = "t2.medium"
  vpc_security_group_ids      = [aws_security_group.vault-SG.id]
  key_name                    = aws_key_pair.vault-public-key.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.vault-kms-unseal.id
  user_data = templatefile("./vault-user-data.sh", {
    var2 = aws_kms_key.vault.id,
    var1 = var.region
  })
  tags = {
    Name = "${local.name}-vault"
  }
}

resource "aws_kms_key" "vault" {
  description             = "vault unseal key"
  deletion_window_in_days = 10
  tags = {
    Name = "${local.name}-vault-kms"
  }
}

resource "aws_elb" "vault-lb" {
  name               = "vault-lb"
  security_groups    = [aws_security_group.vault-SG.id]
  availability_zones = ["eu-west-3a", "eu-west-3b"]
  listener {
    instance_port      = 8200
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = aws_acm_certificate.cert.arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8200"
    interval            = 30
  }

  instances                   = [aws_instance.vault.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "vault-elb"
  }

}

data "aws_route53_zone" "route53_zone" {
  name         = var.domain-name
  private_zone = false
}

resource "aws_route53_record" "vault_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.vault-domain-name
  type    = "A"
  alias {
    name                   = aws_elb.vault-lb.dns_name
    zone_id                = aws_elb.vault-lb.zone_id
    evaluate_target_health = true
  }
}

# CREATE CERTIFICATE WHICH IS DEPENDENT ON HAVING A DOMAIN NAME
resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain-name
  subject_alternative_names = [var.domain-name2]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# ATTACHING ROUTE53 AND THE CERTFIFCATE- CONNECTING ROUTE 53 TO THE CERTIFICATE
resource "aws_route53_record" "cert-record" {
  for_each = {
    for anybody in aws_acm_certificate.cert.domain_validation_options : anybody.domain_name => {
      name   = anybody.resource_record_name
      record = anybody.resource_record_value
      type   = anybody.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.route53_zone.zone_id
}

# SIGN THE CERTIFICATE
resource "aws_acm_certificate_validation" "sign_cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert-record : record.fqdn]
}


resource "aws_security_group" "vault-SG" {
  name        = "vault-SG"
  description = "vault-SG"

  ingress {
    description = "SSH for vault-SG"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "proxy for vault-SG"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http for vault-SG"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "https for vault-SG"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-vault-SG"
  }
}

# Create keypair - RSA key of size 4096 bits
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "private-key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "vault-key.pem"
  file_permission = "600"
}
resource "aws_key_pair" "vault-public-key" {
  key_name   = "vault-public-key"
  public_key = tls_private_key.keypair.public_key_openssh
}