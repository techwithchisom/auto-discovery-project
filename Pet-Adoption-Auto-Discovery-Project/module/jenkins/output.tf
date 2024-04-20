output "jenkins-ip" {
  value = aws_instance.teamjenkins.private_ip
}
output "jenkins_dns_name" {
  value = aws_elb.jenkins_lb.dns_name
}
output "jenkins_zone_id" {
  value = aws_elb.jenkins_lb.zone_id
}