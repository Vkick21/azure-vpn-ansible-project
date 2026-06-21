# Dodanie count nie odtwarza publicznych zasobow w dotychczasowym trybie.
moved {
  from = azurerm_public_ip.lb
  to   = azurerm_public_ip.lb[0]
}

moved {
  from = azurerm_lb.helpdesk
  to   = azurerm_lb.helpdesk[0]
}

moved {
  from = azurerm_lb_backend_address_pool.helpdesk
  to   = azurerm_lb_backend_address_pool.helpdesk[0]
}

moved {
  from = azurerm_network_interface_backend_address_pool_association.helpdesk01
  to   = azurerm_network_interface_backend_address_pool_association.helpdesk01[0]
}

moved {
  from = azurerm_network_interface_backend_address_pool_association.helpdesk02
  to   = azurerm_network_interface_backend_address_pool_association.helpdesk02[0]
}

moved {
  from = azurerm_lb_probe.http
  to   = azurerm_lb_probe.http[0]
}

moved {
  from = azurerm_lb_rule.http
  to   = azurerm_lb_rule.http[0]
}

moved {
  from = azurerm_lb_rule.https
  to   = azurerm_lb_rule.https[0]
}

moved {
  from = azurerm_traffic_manager_profile.operator
  to   = azurerm_traffic_manager_profile.operator[0]
}

moved {
  from = azurerm_traffic_manager_azure_endpoint.operator
  to   = azurerm_traffic_manager_azure_endpoint.operator[0]
}
