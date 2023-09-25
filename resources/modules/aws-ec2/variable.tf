variable "owner" {
  description = "Owner of the resource"
  type        = string
}

variable "tag_prefix" {
  description = "Resource tag prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "instance_type" {
  description = "Instance type e.g m5.large"
  type        = string
}

variable "ami_type" {
  description = "ami type to use"
  type        = string

  validation {
    condition     = contains(["WINDOWS_SERVER_2019", "AMAZON_LINUX_2"], var.ami_type)
    error_message = "Valid values for var: ami_type are (WINDOWS_SERVER_2019, AMAZON_LINUX_2)."
  }
}

variable "is_nvidia_enabled" {
  description = "Is NVIDIA enabled"
  type        = bool
}

locals {
  my-public-cidr = "${chomp(data.http.my-public-ip.response_body)}/32"
  ami_id         = {
    WINDOWS_SERVER_2019 = data.aws_ami.windows_server_2019.id
    AMAZON_LINUX_2      = data.aws_ami.amz_linux.id
  }
}