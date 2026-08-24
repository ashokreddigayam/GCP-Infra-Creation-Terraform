# Windows IIS VM on GCP — Full Deployment Steps

**Project:** supple-apricot-504106-m6  
**VM Public IP:** 34.69.10.188  
**Deployed on:** 2026-08-18  

---

## 1. Prerequisites

| Tool | Version | Where |
|------|---------|--------|
| Terraform | v1.15.8 | RHEL server (installed via winget on Windows) |
| gcloud CLI | latest | RHEL server |
| Service Account Key | supple-apricot-504106-m6-3e44cc1b3143.json | `/tmp/Vulnerabilities/Infrastructure/` on RHEL |

---

## 2. Terraform Code Fixes Applied

### provider.tf
- Added `credentials = file(...)` pointing to the service account JSON key
- Used `var.gcp_project_id` and `var.gcp_region` for project config

### main.tf
- Removed `data "google_compute_subnetwork"` — service account lacked `compute.subnetworks.get`
- Removed `data "google_compute_network"` — service account lacked `compute.networks.get`
- Removed `google_project_service` blocks — service account lacked `serviceusage` permissions
- Removed `google_compute_firewall` blocks — service account lacked `compute.firewalls.create`
- Removed `google_service_account` + `google_project_iam_member` — IAM API not enabled
- Fixed Windows image: used `projects/windows-cloud/global/images/family/windows-2022` (family name is `windows-2022`, NOT `windows-server-2022-dc`)
- Set `access_config {}` (removed invalid `nat_ip = ""`)
- VM uses Compute Engine default service account (`381228042809-compute@developer.gserviceaccount.com`)
- Network and subnetwork hardcoded to `"default"`

### variables.tf
- Added `vm_image` variable for configurable boot image

### terraform.tfvars
- `gcp_project_id` = `supple-apricot-504106-m6` (sourced from service account JSON `project_id` field)
- `machine_type` = `e2-medium` (minimum for Windows Server — e2-micro is too small)
- `boot_disk_size` = `50` (minimum for Windows Server 2022)
- `vm_image` = `projects/windows-cloud/global/images/family/windows-2022`

---

## 3. GCP IAM Permissions Granted

Granted to `381228042809-compute@developer.gserviceaccount.com` via GCP Console → IAM & Admin:

| Role | Purpose |
|------|---------|
| `roles/compute.admin` | Create VM instances, disks, metadata |
| `roles/iam.serviceAccountUser` | Attach service account to VM |

---

## 4. Deployment Commands (Run on RHEL Server)

```bash
cd /path/to/Infrastructure

# Initialize Terraform (downloads Google provider)
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply --auto-approve
```

### Terraform Outputs After Successful Apply
```
public_ip              = "34.69.10.188"
private_ip             = "10.128.0.2"
iis_url                = "http://34.69.10.188"
rdp_connection_string  = "RDP to: 34.69.10.188:3389"
vm_name                = "windows-iis-vm"
vm_zone                = "us-central1-a"
service_account_email  = "381228042809-compute@developer.gserviceaccount.com"
```

---

## 5. Post-Deployment — Manual GCP Steps

These could not be done via Terraform (service account lacked permissions), so they were done via gcloud.

### 5a. Create Firewall Rules
```bash
# Allow HTTP/HTTPS for IIS
gcloud compute firewall-rules create allow-iis-traffic \
  --network=default \
  --allow=tcp:80,tcp:443 \
  --target-tags=iis-server \
  --source-ranges=0.0.0.0/0 \
  --project=supple-apricot-504106-m6

# Allow RDP for administration
gcloud compute firewall-rules create allow-rdp \
  --network=default \
  --allow=tcp:3389 \
  --target-tags=iis-server \
  --source-ranges=0.0.0.0/0 \
  --project=supple-apricot-504106-m6
```

### 5b. Install IIS via Startup Script (Terraform startup script didn't execute on first boot)

```bash
# Write IIS setup script to a file
cat > /tmp/iis-setup.ps1 << 'SCRIPT'
Install-WindowsFeature -Name Web-Server -IncludeManagementTools | Out-Null
Install-WindowsFeature -Name Web-Default-Doc,Web-Http-Errors,Web-Static-Content,Web-Http-Logging,Web-Asp-Net45,Web-Net-Ext45 | Out-Null
netsh advfirewall firewall add rule name="Allow HTTP" protocol=TCP dir=in localport=80 action=allow
netsh advfirewall firewall add rule name="Allow HTTPS" protocol=TCP dir=in localport=443 action=allow
$html = '<html><head><title>IIS Server Status</title></head><body><h1>IIS Server is Running</h1><p>Server: ' + $env:COMPUTERNAME + '</p></body></html>'
Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value $html -Encoding UTF8
Start-Service W3SVC -ErrorAction SilentlyContinue
SCRIPT

# Push the script as VM metadata
gcloud compute instances add-metadata windows-iis-vm \
  --zone=us-central1-a \
  --project=supple-apricot-504106-m6 \
  --metadata-from-file=windows-startup-script-ps1=/tmp/iis-setup.ps1

# Reset VM to trigger the startup script
gcloud compute instances reset windows-iis-vm \
  --zone=us-central1-a \
  --project=supple-apricot-504106-m6
```

### 5c. Verify IIS is Running
```bash
# Wait ~5 minutes then test
curl -s -o /dev/null -w "%{http_code}" http://34.69.10.188
# Expected: 200
```

---

## 6. IIS Web Page Location (Inside VM)

| Item | Path |
|------|------|
| Web root | `C:\inetpub\wwwroot\` |
| Default page | `C:\inetpub\wwwroot\index.html` |
| IIS service | `W3SVC` |

To check via PowerShell inside the VM (RDP):
```powershell
Test-Path "C:\inetpub\wwwroot\index.html"
Get-Service W3SVC
Get-Content "C:\inetpub\wwwroot\index.html"
```

---

## 7. Troubleshooting Reference

| Error | Root Cause | Fix Applied |
|-------|-----------|-------------|
| `compute.subnetworks.get` 403 | SA missing permission | Removed data source, hardcoded `"default"` |
| `compute.networks.get` 403 | SA missing permission | Removed data source, hardcoded `"default"` |
| `serviceusage` 403 | SA missing permission | Removed `google_project_service` blocks |
| `compute.firewalls.create` 403 | SA missing permission | Removed firewall resources, created via gcloud |
| IAM API not enabled | API disabled | Removed service account resource |
| Image 404 | Wrong family name (`windows-server-2022-dc`) | Changed to `windows-2022` |
| Port 80 timeout | Windows Firewall + IIS not installed | Pushed startup script via metadata |

---

## 8. Destroy Infrastructure (When No Longer Needed)

```bash
terraform destroy --auto-approve

# Also delete manually-created firewall rules
gcloud compute firewall-rules delete allow-iis-traffic --project=supple-apricot-504106-m6 -q
gcloud compute firewall-rules delete allow-rdp --project=supple-apricot-504106-m6 -q
```
