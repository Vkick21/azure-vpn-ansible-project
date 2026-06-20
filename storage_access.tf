# Managed Identity pozwala korzystac ze Storage bez kluczy dostepowych.
locals {
  storage_blob_principals = {
    helpdesk01    = azurerm_linux_virtual_machine.helpdesk01.identity[0].principal_id
    helpdesk02    = azurerm_linux_virtual_machine.helpdesk02.identity[0].principal_id
    helpdesk_db01 = azurerm_linux_virtual_machine.database.identity[0].principal_id
  }
}

resource "azurerm_role_assignment" "storage_blob" {
  for_each = local.storage_blob_principals

  scope                = azurerm_storage_account.helpdesk.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}