output "vault-server-ip" {
  value = aws_instance.vault.public_ip
}