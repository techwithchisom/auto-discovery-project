output "bastion_ip" {
  value = module.bastion.bastion_ip
}
output "jenkins_ip" {
  value = module.jenkins.jenkins-ip
}
output "ansible_ip" {
  value = module.ansible.ansible_ip
}
output "rds-endpoint" {
  value = module.rds.rds-endpoint
}
output "nexus_pub_ip" {
  value = module.nexus.nexus_pub_ip
}
output "Sonarqube-ip" {
  value = module.sonarqube.Sonarqube-ip
}

