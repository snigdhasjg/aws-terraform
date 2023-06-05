resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "tls_cert_request" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name         = var.cert_details.common_name
    country             = "IN"
    province            = "WB"
    locality            = "Kolkata"
    organization        = "AWS Joe Sandbox"
    organizational_unit = "Mumbai"
  }

  dns_names = var.cert_details.dns_names
}

resource "tls_locally_signed_cert" "this" {
  allowed_uses = [
    "any_extended",
    "cert_signing",
    "client_auth",
    "code_signing",
    "content_commitment",
    "crl_signing",
    "data_encipherment",
    "decipher_only",
    "digital_signature",
    "email_protection",
    "encipher_only",
    "ipsec_end_system",
    "ipsec_tunnel",
    "ipsec_user",
    "key_agreement",
    "key_encipherment",
    "microsoft_commercial_code_signing",
    "microsoft_kernel_code_signing",
    "microsoft_server_gated_crypto",
    "netscape_server_gated_crypto",
    "ocsp_signing",
    "server_auth",
    "timestamping"
  ]
  ca_cert_pem           = file("${path.module}/ca_cert/rootCA.crt")
  ca_private_key_pem    = file("${path.module}/ca_cert/rootCA.key")
  cert_request_pem      = tls_cert_request.this.cert_request_pem
  validity_period_hours = 365 * 24
}

resource "local_sensitive_file" "generated_cert" {
  filename = "${path.module}/cert/${replace(tls_cert_request.this.subject[0].common_name, "^\\*\\.", "")}.crt"
  content  = tls_locally_signed_cert.this.cert_pem
}

resource "local_sensitive_file" "generated_key" {
  filename = "${path.module}/cert/${replace(tls_cert_request.this.subject[0].common_name, "^\\*\\.", "")}.key"
  content  = tls_private_key.this.private_key_pem
}

resource "null_resource" "delete_cert_dir" {
  depends_on = [
    local_sensitive_file.generated_cert,
    local_sensitive_file.generated_key
  ]

  provisioner "local-exec" {
    when = destroy
    command = "rm -r ${path.module}/cert"
  }
}