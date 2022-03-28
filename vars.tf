variable "aws_profile" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_endpoint" {
  type    = string
  default = ""
}

variable "backend_count" {
  default = 1
}

variable "backend_ami_description" {
  type = string
}

variable "backend_ami_owner" {
  type = string
}

variable "backend_ami_root_type" {
  type = string
}

variable "backend_instance_type" {
  type = string
}

variable "lb_name" {
  default = "testTF"
}

variable "lb_internal" {
  default = false
}

variable "cert_dns_name" {
  default = "testTF.example.com"
}

variable "iam_cert" {
  default = false
  type    = bool
}

variable "configure_ssh" {
  default = false
  type    = bool
}
