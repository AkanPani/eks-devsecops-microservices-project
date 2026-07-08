variable "hosted_zone_name" {
  description = "Route53 hosted zone name. Example: tbdpro.in"
  type        = string
}

variable "domain_name" {
  description = "Main domain name for ACM certificate. Example: dev.tbdpro.in"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names. Example: *.dev.tbdpro.in"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
