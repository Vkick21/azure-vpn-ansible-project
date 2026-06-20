# Dane potrzebne pozniej przez Ansible i aplikacje.
output "database_private_ip" {
  value = azurerm_network_interface.database.private_ip_address
}

output "key_vault_name" {
  value = azurerm_key_vault.helpdesk.name
}