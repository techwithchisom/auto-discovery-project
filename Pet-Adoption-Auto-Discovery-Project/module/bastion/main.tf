resource "aws_instance" "bastion" {
  ami                         = var.ami_redhat
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.bastion_sg]
  key_name                    = var.keyname
  user_data                   = local.bastion_user_data

  tags = {
    Name = var.tag_bastion
  }
}

