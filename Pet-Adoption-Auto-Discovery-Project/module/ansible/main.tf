#Create ansible Server 
resource "aws_instance" "ansible_server" {
  ami                    = var.ami-redhat
  vpc_security_group_ids = [var.ansible-sg]
  instance_type          = "t2.micro"
  key_name               = var.key-name
  subnet_id              = var.subnet-id
  user_data              = local.ansible-user-data

  tags = {
    Name = var.name
  }
}