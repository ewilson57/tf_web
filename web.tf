provider "azurerm" {
  version = "2.9.0"
  features {
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  name                            = "${local.virtual_machine_name}-${format("%03d", count.index)}"
  location                        = azurerm_resource_group.web.location
  resource_group_name             = azurerm_resource_group.web.name
  network_interface_ids           = [azurerm_network_interface.web[count.index].id]
  size                            = "Standard_D1_v2"
  availability_set_id             = azurerm_availability_set.web.id
  disable_password_authentication = true
  admin_username                  = var.admin_username
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

resource "azurerm_availability_set" "web" {
  name                = "${var.prefix}-aset"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
}

resource "azurerm_public_ip" "web-lb" {
  name                = "${var.prefix}-lb-publicip"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  allocation_method   = "Dynamic"
}

resource "azurerm_lb" "web" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.web-lb.id
  }
}

resource "azurerm_lb_rule" "web" {
  resource_group_name            = azurerm_resource_group.web.name
  loadbalancer_id                = azurerm_lb.web.id
  name                           = "http_rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
}

resource "azurerm_lb_probe" "web" {
  resource_group_name = azurerm_resource_group.web.name
  loadbalancer_id     = azurerm_lb.web.id
  name                = "http-probe"
  port                = 80
  interval_in_seconds = 30
  number_of_probes    = 2
}

resource "azurerm_lb_backend_address_pool" "web" {
  resource_group_name = azurerm_resource_group.web.name
  loadbalancer_id     = azurerm_lb.web.id
  name                = "web-servers"
}

resource "azurerm_lb_nat_rule" "web" {
  count                          = 2
  resource_group_name            = azurerm_resource_group.web.name
  loadbalancer_id                = azurerm_lb.web.id
  name                           = azurerm_linux_virtual_machine.web[count.index]
  protocol                       = "tcp"
  frontend_port                  = "5000${count.index + 1}"
  backend_port                   = "22"
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
}
