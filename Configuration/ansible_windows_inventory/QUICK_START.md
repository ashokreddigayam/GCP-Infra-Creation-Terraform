# ==============================================================================
# QUICK START GUIDE
# ==============================================================================

## 🚀 5-Minute Quick Start

### 1. Install Ansible Collections

**Windows:**
```cmd
setup.bat
```

**Linux/Mac:**
```bash
chmod +x setup.sh
./setup.sh
```

Or manually:
```bash
pip install ansible
ansible-galaxy install -r requirements.yml
```

---

### 2. Configure Your Servers

Edit `inventory.ini`:

```ini
[source_server]
source_server ansible_host=192.168.1.100 ansible_user=Administrator

[destination_server]
destination_server ansible_host=192.168.1.101 ansible_user=Administrator
```

---

### 3. Enable WinRM on Windows Servers

Run as **Administrator** on each Windows server:

```powershell
# Enable WinRM
Enable-PSRemoting -Force

# Configure for Ansible (HTTP - for testing only)
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*"

# Verify WinRM is running
Get-Service WinRM | Select-Object Status
```

**For Production (HTTPS):**
```powershell
# Create self-signed certificate (if not using domain certificates)
$cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "$(hostname)"

# Create HTTPS listener
New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Transport="HTTPS"} -ValueSet @{CertificateThumbprint=$cert.Thumbprint}

# Configure firewall
New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "WinRM over HTTPS" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5986
```

---

### 4. Test Connectivity

```bash
ansible -i inventory.ini source_server -m win_ping
ansible -i inventory.ini destination_server -m win_ping
```

Expected output:
```
source_server | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

---

### 5. Run the Workflow

```bash
# Option A: Run complete workflow (all 3 phases)
ansible-playbook run-complete-workflow.yml

# Option B: Run individual phases
ansible-playbook discover-windows-state.yml
ansible-playbook interactive-selection.yml
ansible-playbook deploy-to-destination.yml
```

---

## 📊 What Happens in Each Phase

### Phase 1: Discovery
✓ Scans registry for installed software  
✓ Collects IIS configuration  
✓ Scans application directories  
⏱ Typical duration: 2-5 minutes  
📁 Output: `vars/discovery_output.json`

### Phase 2: Interactive Selection
✓ Displays PowerShell menu  
✓ User selects items to deploy  
✓ Confirms selections  
⏱ Typical duration: 2-10 minutes (user-dependent)  
📁 Output: `vars/selection_results.json`

### Phase 3: Deployment
✓ Creates IIS app pools and sites  
✓ Configures bindings  
✓ Prepares file deployment  
⏱ Typical duration: 5-15 minutes  
📁 Output: `vars/deployment_log.json`

---

## 🎯 Interactive Menu Usage

When Phase 2 launches, you'll see:

```
=================================================================================
WINDOWS INFRASTRUCTURE SELECTION TOOL
=================================================================================

Hostname: PROD-SERVER-01
OS: Windows_NT 10.0.19042

Discovery Summary:
  - Installed Software: 142 items
  - IIS Installed: yes
  - IIS Sites: 5 sites

Press Enter to start selection process

Step 1 of 3: SELECT SOFTWARE
=================================================================================
SELECT INSTALLED SOFTWARE TO DEPLOY
=================================================================================

[1] Microsoft Visual C++ 2019 Redistributable (x64) - 14.29.30139
[2] Microsoft .NET Framework 4.8
[3] Node.js
[4] Git for Windows
[5] Visual Studio Code
...
[0] Go Back / Skip

Select items (comma-separated numbers, 0 to finish): 1,2,4
```

**Selection Tips:**
- Enter `1,2,4` to select items 1, 2, and 4
- Enter `0` to skip this category
- Selections are cumulative
- Review summary before confirming

---

## 📋 File Structure After Execution

```
ansible_windows_inventory/
├── vars/
│   ├── discovery_output.json         ← Phase 1 output
│   ├── selection_results.json        ← Phase 2 output
│   └── deployment_log.json           ← Phase 3 output
├── ansible_execution.log             ← Execution log
└── run-complete-workflow.yml          ← Master playbook
```

---

## 🔍 JSON Output Examples

### discovery_output.json (Sample)
```json
{
  "timestamp": "2024-01-15T10:30:45.123456Z",
  "hostname": "PROD-SERVER-01",
  "os_version": "Windows_NT 10.0.19042",
  "software_count": 142,
  "installed_software": [
    {
      "name": "Microsoft .NET Framework 4.8",
      "version": "4.8.3761.0",
      "publisher": "Microsoft Corporation",
      "install_location": "C:\\Program Files\\dotnet",
      "architecture": "x64"
    }
  ],
  "iis_sites": [
    {
      "name": "Default Web Site",
      "state": "Started",
      "physicalPath": "C:\\inetpub\\wwwroot",
      "appPool": "DefaultAppPool",
      "bindings": [
        {
          "protocol": "http",
          "bindingInformation": "*:80:"
        }
      ]
    }
  ]
}
```

### selection_results.json (Sample)
```json
{
  "timestamp": "2024-01-15 10:35:22",
  "hostname": "PROD-SERVER-01",
  "selected_software": [
    "Microsoft .NET Framework 4.8",
    "Node.js"
  ],
  "selected_iis_sites": [
    {
      "name": "Default Web Site",
      "physicalPath": "C:\\inetpub\\wwwroot",
      "appPool": "DefaultAppPool"
    }
  ]
}
```

---

## ⚠️ Common Issues & Solutions

### Issue: "ansible: command not found"
```bash
# Solution: Install Ansible
pip install ansible

# Or add to PATH if already installed
export PATH="$PATH:$HOME/.local/bin"
```

### Issue: "Win_ping failed - HTTP 401 Unauthorized"
```powershell
# Solution: Configure WinRM credentials
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\Auth\Negotiate -Value $true
```

### Issue: "PowerShell script cannot be loaded because..."
```powershell
# Solution: Change execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: "Connection refused" on port 5985
```powershell
# Solution: Configure firewall
New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "WinRM HTTP" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5985
```

---

## 💡 Pro Tips

1. **Test first**: Always test with `-i inventory.ini source_server -m win_command -a "whoami"`
2. **Use verbose**: Add `-v` or `-vv` for debugging: `ansible-playbook -vv run-complete-workflow.yml`
3. **Dry run**: Check syntax: `ansible-playbook --syntax-check run-complete-workflow.yml`
4. **Backup before**: Always backup IIS config and registry before deployment
5. **Monitor logs**: Watch `ansible_execution.log` in real-time: `tail -f ansible_execution.log`

---

## 📚 Next Steps

- Customize `vars/` directory for your environment
- Modify playbooks for your specific software/applications
- Integrate with CI/CD pipeline
- Add error handling and rollback logic
- Encrypt credentials with Ansible Vault

See [README.md](README.md) for full documentation.
