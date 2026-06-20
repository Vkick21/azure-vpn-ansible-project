# Podstawowe dane przydatne po wdrozeniu i w kolejnych automatyzacjach.
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

# Adres uzywany przez uzytkownikow po uruchomieniu HTTPS.
output "helpdesk_fqdn" {
  value = "${azurerm_public_ip.lb.domain_name_label}.${azurerm_resource_group.main.location}.cloudapp.azure.com"
}

# Prywatny adres panelu dostepny po zestawieniu VPN.
output "helpdesk_private_ip" {
  value = "10.10.1.10"
}
