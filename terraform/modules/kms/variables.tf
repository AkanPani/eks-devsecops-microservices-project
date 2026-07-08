variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alias_name" {
  description = "Optional KMS alias name. Must start with alias/"
  type        = string
  default     = null

  validation {
    condition = var.alias_name == null ? true : (
      trimspace(var.alias_name) == "" ? true : can(regex("^alias/[0-9A-Za-z_/-]+$", trimspace(var.alias_name)))
    )

    error_message = "alias_name must start with alias/ and contain only letters, numbers, underscore, slash, or hyphen."
  }
}

variable "description" {
  description = "Description for the KMS key"
  type        = string
  default     = "KMS key for project encryption"
}

variable "deletion_window_in_days" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
}

variable "enable_key_rotation" {
  description = "Enable automatic KMS key rotation"
  type        = bool
  default     = true
}

variable "multi_region" {
  description = "Whether the KMS key is multi-region"
  type        = bool
  default     = false
}

variable "key_administrators" {
  description = "IAM principals allowed to administer the KMS key"
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "IAM principals allowed to use the KMS key"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

