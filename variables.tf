variable "prefix" {
  description = "The Prefix used for all resources in this example"
  default     = "web"
}

variable "location" {
  description = "The Azure Region in which the resources in this example should exist"
  default     = "South Central US"
}

variable "virtual_machine_name" {
  default = "web-vm"
}

variable "router_wan_ip" {
  description = "The IP address of the routers external interface"
  default     = ""
}

variable "admin_username" {
  description = "The admin user"
  default     = ""
}

variable "admin_password" {
  description = "admin password"
  default     = ""
}

variable "ssh_key" {
  description = "ssh public key"
  default     = ""
}

variable "azurerm_lb_backend_address_pool" {
  default = "web-server-pool"
}

variable "azurerm_lb_rule" {
  default = "http-rule"
}

variable "azurerm_lb_probe" {
  default = "http-probe"
}
