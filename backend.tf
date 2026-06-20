terraform {
  # Stan trzymamy w Azure, zeby nie zalezal od jednego komputera.
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstatehelpdesk01"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}