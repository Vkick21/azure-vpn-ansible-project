terraform {
  backend "azurerm" {
    resource_group_name  = "rg-helpdesk-prod"
    storage_account_name = "helpdeskjfktb9"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}