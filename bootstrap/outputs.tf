output "management_vm_name" {
  value = azurerm_linux_virtual_machine.management.name
}

output "management_private_ip" {
  value = azurerm_network_interface.management.private_ip_address
}

output "management_identity_principal_id" {
  value = azurerm_linux_virtual_machine.management.identity[0].principal_id
}

output "github_control_client_id" {
  value = azurerm_user_assigned_identity.github_control.client_id
}

output "azure_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "azure_subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}
