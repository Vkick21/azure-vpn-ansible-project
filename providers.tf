terraform {
  # Wersje sa ograniczone, zeby aktualizacja providera nie zaskoczyla projektu.
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

# Domyslna konfiguracja polaczenia z Azure.
provider "azurerm" {
  features {}
}