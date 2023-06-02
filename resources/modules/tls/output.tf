output "cert" {
  value = {
    certificate = tls_locally_signed_cert.this.cert_pem
    key         = tls_private_key.this.private_key_pem
  }
}

output "root-cert" {
  value = {
    certificate = tls_locally_signed_cert.this.ca_cert_pem
    key         = tls_locally_signed_cert.this.ca_private_key_pem
  }
}