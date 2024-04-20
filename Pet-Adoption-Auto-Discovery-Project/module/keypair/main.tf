# Generate a 4096-bit RSA private key for secure access.
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Store the private key locally for safekeeping.
resource "local_file" "keypair" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "infra-key.pem"
  file_permission = "600"
}
# Create an AWS key pair for remote access
resource "aws_key_pair" "public-key" {
  key_name   = "infra-key"
  public_key = tls_private_key.keypair.public_key_openssh
}