terraform {
  # Wersje są ograniczone, żeby aktualizacja providera nie zaskoczyła projektu.
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Domyślna konfiguracja połączenia z Azure.
provider "azurerm" {
  features {}
}