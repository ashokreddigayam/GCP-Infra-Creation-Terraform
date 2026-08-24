variable "vm_image" {
  description = "Boot image self-link or family path for the VM"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "vm_name" {
  description = "Name of the Windows VM"
  type        = string
  default     = "windows-iis-vm"
}

variable "machine_type" {
  description = "Machine type for the VM"
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "firewall_rule_name" {
  description = "Firewall rule name"
  type        = string
  default     = "allow-iis-traffic"
}

variable "dashboard_resource_name" {
  description = "Name tag for dashboard integration"
  type        = string
  default     = "windows-iis-dashboard"
}

variable "labels" {
  description = "Labels for resources"
  type        = map(string)
  default = {
    environment = "production"
    application = "iis-server"
    managed_by  = "terraform"
  }
}
