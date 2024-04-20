# Output the ID of the AWS key pair for referencing in other resources.
output "public-key-id" {
  value = aws_key_pair.public-key.id
}

# Output the sensitive private key material for potential usage in local configurations.
output "private-key-id" {
  value = tls_private_key.keypair.private_key_pem
}