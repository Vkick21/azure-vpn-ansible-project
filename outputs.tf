# Podstawowe dane przydatne po wdrozeniu i w kolejnych automatyzacjach.
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

# Adres uzywany przez uzytkownikow po uruchomieniu HTTPS.
output "helpdesk_fqdn" {
  value = var.private_only ? "${var.helpdesk_dns_label}.${azurerm_resource_group.main.location}.cloudapp.azure.com" : azurerm_public_ip.lb[0].fqdn
}

# Osobna nazwa uzywana tylko przez panel operatora.
output "operator_fqdn" {
  value = var.private_only ? "${var.operator_dns_label}.trafficmanager.net" : azurerm_traffic_manager_profile.operator[0].fqdn
}

# Prywatny adres panelu dostepny po zestawieniu VPN.
output "helpdesk_private_ip" {
  value = "10.10.1.10"
}
