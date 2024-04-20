output "ansible_ip" {
  value = aws_instance.ansible_server.private_ip
}