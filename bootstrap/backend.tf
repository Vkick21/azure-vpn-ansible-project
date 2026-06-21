terraform {
  # Osobny klucz chroni VM zarzadzajaca przed glownym Terraform.
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstatehelpdesk01"
    container_name       = "tfstate"
    key                  = "bootstrap.tfstate"
  }
}
