

variable "location" {
  default = "westeurope"
}

variable "resource_group_name" {
  default = "rg-helpdesk-prod"
}

variable "admin_username" {
  default = "azureuser"
}

variable "ssh_public_key_path" {
  default = "C:/Users/janek/.ssh/id_ed25519.pub"
}

variable "enable_vpn" {
  description = "Create VPN Gateway"
  type        = bool
  default     = true
}

variable "enable_bastion" {
  description = "Create Bastion Host"
  type        = bool
  default     = true
}

variable "mode" {
  description = "Environment mode: full or suspended"
  type        = string
  default     = "full"
}

variable "env_mode" {
  type    = string
  default = "full"
}