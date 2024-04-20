locals {
  sonarqube_user_data = <<-EOF
#!/bin/bash

# Update package lists
sudo apt update -y

# Install necessary packages
sudo apt install -y openjdk-11-jdk postgresql unzip

# Configure OS level values
sudo bash -c 'echo "
vm.max_map_count=262144
fs.file-max=65536
ulimit -n 65536
ulimit -u 4096" >> /etc/sysctl.conf'

sudo bash -c 'echo "
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096" >> /etc/security/limits.conf'

# Install PostgreSQL
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update -y
sudo apt install -y postgresql-14 postgresql-contrib-14

# Enable and start PostgreSQL
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Change default password of postgres user
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'Admin123@'"

# Create user sonar without switching technically
sudo -u postgres createuser sonar

# Create SonarQube Database and change sonar password
sudo -u postgres psql -c "ALTER USER sonar WITH ENCRYPTED PASSWORD 'Admin123@'"
sudo -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube to sonar"

# Restart PostgreSQL for changes to take effect
sudo systemctl restart postgresql

# Install SonarQube
sudo mkdir /sonarqube/
cd /sonarqube/
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.9.2.46101.zip
sudo unzip sonarqube-8.9.2.46101.zip -d /opt/
sudo mv /opt/sonarqube-8.9.2.46101/ /opt/sonarqube

# Add group user sonarqube
sudo groupadd sonar

# Create a user and add the user into the group with directory permission to the /opt/ directory
sudo useradd -c "SonarQube - User" -d /opt/sonarqube/ -g sonar sonar

# Change ownership of the directory to sonar
sudo chown sonar:sonar /opt/sonarqube/ -R

# Configure SonarQube
sudo bash -c 'echo "
sonar.jdbc.username=sonar
sonar.jdbc.password=Admin123@
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError" >> /opt/sonarqube/conf/sonar.properties'

# Configure SonarQube service
sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOT
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
ExecReload=/opt/sonarqube/bin/linux-x86-64/sonar.sh restart
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOT

# Enable and Start the SonarQube service
sudo systemctl daemon-reload
sudo systemctl enable sonarqube.service
sudo systemctl start sonarqube.service

# Install net-tools incase we want to debug later
sudo apt install net-tools -y

# Install nginx
sudo apt install nginx -y

# Configure nginx to access server from outside
sudo tee /etc/nginx/sites-enabled/sonarqube.conf > /dev/null <<EOT
server {
  listen 80;
  access_log  /var/log/nginx/sonar.access.log;
  error_log   /var/log/nginx/sonar.error.log;
  proxy_buffers 16 64k;
  proxy_buffer_size 128k;
  location / {
      proxy_pass  http://127.0.0.1:9000;
      proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
      proxy_redirect off;
      proxy_set_header    Host            \$host;
      proxy_set_header    X-Real-IP       \$remote_addr;
      proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header    X-Forwarded-Proto http;
  }
}
EOT

# Remove the default configuration file
sudo rm /etc/nginx/sites-enabled/default

# Enable and restart nginx service
sudo systemctl enable nginx.service
sudo systemctl stop nginx.service
sudo systemctl start nginx.service

# Install New Relic
curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo NEW_RELIC_API_KEY="${var.nr-key}" NEW_RELIC_ACCOUNT_ID="${var.nr-acc-id}" NEW_RELIC_REGION="${var.nr-region}" /usr/local/bin/newrelic install -y

# Change Hostname(IP) to something readable
sudo hostnamectl set-hostname Sonarqube

# Reboot the system
sudo reboot
EOF
}