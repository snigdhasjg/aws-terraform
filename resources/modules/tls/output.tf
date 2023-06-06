output "cert" {
  value = {
    certificate    = tls_locally_signed_cert.this.cert_pem
    key            = tls_private_key.this.private_key_pem
    ca_certificate = tls_locally_signed_cert.this.ca_cert_pem
    common_name    = var.certificate_common_name
  }
}