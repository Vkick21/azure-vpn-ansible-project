

variable "location" {
  description = "Region Azure dla zasobow projektu"
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Nazwa glownej grupy zasobow"
  default     = "rg-helpdesk-prod"
}

variable "admin_username" {
  description = "Konto administratora maszyn Linux"
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Lokalna sciezka do publicznego klucza SSH"
  default     = "C:/Users/janek/.ssh/id_ed25519.pub"
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
  description = "Tryb pracy srodowiska uzywany przez locals"
  type        = string
  default     = "full"
}