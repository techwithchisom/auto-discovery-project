output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_id" {
  value = aws_instance.bastion.id
}