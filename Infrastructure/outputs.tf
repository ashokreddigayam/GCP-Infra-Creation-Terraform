output "vm_name" {
  description = "Name of the Windows VM"
  value       = google_compute_instance.windows_vm.name
}

output "vm_id" {
  description = "Instance ID of the Windows VM"
  value       = google_compute_instance.windows_vm.id
}

output "vm_zone" {
  description = "Zone of the Windows VM"
  value       = google_compute_instance.windows_vm.zone
}

output "public_ip" {
  description = "Public IP address of the Windows VM"
  value       = google_compute_instance.windows_vm.network_interface[0].access_config[0].nat_ip
}

output "private_ip" {
  description = "Private IP address of the Windows VM"
  value       = google_compute_instance.windows_vm.network_interface[0].network_ip
}

output "iis_url" {
  description = "URL to access IIS server"
  value       = "http://${google_compute_instance.windows_vm.network_interface[0].access_config[0].nat_ip}"
}

output "rdp_connection_string" {
  description = "RDP connection information"
  value       = "RDP to: ${google_compute_instance.windows_vm.network_interface[0].access_config[0].nat_ip}:3389"
}

output "network_name" {
  description = "Name of the VPC network (default)"
  value       = "default"
}

output "subnet_name" {
  description = "Name of the subnet (default)"
  value       = "default"
}

output "service_account_email" {
  description = "Service account email for the VM"
  value       = google_compute_instance.windows_vm.service_account[0].email
}

output "vm_labels" {
  description = "Labels attached to the VM for dashboard identification"
  value       = google_compute_instance.windows_vm.labels
}

output "vm_tags" {
  description = "Tags attached to the VM"
  value       = google_compute_instance.windows_vm.tags
}

output "dashboard_integration_id" {
  description = "Identifier for dashboard integration"
  value       = var.dashboard_resource_name
}
