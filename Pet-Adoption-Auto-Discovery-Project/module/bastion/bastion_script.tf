locals {
  bastion_user_data = <<-EOF
#!/bin/bash
echo "${var.private_key}" >> /home/ec2-user/.ssh/id_rsa
chmod 400 /home/ec2-user/.ssh/id_rsa
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa
sudo hostnamectl set-hostname Bastion
EOF
}
