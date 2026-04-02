variable "resource_group_name" {
  description = "Resource group name for the Azure resources"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for the Azure virtual machines"
  type        = string
}

variable "vm_count" {
  description = "Number of virtual machines to create"
  type        = number
}

variable "vm_name_prefix" {
  description = "Prefix for the virtual machine names"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the virtual machines"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for the virtual machines"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the virtual machines"
  type        = map(string)
  default     = {}
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP address (true/false)"
  type        = bool
  default     = false
}

variable "subnet_prefix" {
  description = "CIDR prefix for the subnet (e.g., 10.0.1.0/24) for generating static IPs"
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machines (e.g., Standard_D2s_v5)"
  type    = string
  default = "Standard_D2s_v5"
}

variable "create_data_disk" {
  description = "Whether to create an additional disk for the database cluster (true/false)"
  type        = bool
  default     = false
}

variable "data_disk_size_gb" {
  description = "Size of the additional data disk in GB (applicable if create_data_disk is true)"
  type    = number
  default = 64
}

variable "storage_container_id" {
  description = "ID of the Azure Storage container for role assignment scope"
  type        = string
}
