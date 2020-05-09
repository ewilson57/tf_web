variable "prefix" {
  description = "The Prefix used for all resources in this example"
  default     = "web"

}

variable "location" {
  description = "The Azure Region in which the resources in this example should exist"
  default     = "South Central US"
}

variable "router_wan_ip" {
  description = "The IP address of the routers external interface"
  default     = "192.180.173.26/32"
}
