# ED25519 key
resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}