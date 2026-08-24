# GCP Configuration
gcp_project_id = "supple-apricot-504106-m6"
gcp_region     = "us-central1"
gcp_zone       = "us-central1-a"

# VM Configuration
vm_name         = "windows-iis-vm"
machine_type    = "e2-medium"
boot_disk_size  = 50
# run on RHEL: gcloud compute images list --filter="name~windows" --project=supple-apricot-504106-m6
vm_image        = "projects/windows-cloud/global/images/family/windows-2022"

# Firewall Configuration
firewall_rule_name = "allow-iis-traffic"

# Dashboard Integration
dashboard_resource_name = "windows-iis-dashboard"

# Resource Labels
labels = {
  environment = "production"
  application = "iis-server"
  managed_by  = "terraform"
  dashboard   = "enabled"
}
