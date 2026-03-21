variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-ppg-cluster-dev"
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "polandcentral"
}

variable "vnet" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "database_subnet" {
  description = "Database subnet address space"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "jumpbox_subnet" {
  description = "Jumpbox subnet address space"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "admin_username" {
  description = "Administrator username for all virtual machines"
  type        = string
  default     = "oleksandrix"
}

variable "ssh_pub_key_path" {
  description = "Path to the public SSH key for VM access"
  type        = string
  default     = "~/.ssh/azure-ppg-cluster.pub"
}

variable "admin_ip" {
  description = "My public IP address for SSH access to Jumpbox"
  type        = string
}
