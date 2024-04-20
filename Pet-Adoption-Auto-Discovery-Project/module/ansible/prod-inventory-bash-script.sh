#!/bin/bash

set -x

# Define variables
AWS_CLI_PATH='/usr/local/bin/aws'
INVENTORY_FILE='/etc/ansible/prod-hosts'
IPS_FILE='/etc/ansible/prod-ips.list'
ASG_NAME='pet-clinic-prod-asg'
SSH_KEY_PATH="~/.ssh/id_rsa"
WAIT_TIME=20

# Function to discover AWS instances and save private IPs to file
aws_discovery() {
    \$AWS_CLI_PATH ec2 describe-instances \\
        --filters "Name=tag:aws:autoscaling:groupName,Values=\$ASG_NAME" \\
        --query 'Reservations[*].Instances[*].NetworkInterfaces[*].PrivateIpAddress' \\
        --output text > "\$IPS_FILE"
}

# Function to update Ansible inventory file
update_inventory() {
    echo "[webservers]" > "\$INVENTORY_FILE"
    while IFS= read -r instance; do
        ssh-keyscan -H "\$instance" >> ~/.ssh/known_hosts
        echo "\$instance ansible_user=ec2-user ansible_ssh_private_key_file=\$SSH_KEY_PATH" >> "\$INVENTORY_FILE"
    done < "\$IPS_FILE"

    echo "Inventory updated successfully."
}

# Function to wait for specified time
wait_for_seconds() {
    echo "Waiting for \$WAIT_TIME seconds..."
    sleep "\$WAIT_TIME"
}

# Function to check and start Docker container if not running
check_docker_container() {
    while read -r ip; do
        # Check if container is running
        ssh -i "\$SSH_KEY_PATH" ec2-user@"\$ip" "docker ps --filter 'name=appContainer' --format '{{.Names}}'" | grep -q "appContainer"

        if [[ $? -ne 0 ]]; then
            # Container not running, execute script to start container
            ssh -i "\$SSH_KEY_PATH" ec2-user@"\$ip" "/home/ec2-user/scripts/script.sh"
        fi
    done < "\$IPS_FILE"
}

# Main function block
main() {
    aws_discovery
    update_inventory
    wait_for_seconds
    check_docker_container
}

# Execute main function
main
