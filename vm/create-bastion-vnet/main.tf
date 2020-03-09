provider "azurerm" {
  version = "=1.41"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}


##########
# VNet
##########

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_address_space]
}

resource "azurerm_subnet" "default" {
  name                 = "default-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = var.default_address_prefix
}

resource "azurerm_subnet" "bastion" {
  name                 = "bastion-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = var.bastion_address_prefix
}

resource "azurerm_network_security_group" "bastion" {
  name                = "${var.prefix}nsg-bastion"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_network_security_group" "default" {
  name                = "${var.prefix}nsg-default"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.default.id
}

#####
resource "random_id" "sa" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

resource "azurerm_storage_account" "diag" {
  name                     = "diag${random_id.sa.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  tags                     = var.tags
}


# Bastion Virtual Machine
#############################################################

locals {
  bastion_vm_name = "${var.prefix}vm-bastion"
}

resource "azurerm_public_ip" "bastion" {
  name                = "${local.bastion_vm_name}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "bastion" {
  name                = "${local.bastion_vm_name}-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.bastion.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_virtual_machine" "bastion" {
  name                = local.bastion_vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vm_size             = var.vm_size
  network_interface_ids = [
    azurerm_network_interface.bastion.id,
  ]

  # admin_ssh_key {
  #   username   = var.username
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  os_profile {
    computer_name  = local.bastion_vm_name
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-${local.bastion_vm_name}"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
    caching           = "ReadWrite"
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.diag.primary_blob_endpoint
  }
}

# Workload Virtual Machines
#####################################

locals {
  instance_count = 2
}

resource "azurerm_network_interface" "server" {
  count               = local.instance_count
  name                = "${var.prefix}vm-server-${count.index}-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_virtual_machine" "server" {
  count               = local.instance_count
  name                = "${var.prefix}vm-server-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vm_size             = var.vm_size
  network_interface_ids = [
    "${element(azurerm_network_interface.server.*.id, count.index)}"
  ]

  # admin_ssh_key {
  #   username   = var.username
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  os_profile {
    computer_name  = "${var.prefix}vm-server-${count.index}"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-${var.prefix}vm-server-${count.index}"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
    caching           = "ReadWrite"
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.diag.primary_blob_endpoint
  }
}
