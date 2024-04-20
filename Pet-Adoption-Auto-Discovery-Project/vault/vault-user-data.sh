#!/bin/bash

# Update package repositories
sudo apt update

# Download and install Consul
sudo wget https://releases.hashicorp.com/consul/1.7.3/consul_1.7.3_linux_amd64.zip
sudo apt install unzip -y
sudo unzip consul_1.7.3_linux_amd64.zip
sudo mv consul /usr/bin/

# Create a Consul systemd service
sudo cat <<EOT>> /etc/systemd/system/consul.service
[Unit]
Description=Consul
Documentation=https://www.consul.io/

[Service]
ExecStart=/usr/bin/consul agent -server -ui -data-dir=/temp/consul -bootstrap-expect=1 -node=vault -bind=$(hostname -i) -config-dir=/etc/consul.d/
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOT

# Create Consul configuration directory and UI settings
sudo mkdir /etc/consul.d 
sudo cat <<EOT>> /etc/consul.d/ui.json
{
    "addresses":{
    "http": "0.0.0.0"
    }
}
EOT

# Reload systemd, start, and enable Consul service
sudo systemctl daemon-reload
sudo systemctl start consul
sudo systemctl enable consul

# Download and install Vault
sudo apt update
sudo wget https://releases.hashicorp.com/vault/1.5.0/vault_1.5.0_linux_amd64.zip
sudo unzip vault_1.5.0_linux_amd64.zip
sudo mv vault /usr/bin/

# Create Vault configuration file
sudo mkdir /etc/vault/
sudo cat <<EOT>> /etc/vault/config.hcl
storage "consul" {
    address = "127.0.0.1:8500"
    path    = "vault/"
}

listener "tcp" {
    address        = "0.0.0.0:8200"
    tls_disable    = 1
}

seal "awskms" {
    region     = "${var1}"
    kms_key_id = "${var2}"
}
ui = true
EOT

# Create Vault systemd service
sudo cat <<EOT>> /etc/systemd/system/vault.service
[Unit]
Description=Vault
Documentation=https://www.vault.io/

[Service]
ExecStart=/usr/bin/vault server -config=/etc/vault/config.hcl
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOT

# Reload systemd, start, and enable Vault service
sudo systemctl daemon-reload
export VAULT_ADDR="http://localhost:8200"
cat <<EOT > /etc/profile.d/vault.sh
export VAULT_ADDR="http://localhost:8200"
export VAULT_SKIP_VERIFY=true
EOT
vault -autocomplete-install
complete -C /usr/bin/vault vault

# Notify once provisioned
echo "Vault server provisioned successfully."

# Start Vault service
sudo systemctl start vault
sudo systemctl enable vault

# Set hostname to Vault
sudo hostnamectl set-hostname Vault