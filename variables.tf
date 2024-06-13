# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "username" {
  type        = string
  description = "Linux username, compliant with the Debian/Ubuntu format."

  validation {
    condition     = length(var.username) < 33
    error_message = "Username must be no longer than 32 characters."
  }

  validation {
    condition     = can(regex("^([a-z])[a-z0-9.-]*$", var.username))
    error_message = "Username must start with a letter and contain lowercase letters, digits, dashes (-), and periods (.)."
  }
}

variable "instance_ids" {
  description = "One or more EC2 instance IDs where this user should exist"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "groups" {
  description = "(Optional) Linux user groups that this user should be associated with. If a custom group does not exist on the instance, it will be automatically created. However, removing a previously set custom group will not delete it on the instance."
  type        = list(string)
  default     = []

}

variable "shell" {
  description = "(Optional) Shell type to assign to the user. Must already exist on the instance."
  type        = string
  default     = "/bin/bash"
}

variable "ssh_keys" {
  description = "(Optional) Public SSH keys associated with this user. Setting this value will replace any existing keys, including those that were manually added in the instance."
  type        = list(string)
  default     = []
}

variable "sudoer" {
  description = "Whether this user should have escalated privileges by being part of the sudoers group."
  type        = bool
  default     = false
}
