variable "certificate_common_name" {
  description = "To generate certificate with the common name"
  type = string
}

variable "certificate_dns_names" {
  description = "To generate certificate with the DNS names"
  type = list(string)
}