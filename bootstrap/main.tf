# Bootstrap jest niezalezny od glownego stanu Helpdesku.
data "azurerm_resource_group" "workload" {
  name = var.workload_resource_group_name
}

data "azurerm_client_config" "current" {}

data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.workload.name
}

data "azurerm_subnet" "management" {
  name                 = var.management_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.workload.name
}

data "azurerm_storage_account" "tfstate" {
  name                = var.tfstate_storage_account_name
  resource_group_name = var.tfstate_resource_group_name
}

resource "azurerm_resource_group" "management" {
  name     = var.management_resource_group_name
  location = var.location
}

resource "azurerm_network_security_group" "management" {
  name                = "nsg-ansible-mgmt"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name

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
}

resource "azurerm_network_interface" "management" {
  name                = "nic-ansible-mgmt"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.management.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.2.10"
  }
}

resource "azurerm_network_interface_security_group_association" "management" {
  network_interface_id      = azurerm_network_interface.management.id
  network_security_group_id = azurerm_network_security_group.management.id
}

resource "azurerm_linux_virtual_machine" "management" {
  name                = "ansible-mgmt"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.management.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 32
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

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml.tftpl", {
    helpdesk_fqdn = var.helpdesk_fqdn
    operator_fqdn = var.operator_fqdn
  }))

  # Glowny Terraform nie zarzadza ta VM, a bootstrap nie moze jej przypadkiem usunac.
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    role       = "automation"
    managed_by = "terraform-bootstrap"
  }
}

# Runner zarzadza zasobami aplikacji, ale tylko w glownej grupie projektu.
resource "azurerm_role_assignment" "workload_contributor" {
  scope                = data.azurerm_resource_group.workload.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_virtual_machine.management.identity[0].principal_id
}

# Glowna konfiguracja tworzy przypisania rol dla Managed Identity serwerow.
resource "azurerm_role_assignment" "workload_role_admin" {
  scope                = data.azurerm_resource_group.workload.id
  role_definition_name = "User Access Administrator"
  principal_id         = azurerm_linux_virtual_machine.management.identity[0].principal_id
}

# Dostep do pliku stanu odbywa sie przez Entra ID, bez klucza konta Storage.
resource "azurerm_role_assignment" "tfstate_blob" {
  scope                = data.azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.management.identity[0].principal_id
}

# GitHub-hosted workflow moze tylko sterowac VM w grupie zarzadzajacej.
resource "azurerm_user_assigned_identity" "github_control" {
  name                = "id-github-runner-control"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
}

resource "azurerm_federated_identity_credential" "github_control" {
  name                = "github-production"
  resource_group_name = azurerm_resource_group.management.name
  parent_id           = azurerm_user_assigned_identity.github_control.id
  issuer              = "https://token.actions.githubusercontent.com"
  audience            = ["api://AzureADTokenExchange"]
  subject             = "repo:${var.github_repository}:environment:production"
}

resource "azurerm_role_assignment" "github_vm_control" {
  scope                = azurerm_resource_group.management.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.github_control.principal_id
}
