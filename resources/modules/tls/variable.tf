variable "cert_details" {
  description = "Certificate generation details"
  type = object({
    common_name = string
    dns_names = list(string)
  })
}