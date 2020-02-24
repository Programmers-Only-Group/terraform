resource "tls_private_key" "rsa_main" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "rsa_main_private_pem" {
  value = tls_private_key.rsa_main.private_key_pem
}
