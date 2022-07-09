# RSA key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
}

# Write private key for debugging
resource "local_sensitive_file" "private_key" {
    content  = tls_private_key.ssh_key.private_key_openssh
    filename = "${path.module}/private_key"
}