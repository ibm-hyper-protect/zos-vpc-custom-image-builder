# RSA key
resource "tls_private_key" "custom_vsi_ssh_key" {
  algorithm = "RSA"
}

# Write private key for debugging
resource "local_sensitive_file" "custom_vsi_private_key" {
    content  = tls_private_key.custom_vsi_ssh_key.private_key_openssh
    filename = "${path.module}/private_key_custom_vsi"
}