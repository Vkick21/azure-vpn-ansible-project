# Losowe wartosci trafiaja do zdalnego stanu Terraform i Key Vault.
resource "random_password" "database" {
  length  = 32
  special = false
}

resource "random_password" "django" {
  length  = 64
  special = false
}

# Key Vault udostepnia sekrety aplikacji przez Managed Identity.
resource "azurerm_key_vault" "helpdesk" {
  name                       = "kv-helpdesk-${random_string.storage.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Biezacy wykonawca i jawnie wskazane tozsamosci zachowuja dostep do sekretow.
  dynamic "access_policy" {
    for_each = setunion(
      toset([data.azurerm_client_config.current.object_id]),
      var.additional_key_vault_admin_object_ids
    )

    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = access_policy.value

      secret_permissions = [
        "Delete",
        "Get",
        "List",
        "Purge",
        "Recover",
        "Set"
      ]
    }
  }

  # Obie VM aplikacyjne moga tylko odczytywac sekrety.
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_virtual_machine.helpdesk01.identity[0].principal_id

    secret_permissions = [
      "Get",
      "List"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_virtual_machine.helpdesk02.identity[0].principal_id

    secret_permissions = [
      "Get",
      "List"
    ]
  }
}

resource "azurerm_key_vault_secret" "database_password" {
  name         = "database-password"
  value        = random_password.database.result
  key_vault_id = azurerm_key_vault.helpdesk.id
}

resource "azurerm_key_vault_secret" "django_secret_key" {
  name         = "django-secret-key"
  value        = random_password.django.result
  key_vault_id = azurerm_key_vault.helpdesk.id
}

# Haslo pierwszego operatora mozna pozniej odczytac z Key Vault.
resource "random_password" "django_admin" {
  length  = 24
  special = false
}

resource "azurerm_key_vault_secret" "django_admin_password" {
  name         = "django-admin-password"
  value        = random_password.django_admin.result
  key_vault_id = azurerm_key_vault.helpdesk.id
}
