resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-helpdesk"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "app" {
  name                 = "subnet-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "management" {
  name                 = "subnet-management"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.3.0/24"]
}


resource "azurerm_network_interface" "helpdesk01" {
  name                = "nic-helpdesk01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "helpdesk01" {
  name                = "helpdesk01"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  size = "Standard_B1s"

  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.helpdesk01.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "app" {
  name                = "nsg-app"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "helpdesk01" {
  network_interface_id      = azurerm_network_interface.helpdesk01.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name

  address_prefixes = ["10.10.4.0/26"]
}


resource "azurerm_network_interface" "helpdesk02" {
  name                = "nic-helpdesk02"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "helpdesk02" {
  name                = "helpdesk02"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  size = "Standard_B1s"

  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.helpdesk02.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_network_interface_security_group_association" "helpdesk02" {
  network_interface_id      = azurerm_network_interface.helpdesk02.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_public_ip" "lb" {
  name                = "pip-helpdesk-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_lb" "helpdesk" {
  name                = "lb-helpdesk"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "helpdesk" {
  loadbalancer_id = azurerm_lb.helpdesk.id
  name            = "backend-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "helpdesk01" {
  network_interface_id    = azurerm_network_interface.helpdesk01.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.helpdesk.id
}

resource "azurerm_network_interface_backend_address_pool_association" "helpdesk02" {
  network_interface_id    = azurerm_network_interface.helpdesk02.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.helpdesk.id
}

resource "azurerm_lb_probe" "http" {
  loadbalancer_id = azurerm_lb.helpdesk.id
  name            = "http-probe"
  port            = 80
}

resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = azurerm_lb.helpdesk.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"

  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.helpdesk.id
  ]

  probe_id = azurerm_lb_probe.http.id
}


resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_bastion_host" "main" {
  name                = "bastion-helpdesk"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_public_ip" "vpn" {
  name                = "pip-vpn-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  allocation_method = "Static"
  sku               = "Standard"

  zones = ["1"]
}

resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "vpn-helpdesk"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  sku = "VpnGw1AZ"

  ip_configuration {
    name                          = "vpnGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}

resource "azurerm_storage_account" "helpdesk" {
  name                = "helpdesk${random_string.storage.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_string" "storage" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_container" "attachments" {
  name                  = "attachments"
  storage_account_id    = azurerm_storage_account.helpdesk.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "documentation" {
  name                  = "documentation"
  storage_account_id    = azurerm_storage_account.helpdesk.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_id    = azurerm_storage_account.helpdesk.id
  container_access_type = "private"
}

resource "azurerm_network_interface" "ansible" {
  name                = "nic-ansible-mgmt"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.management.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "ansible" {
  name                = "ansible-mgmt"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  size = "Standard_B1s"

  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.ansible.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_network_interface_security_group_association" "ansible" {
  network_interface_id      = azurerm_network_interface.ansible.id
  network_security_group_id = azurerm_network_security_group.app.id
}
