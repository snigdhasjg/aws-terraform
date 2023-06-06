variable "tag_prefix" {
  description = "Resource tag prefix"
  type        = string
}

variable "vpc-id" {
  description = "VPC ID"
  type        = string
}

variable "vpn_cidr_block" {
  description = "CIDR block of VPN"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpn_cidr_block, 32))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "server-cert" {
  description = "Locally generated certificate"
  type        = object({
    certificate    = string
    key            = string
    ca_certificate = string
    common_name    = string
  })
}

variable "client-cert" {
  description = "Locally generated root certificate"
  type        = object({
    certificate    = string
    key            = string
    ca_certificate = string
    common_name    = string
  })
}