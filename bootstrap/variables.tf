variable "location" {
  description = "Region VM zarzadzajacej"
  type        = string
  default     = "westeurope"
}

variable "management_resource_group_name" {
  description = "Osobna grupa zasobow automatyzacji"
  type        = string
  default     = "rg-helpdesk-management"
}

variable "workload_resource_group_name" {
  description = "Grupa zasobow zarzadzana przez glowny Terraform"
  type        = string
  default     = "rg-helpdesk-prod"
}

variable "vnet_name" {
  description = "Istniejaca siec projektu"
  type        = string
  default     = "vnet-helpdesk"
}

variable "management_subnet_name" {
  description = "Istniejaca podsiec dla automatyzacji"
  type        = string
  default     = "subnet-management"
}

variable "admin_username" {
  description = "Administrator Linux"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Klucz uzywany tylko do pierwszego dostepu po VPN"
  type        = string
  default     = "C:/Users/janek/.ssh/id_ed25519.pub"
}

variable "vm_size" {
  description = "Oszczedny rozmiar runnera"
  type        = string
  default     = "Standard_B1s"
}

variable "helpdesk_fqdn" {
  description = "Nazwa formularza kierowana prywatnie z runnera"
  type        = string
  default     = "vkickhamster-helpdesk.westeurope.cloudapp.azure.com"
}

variable "operator_fqdn" {
  description = "Nazwa panelu kierowana prywatnie z runnera"
  type        = string
  default     = "vkickhamster-operator-110997.trafficmanager.net"
}

variable "github_repository" {
  description = "Repozytorium uprawnione do wlaczania i zatrzymywania runnera"
  type        = string
  default     = "Vkick21/azure-vpn-ansible-project"
}

variable "tfstate_resource_group_name" {
  description = "Grupa istniejacego zdalnego stanu"
  type        = string
  default     = "rg-tfstate"
}

variable "tfstate_storage_account_name" {
  description = "Konto istniejacego zdalnego stanu"
  type        = string
  default     = "tfstatehelpdesk01"
}
