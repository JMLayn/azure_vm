resource "azurerm_virtual_network" "WkstDemo" {
  name                = "WkstDemoVNET"
  resource_group_name = "${azurerm_resource_group.WkstDemo.name}"
  location            = "${azurerm_resource_group.WkstDemo.location}"
  address_space       = ["10.0.0.0/16"]
}
