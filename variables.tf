

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
  description = "Reserved environment mode for compatibility"
  type        = string
  default     = "full"
}

variable "env_mode" {
  description = "Tryb srodowiska: full utrzymuje Bastion, suspended planuje jego usuniecie"
  type        = string
  default     = "full"

  validation {
    condition     = contains(["full", "suspended"], var.env_mode)
    error_message = "env_mode musi miec wartosc full albo suspended."
  }
}
variable "helpdesk_dns_label" {
  description = "DNS label for the public HelpDesk endpoint"
  type        = string
}

variable "operator_dns_label" {
  description = "DNS label for the operator endpoint in Traffic Manager"
  type        = string
}

variable "private_only" {
  description = "Udostepnia caly Helpdesk tylko przez VPN i jeden prywatny Load Balancer"
  type        = bool
  default     = false
}

variable "additional_key_vault_admin_object_ids" {
  description = "Dodatkowe tozsamosci Terraform, ktore musza zachowac dostep do sekretow"
  type        = set(string)
  default     = []
}
