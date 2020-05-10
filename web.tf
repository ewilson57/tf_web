provider "azurerm" {
  version = "2.9.0"
  features {}
}

resource "azurerm_linux_virtual_machine" "web" {
  name                            = "${local.virtual_machine_name}-${format("%03d", count.index)}"
  location                        = azurerm_resource_group.web.location
  resource_group_name             = azurerm_resource_group.web.name
  network_interface_ids           = [azurerm_network_interface.web[count.index].id]
  size                            = "Standard_D1_v2"
  admin_username                  = var.admin_username
  disable_password_authentication = true
  custom_data                     = filebase64("files/web_bootstrap.sh")

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa_${var.admin_username}.pub")
  }

  count = 2
}
