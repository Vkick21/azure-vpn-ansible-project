# Glowna grupa przechowuje wszystkie zasoby srodowiska HelpDesk.
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Wspolna siec prywatna dla aplikacji, administracji i VPN.
resource "azurerm_virtual_network" "main" {
  name                = "vnet-helpdesk"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Podsiec aplikacji przeznaczona dla serwerow HelpDesk.
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


# Pierwszy serwer aplikacyjny.
resource "azurerm_network_interface" "helpdesk01" {
  name                = "nic-helpdesk01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.private_only ? azurerm_public_ip.app_outbound[0].id : null
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

  identity {
    type = "SystemAssigned"
  }
}

# Reguly sieciowe dopuszczaja SSH i ruch HTTP do serwerow.
resource "azurerm_network_security_group" "app" {
  name                = "nsg-app"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSSHFromVPN"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "172.20.200.0/24"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowSSHFromManagement"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.10.2.10/32"
    destination_address_prefix = "*"
  }
  dynamic "security_rule" {
    for_each = var.private_only ? [] : [1]
    content {
      name                       = "AllowPublicWeb"
      priority                   = 1020
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["80", "443"]
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
  }
  security_rule {
    name                       = "AllowWebFromVPN"
    priority                   = 1030
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "172.20.200.0/24"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowLoadBalancerProbe"
    priority                   = 1040
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Block lateral access from the remaining VNet subnets.
  security_rule {
    name                       = "DenyOtherVnetInbound"
    priority                   = 4090
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowPostgreSQLOutbound"
    priority                   = 2000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "10.10.5.4"
  }
  security_rule {
    name                       = "AllowWebOutbound"
    priority                   = 2010
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
  security_rule {
    name                       = "AllowAzureHTTPSOutbound"
    priority                   = 2020
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
  security_rule {
    name                       = "AllowKeyVaultHTTPSOutbound"
    priority                   = 2030
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureKeyVault"
  }
  security_rule {
    name                       = "DenyOtherVnetOutbound"
    priority                   = 4091
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "DenyOtherInternetOutbound"
    priority                   = 4092
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}
resource "azurerm_network_interface_security_group_association" "helpdesk01" {
  network_interface_id      = azurerm_network_interface.helpdesk01.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# Dedykowana podsiec wymagana przez Azure Bastion.
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name

  address_prefixes = ["10.10.4.0/26"]
}


# Drugi serwer aplikacyjny.
resource "azurerm_network_interface" "helpdesk02" {
  name                = "nic-helpdesk02"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.private_only ? azurerm_public_ip.app_outbound[1].id : null
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

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_network_interface_security_group_association" "helpdesk02" {
  network_interface_id      = azurerm_network_interface.helpdesk02.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# Publiczny Load Balancer rozdziela ruch HTTP miedzy obie VM.
resource "azurerm_public_ip" "lb" {
  count = var.private_only ? 0 : 1

  name                = "pip-helpdesk-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  allocation_method = "Static"
  sku               = "Standard"

  # Bezplatna nazwa Azure dla publicznego HelpDesk.
  domain_name_label = var.helpdesk_dns_label
}

# Jeden adres sluzy tylko jako SNAT. Nie ma na nim publicznych regul przychodzacych.
resource "azurerm_public_ip" "app_outbound" {
  count = var.private_only ? 2 : 0

  name                = count.index == 0 ? "pip-helpdesk-outbound" : "pip-helpdesk02-outbound"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "helpdesk" {
  count = var.private_only ? 0 : 1

  name                = "lb-helpdesk"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb[0].id
  }

}

# Osobny wewnetrzny Load Balancer utrzymuje panel wylacznie w sieci prywatnej.
resource "azurerm_lb" "operator" {
  name                = "lb-helpdesk-operator"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "PrivateIPAddress"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.1.10"
  }

}

resource "azurerm_lb_backend_address_pool" "operator" {
  loadbalancer_id = azurerm_lb.operator.id
  name            = "operator-backend-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "operator_helpdesk01" {
  network_interface_id    = azurerm_network_interface.helpdesk01.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.operator.id
}

resource "azurerm_network_interface_backend_address_pool_association" "operator_helpdesk02" {
  network_interface_id    = azurerm_network_interface.helpdesk02.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.operator.id
}

resource "azurerm_lb_probe" "operator_http" {
  loadbalancer_id = azurerm_lb.operator.id
  name            = "operator-http-probe"
  protocol        = "Http"
  port            = 80
  request_path    = "/health/"
}
resource "azurerm_lb_backend_address_pool" "helpdesk" {
  count = var.private_only ? 0 : 1

  loadbalancer_id = azurerm_lb.helpdesk[0].id
  name            = "backend-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "helpdesk01" {
  count = var.private_only ? 0 : 1

  network_interface_id    = azurerm_network_interface.helpdesk01.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.helpdesk[0].id
}

resource "azurerm_network_interface_backend_address_pool_association" "helpdesk02" {
  count = var.private_only ? 0 : 1

  network_interface_id    = azurerm_network_interface.helpdesk02.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.helpdesk[0].id
}

resource "azurerm_lb_probe" "http" {
  count = var.private_only ? 0 : 1

  loadbalancer_id = azurerm_lb.helpdesk[0].id
  name            = "http-probe"
  protocol        = "Http"
  port            = 80
  request_path    = "/health/"
}

resource "azurerm_lb_rule" "http" {
  count = var.private_only ? 0 : 1

  loadbalancer_id                = azurerm_lb.helpdesk[0].id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"

  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.helpdesk[0].id
  ]

  probe_id = azurerm_lb_probe.http[0].id
}

# HTTPS korzysta z tych samych serwerow i tego samego publicznego adresu IP.
resource "azurerm_lb_rule" "https" {
  count = var.private_only ? 0 : 1

  loadbalancer_id                = azurerm_lb.helpdesk[0].id
  name                           = "https-rule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "PublicIPAddress"

  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.helpdesk[0].id
  ]

  probe_id = azurerm_lb_probe.http[0].id
}


# Prywatne reguly zachowuja wysoka dostepnosc panelu przez oba backendy.
resource "azurerm_lb_rule" "internal_http" {
  loadbalancer_id                = azurerm_lb.operator.id
  name                           = "internal-http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PrivateIPAddress"
  disable_outbound_snat          = true

  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.operator.id
  ]

  probe_id = azurerm_lb_probe.operator_http.id
}

resource "azurerm_lb_rule" "internal_https" {
  loadbalancer_id                = azurerm_lb.operator.id
  name                           = "internal-https-rule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "PrivateIPAddress"
  disable_outbound_snat          = true

  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.operator.id
  ]

  probe_id = azurerm_lb_probe.operator_http.id
}

# Osobna nazwa operatora pozwala zostawic formularz na publicznym adresie.
# Publicznie panel nadal zwraca 403, a host operatora kieruje te nazwe przez VPN.
resource "azurerm_traffic_manager_profile" "operator" {
  count = var.private_only ? 0 : 1

  name                   = "tm-helpdesk-operator"
  resource_group_name    = azurerm_resource_group.main.name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = var.operator_dns_label
    ttl           = 30
  }

  monitor_config {
    protocol = "HTTPS"
    port     = 443
    path     = "/health/"
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "operator" {
  count = var.private_only ? 0 : 1

  name               = "public-helpdesk-endpoint"
  profile_id         = azurerm_traffic_manager_profile.operator[0].id
  target_resource_id = azurerm_public_ip.lb[0].id
  priority           = 1
}

# Bastion zapewnia awaryjny dostep administracyjny bez IP na VM.
resource "azurerm_public_ip" "bastion" {
  count = local.bastion_enabled ? 1 : 0

  name                = "pip-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_bastion_host" "main" {
  count               = local.bastion_enabled ? 1 : 0
  name                = "bastion-helpdesk"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}

# Brama User-to-Site pozwala zarzadzac VM z lokalnego komputera.
resource "azurerm_public_ip" "vpn" {
  count = var.enable_vpn ? 1 : 0

  name                = "pip-vpn-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  allocation_method = "Static"
  sku               = "Standard"

  zones = ["1"]
}

resource "azurerm_virtual_network_gateway" "vpn" {
  count = var.enable_vpn ? 1 : 0

  name                = "vpn-helpdesk"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  bgp_enabled   = false

  sku = "VpnGw1AZ"

  ip_configuration {
    name                          = "vpngatewayconfig"
    public_ip_address_id          = azurerm_public_ip.vpn[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  vpn_client_configuration {
    address_space = [
      "172.20.200.0/24"
    ]


    vpn_client_protocols = ["OpenVPN"]

    root_certificate {
      name             = "vpn-root"
      public_cert_data = var.vpn_root_certificate_base64 != null ? var.vpn_root_certificate_base64 : filebase64("AzureVPNRootCert.cer")
    }
  }
}

# Storage przechowuje zalaczniki, dokumentacje i kopie zapasowe.
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

# Publiczny kontener przechowuje tylko krotkotrwale tokeny potwierdzajace domene dla certyfikatu.
resource "azurerm_storage_container" "acme" {
  name                  = "acme"
  storage_account_id    = azurerm_storage_account.helpdesk.id
  container_access_type = "blob"
}

# Certyfikat jest prywatny i dostepny tylko dla tozsamosci serwerow.
resource "azurerm_storage_container" "certificates" {
  name                  = "certificates"
  storage_account_id    = azurerm_storage_account.helpdesk.id
  container_access_type = "private"
}


# Monitoring zbiera metryki i logi z serwerow Linux.
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-helpdesk-prod"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku               = "PerGB2018"
  retention_in_days = 30
}

resource "azurerm_monitor_data_collection_rule" "main" {
  name                = "dcr-helpdesk-prod"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  kind = "Linux"

  destinations {
    log_analytics {
      name                  = "la-328748078"
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
    }
  }

  data_flow {
    streams       = ["Microsoft-Perf"]
    destinations  = ["la-328748078"]
    output_stream = "Microsoft-Perf"
    transform_kql = "source"
  }

  data_flow {
    streams       = ["Microsoft-Syslog"]
    destinations  = ["la-328748078"]
    output_stream = "Microsoft-Syslog"
    transform_kql = "source"
  }

  data_sources {
    performance_counter {
      name                          = "perfCounterDataSource60"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60

      counter_specifiers = [
        "Processor(*)\\% Processor Time",
        "Processor(*)\\% Idle Time",
        "Processor(*)\\% User Time",
        "Processor(*)\\% Nice Time",
        "Processor(*)\\% Privileged Time",
        "Processor(*)\\% IO Wait Time",
        "Processor(*)\\% Interrupt Time",
        "Memory(*)\\Available MBytes Memory",
        "Memory(*)\\% Available Memory",
        "Memory(*)\\Used Memory MBytes",
        "Memory(*)\\% Used Memory",
        "Memory(*)\\Pages/sec",
        "Memory(*)\\Page Reads/sec",
        "Memory(*)\\Page Writes/sec",
        "Memory(*)\\Available MBytes Swap",
        "Memory(*)\\% Available Swap Space",
        "Memory(*)\\Used MBytes Swap Space",
        "Memory(*)\\% Used Swap Space",
        "Process(*)\\Pct User Time",
        "Process(*)\\Pct Privileged Time",
        "Process(*)\\Used Memory",
        "Process(*)\\Virtual Shared Memory",
        "Logical Disk(*)\\% Free Inodes",
        "Logical Disk(*)\\% Used Inodes",
        "Logical Disk(*)\\Free Megabytes",
        "Logical Disk(*)\\% Free Space",
        "Logical Disk(*)\\% Used Space",
        "Logical Disk(*)\\Logical Disk Bytes/sec",
        "Logical Disk(*)\\Disk Read Bytes/sec",
        "Logical Disk(*)\\Disk Write Bytes/sec",
        "Logical Disk(*)\\Disk Transfers/sec",
        "Logical Disk(*)\\Disk Reads/sec",
        "Logical Disk(*)\\Disk Writes/sec",
        "Network(*)\\Total Bytes Transmitted",
        "Network(*)\\Total Bytes Received",
        "Network(*)\\Total Bytes",
        "Network(*)\\Total Packets Transmitted",
        "Network(*)\\Total Packets Received",
        "Network(*)\\Total Rx Errors",
        "Network(*)\\Total Tx Errors",
        "Network(*)\\Total Collisions",
        "System(*)\\Uptime",
        "System(*)\\Load1",
        "System(*)\\Load5",
        "System(*)\\Load15",
        "System(*)\\Users",
        "System(*)\\Unique Users",
        "System(*)\\CPUs"
      ]
    }

    syslog {
      name = "sysLogsDataSource-1688419672"

      streams = [
        "Microsoft-Syslog"
      ]

      facility_names = [
        "alert",
        "audit",
        "auth",
        "authpriv",
        "clock",
        "cron",
        "daemon",
        "ftp",
        "kern",
        "local0",
        "local1",
        "local2",
        "local3",
        "local4",
        "local5",
        "local6",
        "local7",
        "lpr",
        "mail",
        "news",
        "nopri",
        "ntp",
        "syslog",
        "user",
        "uucp"
      ]

      log_levels = [
        "Debug",
        "Info",
        "Notice",
        "Warning",
        "Error",
        "Critical",
        "Alert",
        "Emergency"
      ]
    }
  }
}

