# Simple terraform to spin up a Azure VM for Workstation deployment_mode

#TODO
# modulize


#-------------root/main.tf----------

provider "azurerm" {
  version = "~> 1.27"
}

resource "azurerm_resource_group" "WkstDemo" {
  name     = "${var.resourceGroup}"
  location = "${var.resourceLocation}"

  tags = {
    x-do-not-remove = "${var.x-do-not-remove}"
    X-Contact       = "${var.X-Contact}"
    X-Application   = "${var.X-Application}"
    X-Dept          = "${var.X-Dept}"
    X-Customer      = "${var.X-Customer}"
    X-Project       = "${var.X-Project}"
  }
}

# -----------network----------------
resource "azurerm_virtual_network" "WkstDemo" {
  name                = "WkstDemoVNET"
  resource_group_name = "${azurerm_resource_group.WkstDemo.name}"
  location            = "${azurerm_resource_group.WkstDemo.location}"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "WkstDemo" {
  name                 = "WkstDemoSubnet"
  resource_group_name  = "${azurerm_resource_group.WkstDemo.name}"
  virtual_network_name = "${azurerm_virtual_network.WkstDemo.name}"
  address_prefix       = "10.0.0.0/24"
}

resource "azurerm_public_ip" "WkstDemo" {
  name                = "WkstDemoPublicIp"
  resource_group_name = "${azurerm_resource_group.WkstDemo.name}"
  location            = "${azurerm_resource_group.WkstDemo.location}"
  allocation_method   = "Dynamic"
}

#--------------security------------------
resource "azurerm_network_security_group" "WkstDemo" {
  name                = "WkstDemoNetSecGrp"
  resource_group_name = "${azurerm_resource_group.WkstDemo.name}"
  location            = "${azurerm_resource_group.WkstDemo.location}"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "WkstDemo" {
  name                      = "WkstDemoNIC"
  resource_group_name       = "${azurerm_resource_group.WkstDemo.name}"
  location                  = "${azurerm_resource_group.WkstDemo.location}"
  network_security_group_id = "${azurerm_network_security_group.WkstDemo.id}"

  ip_configuration {
    name                          = "WkstDemoNICcfg"
    subnet_id                     = "${azurerm_subnet.WkstDemo.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.WkstDemo.id}"
  }
}

#-----------------compute-------------------------

resource "azurerm_virtual_machine" "WkstDemo" {
  name                  = "WkstDemoVM"
  location              = "${azurerm_resource_group.WkstDemo.location}"
  resource_group_name   = "${azurerm_resource_group.WkstDemo.name}"
  network_interface_ids = ["${azurerm_network_interface.WkstDemo.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "WkstDemoOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  os_profile {
    computer_name  = "WkstDemo"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCcHhLORvRvCej6WmChXBtS4nt70zdPZwOOARQ/CbUXcZgZBXhJEtHqpVuXWpi1GSxciGviXVnhqsTwiKGnvapD+ekwSDsX8rpCLQy0zjLwnEPUG284t2ZsuYtmjuQqsFVxo2vjmnLu+J70YAjnMtaWBeI13+G4e9iQOZoBXkUA/rAIyB08uRINuok9GwtoO7lyQu7Q2R4hpQbsduV5wF4Pqdxx2UkUmoXwScXLc4QlW3MvJMahKd8k6/1vNvf/bR8jITYuojoCk5wCKhOGFVZQEY+FzClX6VB3LmavikxgNhaPK3C7RWJXBwHsILGJM6H/xXFIaB3b5ihKdH+XkaFOmMYt8hggrIcyn50YPTzWSutjm48lnGtSN/c5ocA10eRAnu1ArUcrjrLQXPFv9GytlXU8BFvgOIaFBWFYbNR3tBdbB7R+coS6GcAAP18EXV+gyf9Wt+Femfh6F6YL1IAQxXIi7Z85sqoaGMIdNm9ZaafLQX310ZyUhbMtGpLqHace3TLCS3a6685ZbWgvfajITHMQ2T4S+nXvN2rbVeqRaNouCDEPJB+UQKeAfzXrr/OG6ZDb8apSe5MMEPj3z9O49f+vgdQv1dOpKWvNeutO8DeAS+9UiRVD4aC/iBttktiytLAs8vW0YXQoQN/Fc0jsZpwKQeE26cgy3mFqOdjxcQ== jlayn@hashicorp.com"
      # key_data = "${file("~/.ssh/jmlayn_rsa.pub")}"
    }
  }
}

data "azurerm_public_ip" "WkstDemo" {
  name                = "${azurerm_public_ip.WkstDemo.name}"
  resource_group_name = "${azurerm_virtual_machine.WkstDemo.resource_group_name}"
}
