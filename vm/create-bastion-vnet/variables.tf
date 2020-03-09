variable "location" {
  description = "(optional: default=japaneast) The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
  default     = "japaneast"
}

variable "resource_group_name" {
  description = "The name of the resource group where the load balancer resources will be placed."
}

variable "prefix" {
  description = "Default prefix to use with your resource names."
  default     = ""
}

variable "vnet_address_space" {
  description = "Address space for virtual network"
  default     = "10.0.0.0/16"
}

variable "default_address_prefix" {
  description = "Address prefix for the default subnet"
  default     = "10.0.0.0/24"
}
variable "bastion_address_prefix" {
  description = "Address prefix for the bastion subnet"
  default     = "10.0.1.0/24"
}

variable "vm_size" {
  description = "The size of Virtual Machine."
  default     = "Standard_B1mS"
}

variable "username" {
  description = "Administrator user name."
}

variable "password" {
  description = "Administrator password (recommended to disable password auth)"
}

variable "tags" {
  description = "(optional) Tags that describe your resources."
  default = {
    source = "terraform"
  }
}
