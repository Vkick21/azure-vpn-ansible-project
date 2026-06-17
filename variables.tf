variable "subscription_id" {
  type = string
}

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