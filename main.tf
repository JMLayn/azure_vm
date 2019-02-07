# Simple terraform to spin up a Azure VM for Workstation deployment_mode

#TODO
# output the ipaddress
# modulize


#-------------root/main.tf----------

provider "azurerm" {
  version = "=1.21.0"
}

resource "azurerm_resource_group" "WkstDemo" {
  name     = "JMLaynRG2"
  location = "eastus2"

  tags {
    do-not-remove = "do-not-remove"
    X-Contact     = "JMLayn"
    X-Application = "NA-East"
    X-Dept        = "Sales"
    X-Customer    = "Workstation Demo"
    X-Project     = "Workstation Demo"
  }
}

#-----------network----------------
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
  name                         = "WkstDemoPublicIp"
  resource_group_name          = "${azurerm_resource_group.WkstDemo.name}"
  location                     = "${azurerm_resource_group.WkstDemo.location}"
  public_ip_address_allocation = "dynamic"
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
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
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
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }
}

data "azurerm_public_ip" "WkstDemo" {
  name = "${azurerm_public_ip.WkstDemo.name}"
  resource_group_name = "${azurerm_virtual_machine.WkstDemo.resource_group_name}"
}

output "ip_address" {
  value = "${data.azurerm_public_ip.WkstDemo.ip_address}"
}
