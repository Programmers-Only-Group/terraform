# MANDATORY
variable "name" {
  type        = string
  description = "ALB name"
}

variable "security_groups" {
  type        = list(string)
  description = "List of security group ids"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnet ids"
}

variable "target_group" {
  description = "A list of target groups"
  type        = list(map(string))
}

variable "certificate_arn" {
  type        = string
  description = "ARN of SSL certificate"
}

# OPTIONAL
variable "tags" {
  type = map

  default = {
    owner = "bwieckow"
  }
}

variable "if_only_ssl" {
  type        = bool
  description = "Determines whether to redirect traffic from 80 to 443."
  default     = true
}

variable "internal" {
  type        = bool
  description = "(optional) describe your variable"
  default     = false
}

variable "idle_timeout" {
  type        = string
  description = "Idle timeout"
  default     = "3600"
}

variable "http2_enabled" {
  type        = bool
  description = "If HTTP2 enabled"
  default     = true
}

variable "deletion_protection_enabled" {
  type        = bool
  description = "Deletion protaction"
  default     = false
}