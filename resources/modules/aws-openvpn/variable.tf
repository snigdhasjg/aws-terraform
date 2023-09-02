variable "owner" {
  description = "Owner of the resource"
  type        = string
}

variable "tag_prefix" {
  description = "Resource tag prefix"
  type        = string
}

variable "vpc-id" {
  description = "VPC ID"
  type        = string
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

#variable "client-cert" {
#  description = "Locally generated root certificate"
#  type        = object({
#    certificate    = string
#    key            = string
#    ca_certificate = string
#    common_name    = string
#  })
#}