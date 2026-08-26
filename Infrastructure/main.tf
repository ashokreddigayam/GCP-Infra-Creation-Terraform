# Create Windows VM with IIS installation
resource "google_compute_instance" "windows_vm" {
  name                      = var.vm_name
  machine_type              = var.machine_type
  zone                      = var.gcp_zone
  allow_stopping_for_update = true

  labels = merge(
    var.labels,
    {
      dashboard_integration = var.dashboard_resource_name
    }
  )

  tags = ["iis-server", "windows-vm", var.dashboard_resource_name]

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.boot_disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = "default"
    subnetwork = "default"

    access_config {}
  }

  metadata = {
    # GCP executes this natively as PowerShell — no CMD wrapper, supports multi-line correctly
    windows-startup-script-ps1 = <<-EOT
      # Install all IIS features in one call — significantly faster than individual installs
      Install-WindowsFeature -Name Web-Server, Web-Default-Doc, Web-Http-Errors, Web-Static-Content, Web-Http-Logging, Web-App-Dev, Web-Net-Ext45, Web-Asp-Net45 -IncludeManagementTools | Out-Null

      # Download and install .NET 8.0 Hosting Bundle for ASP.NET Core support in IIS
      $hostingUrl = "https://download.visualstudio.microsoft.com/download/pr/49e9ce63-e380-4ef1-897b-9c2ae59e74c8/1e737c35f2a1b9e2c6cb3448ff61dfbd/dotnet-hosting-8.0.10-win.exe"
      $installer  = "$env:TEMP\dotnet-hosting.exe"
      Invoke-WebRequest -Uri $hostingUrl -OutFile $installer -UseBasicParsing -ErrorAction SilentlyContinue
      if (Test-Path $installer) {
        Start-Process -FilePath $installer -ArgumentList '/q /norestart' -Wait
        net stop was /y -ErrorAction SilentlyContinue
        net start w3svc -ErrorAction SilentlyContinue
      }

      $installTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
      $serverName  = $env:COMPUTERNAME

      $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
  <title>IIS Server Status</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
    .container { background-color: white; padding: 30px; border-radius: 5px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
    h1 { color: #0078d4; }
    .info { background-color: #e7f3ff; padding: 15px; border-left: 4px solid #0078d4; margin: 10px 0; }
  </style>
</head>
<body>
  <div class="container">
    <h1>IIS Server is Running</h1>
    <div class="info">
      <p><strong>Server Name:</strong> $serverName</p>
      <p><strong>Server Status:</strong> Healthy</p>
      <p><strong>Dashboard Integration:</strong> Enabled</p>
      <p><strong>Installation Time:</strong> $installTime</p>
    </div>
  </div>
</body>
</html>
"@

      $iisPath = 'C:\inetpub\wwwroot\index.html'
      Set-Content -Path $iisPath -Value $htmlContent -Encoding UTF8
      icacls $iisPath /grant 'IIS AppPool\DefaultAppPool:(OI)(CI)M'

      # Open Windows Firewall for HTTP (IIS install does not always do this automatically)
      New-NetFirewallRule -DisplayName 'IIS HTTP'      -Direction Inbound -Protocol TCP -LocalPort 80   -Action Allow -ErrorAction SilentlyContinue
      New-NetFirewallRule -DisplayName 'IIS HTTP 8080' -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow -ErrorAction SilentlyContinue

      # Ensure IIS service is running and set to auto-start
      Set-Service   W3SVC -StartupType Automatic
      Start-Service W3SVC

      Write-EventLog -LogName Application -Source 'GCPStartup' -EntryType Information -EventId 1 -Message 'IIS setup complete' -ErrorAction SilentlyContinue
    EOT
  }

  service_account {
    # uses the Compute Engine default service account
    scopes = ["cloud-platform"]
  }
}

# Allow HTTP (80) and DemoApp (8080) inbound — blocked by default in GCP
resource "google_compute_firewall" "allow_http" {
  name    = "allow-iis-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  # Applies only to VMs tagged as iis-server
  target_tags   = ["iis-server"]
  source_ranges = ["0.0.0.0/0"]
}
