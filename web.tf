provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
}

resource "azurerm_availability_set" "web" {
  name                = "${var.prefix}-aset"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
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
    public_key = var.ssh_key
  }
  count = 2
  depends_on = [azurerm_lb_rule.web]
}

resource "azurerm_public_ip" "web-lb" {
  name                = "${var.prefix}-lb-publicip"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  allocation_method   = "Static"
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

locals {
  azurerm_lb_backend_address_pool = "web-server-pool"
  azurerm_lb_rule                 = "http-rule"
  azurerm_lb_probe                = "http-probe"
}

resource "azurerm_lb_backend_address_pool" "web" {
  resource_group_name = azurerm_resource_group.web.name
  loadbalancer_id     = azurerm_lb.web.id
  name                = local.azurerm_lb_backend_address_pool
}

resource "azurerm_lb_rule" "web" {
  resource_group_name            = azurerm_resource_group.web.name
  loadbalancer_id                = azurerm_lb.web.id
  name                           = local.azurerm_lb_rule
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.web.id
  probe_id                       = azurerm_lb_probe.web.id
}

resource "azurerm_lb_probe" "web" {
  resource_group_name = azurerm_resource_group.web.name
  loadbalancer_id     = azurerm_lb.web.id
  name                = local.azurerm_lb_probe
  port                = 80
  interval_in_seconds = 30
  number_of_probes    = 2
}

resource "azurerm_lb_nat_rule" "web" {
  count                          = 2
  resource_group_name            = azurerm_resource_group.web.name
  loadbalancer_id                = azurerm_lb.web.id
  name                           = azurerm_linux_virtual_machine.web[count.index].name
  protocol                       = "tcp"
  frontend_port                  = "5000${count.index}"
  backend_port                   = "22"
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
}

resource "azurerm_network_interface_backend_address_pool_association" "web" {
  network_interface_id    = azurerm_network_interface.web[count.index].id
  ip_configuration_name   = "configuration"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
  count                   = 2
}
