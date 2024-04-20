output "Sonarqube-ip" {
  value = aws_instance.SonarQube_Server.public_ip
}
output "sonarqube_dns_name" {
  value = aws_elb.elb-sonar.dns_name
}
output "sonarqube_zone_id" {
  value = aws_elb.elb-sonar.zone_id
}
