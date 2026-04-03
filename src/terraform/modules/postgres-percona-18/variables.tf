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
  default     = 3
}

variable "vm_name_prefix" {
  description = "Prefix for the virtual machine names"
  type        = string
  default     = "percona-node"
}

variable "admin_username" {
  description = "Admin username for the virtual machines"
  type        = string
  default     = "azureuser"
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

variable "subnet_prefix" {
  description = "CIDR prefix for the subnet (e.g., 10.0.1.0/24) for generating static IPs"
  type        = string
  default     = "10.0.1.0/24"
}

variable "nic_ip_configuration_name" {
  description = "Name of NIC IP configuration"
  type        = string
  default     = "internal"
}

variable "private_ip_address_allocation" {
  description = "Private IP allocation method for VM NICs"
  type        = string
  default     = "Static"
}

variable "vm_private_ip_host_offset" {
  description = "Starting host offset in subnet_prefix for cluster VM private IPs"
  type        = number
  default     = 10
}

variable "vm_size" {
  description = "Size of the virtual machines (e.g., Standard_D2s_v5)"
  type    = string
  default = "Standard_D2s_v5"
}

variable "os_disk_caching" {
  description = "OS disk caching mode for VMs"
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "OS disk storage account type for VMs"
  type        = string
  default     = "Premium_LRS"
}

variable "image_publisher" {
  description = "Publisher of VM image"
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "Offer of VM image"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "image_sku" {
  description = "SKU of VM image"
  type        = string
  default     = "22_04-lts"
}

variable "image_version" {
  description = "Version of VM image"
  type        = string
  default     = "latest"
}

variable "create_ansible_host" {
  description = "Whether to create a dedicated host for running Ansible deployment"
  type        = bool
  default     = true
}

variable "ansible_host_name" {
  description = "Name of the VM used as Ansible deployment host"
  type        = string
  default     = "percona-ansible-host"
}

variable "ansible_host_vm_size" {
  description = "Size of the Ansible deployment host VM"
  type        = string
  default     = "Standard_B2s"
}

variable "ansible_host_private_ip_hostnumber" {
  description = "Host number in subnet_prefix used for static private IP of Ansible host"
  type        = number
  default     = 250
}

variable "create_data_disk" {
  description = "Whether to create an additional disk for the database cluster (true/false)"
  type        = bool
  default     = false
}

variable "data_disk_storage_account_type" {
  description = "Storage account type for additional data disk"
  type        = string
  default     = "Premium_LRS"
}

variable "data_disk_create_option" {
  description = "Create option for additional data disk"
  type        = string
  default     = "Empty"
}

variable "data_disk_size_gb" {
  description = "Size of the additional data disk in GB (applicable if create_data_disk is true)"
  type    = number
  default = 64
}

variable "data_disk_attachment_lun" {
  description = "LUN for attaching additional data disk"
  type        = number
  default     = 10
}

variable "data_disk_attachment_caching" {
  description = "Caching mode for attached additional data disk"
  type        = string
  default     = "ReadOnly"
}

variable "vnet_id" {
  description = "Virtual network ID used by the load balancer backend pool"
  type        = string
}

variable "lb_name" {
  description = "Name of the internal Azure load balancer"
  type        = string
  default     = "ppg-internal-lb"
}

variable "lb_frontend_private_ip_address" {
  description = "Static private IP address assigned to the load balancer frontend"
  type        = string
  default     = "10.0.0.100"
}

variable "lb_frontend_configuration_name" {
  description = "Name of the LB frontend IP configuration"
  type        = string
  default     = "private-frontend"
}

variable "lb_sku" {
  description = "SKU for the load balancer"
  type        = string
  default     = "Standard"
}

variable "lb_private_ip_address_allocation" {
  description = "Private IP allocation method for LB frontend"
  type        = string
  default     = "Static"
}

variable "lb_default_protocol" {
  description = "Default LB rule protocol when not provided in rule"
  type        = string
  default     = "Tcp"
}

variable "lb_default_idle_timeout_in_minutes" {
  description = "Default idle timeout for LB rules"
  type        = number
  default     = 4
}

variable "lb_default_disable_outbound_snat" {
  description = "Default outbound SNAT behavior for LB rules"
  type        = bool
  default     = false
}

variable "lb_rules" {
  description = "Map of load balancer rules keyed by logical rule name"
  type = map(object({
    frontend_port           = number
    backend_port            = optional(number)
    protocol                = optional(string)
    probe_port              = optional(number)
    probe_protocol          = optional(string)
    probe_request_path      = optional(string)
    idle_timeout_in_minutes = optional(number)
    disable_outbound_snat   = optional(bool)
  }))

  default = {
    postgres = {
      frontend_port      = 5432
      backend_port       = 6432
      probe_port         = 8008
      probe_protocol     = "Http"
      probe_request_path = "/primary"
    }
  }
}

variable "lb_probe_interval_in_seconds" {
  description = "Interval between health probe attempts"
  type        = number
  default     = 5
}

variable "lb_number_of_probes" {
  description = "How many failed probes mark a backend as unhealthy"
  type        = number
  default     = 2
}
