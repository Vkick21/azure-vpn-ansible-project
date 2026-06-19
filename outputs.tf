# Podstawowe dane przydatne po wdrożeniu i w kolejnych automatyzacjach.
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}