variable "selectel_domain" {
  description = "Selectel account domain (account ID)"
  type        = string
  default     = null
}

variable "selectel_username" {
  description = "Selectel username"
  type        = string
  default     = null
}

variable "selectel_password" {
  description = "Selectel password"
  type        = string
  sensitive   = true
  default     = null
}

variable "selectel_openstack_password" {
  description = "Password for OpenStack service user"
  type        = string
  sensitive   = true
  default     = null
}

variable "environment_name" {
  description = "Environment name suffix for resources"
  type        = string
  default     = "ai-toolkit"
}

variable "region" {
  description = "Selectel region"
  type        = string
  default     = "ru-7"
}

variable "availability_zone" {
  description = "Selectel availability zone"
  type        = string
  default     = "ru-7b"
}

variable "image_name" {
  description = "Image name for VM"
  type        = string
  default     = "Ubuntu 24.04 LTS 64-bit"
}

variable "flavor_name" {
  description = "Optional existing OpenStack flavor name (use for GPU flavors, e.g. compute_pci_gpu_rtx4080). If empty, custom CPU flavor is created from cpu_count/ram_gb"
  type        = string
  default     = ""
}

variable "cpu_count" {
  description = "vCPU count for AI Toolkit VM"
  type        = number
  default     = 8
}

variable "ram_gb" {
  description = "RAM in GB for AI Toolkit VM"
  type        = number
  default     = 32
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 200
}

variable "disk_type" {
  description = "Disk type: fast, universal2, universal, basicssd, basic"
  type        = string
  default     = "fast"

  validation {
    condition     = contains(["fast", "universal2", "universal", "basicssd", "basic"], var.disk_type)
    error_message = "disk_type must be one of: fast, universal2, universal, basicssd, basic"
  }
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH (22)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_ui_cidr" {
  description = "CIDR allowed to access AI Toolkit UI (8675)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "nvidia_driver_version" {
  description = "NVIDIA driver version to install (e.g. 590, 570, 535)"
  type        = string
  default     = "590"
}

variable "ai_toolkit_auth" {
  description = "Optional auth token for AI Toolkit UI"
  type        = string
  sensitive   = true
  default     = ""
}
