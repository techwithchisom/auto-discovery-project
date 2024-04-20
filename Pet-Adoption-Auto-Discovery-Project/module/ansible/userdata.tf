locals {
  ansible-user-data = <<-EOF
#!/bin/bash
#Update instance and install tools (get, unzip, aws cli) 
sudo yum update -y
sudo yum install wget -y
sudo yum install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo ln -svf /usr/local/bin/aws /usr/bin/aws #This command is often used to make the AWS Command Line Interface (AWS CLI) available globally by creating a symbolic link in a directory that is included in the system's PATH
sudo bash -c 'echo "StrictHostKeyChecking No" >> /etc/ssh/ssh_config'
#configuring awscli on the ansible server
sudo su -c "aws configure set aws_access_key_id ${aws_iam_access_key.ansible_user_key.id}" ec2-user
sudo su -c "aws configure set aws_secret_access_key ${aws_iam_access_key.ansible_user_key.secret}" ec2-user
sudo su -c "aws configure set default.region eu-west-3" ec2-user
sudo su -c "aws configure set default.output text" ec2-user

# Set Access_keys as ENV Variables
export AWS_ACCESS_KEY_ID=${aws_iam_access_key.ansible_user_key.id}
export AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.ansible_user_key.secret}

# install ansible
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum install epel-release-latest-7.noarch.rpm -y
sudo yum update -y
sudo yum install python python-devel python-pip ansible -y

# copying files from local machines into Ansible server
sudo echo "${file(var.staging-MyPlaybook)}" >> /etc/ansible/stage-playbook.yml 
sudo echo "${file(var.staging-discovery-script)}" >> /etc/ansible/stage-bash-script.sh
sudo echo "${file(var.prod-MyPlaybook)}" >> /etc/ansible/prod-playbook.yml
sudo echo "${file(var.prod-discovery-script)}" >> /etc/ansible/prod-bash-script.sh 
sudo echo "${var.private_key}" >> /home/ec2-user/.ssh/id_rsa
sudo bash -c 'echo "NEXUS_IP: ${var.nexus-ip}:8085" > /etc/ansible/ansible_vars_file.yml'

# Give the right permissions to the files copied from the local machine into the ansible server
sudo chown -R ec2-user:ec2-user /etc/ansible
sudo chmod 400 /etc/ansible/key.pem
sudo chmod 755 /etc/ansible/stage-bash-script.sh 
sudo chmod 755 /etc/ansible/prod-bash-script.sh

#creating crontab to execute auto discovery script
echo "* * * * * ec2-user sh /etc/ansible/stage-bash-script.sh" > /etc/crontab
echo "* * * * * ec2-user sh /etc/ansible/prod-bash-script.sh" >> /etc/crontab
curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo NEW_RELIC_API_KEY="${var.nr-key}" NEW_RELIC_ACCOUNT_ID="${var.nr-acc-id}" NEW_RELIC_REGION="${var.nr-region}" /usr/local/bin/newrelic install -y
sudo hostnamectl set-hostname Ansible
EOF
}