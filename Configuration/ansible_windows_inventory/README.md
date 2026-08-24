# Windows Infrastructure Discovery & Deployment with Ansible

Automated discovery and deployment of Windows software, IIS sites, and applications using Ansible with interactive selection.

---

## 📋 Overview

This solution provides three-step workflow:

1. **Discovery** - Scan source server for installed software, IIS configuration, and application files
2. **Interactive Selection** - Choose which items to deploy via PowerShell menu
3. **Deployment** - Deploy selected items to destination server

---

## 📁 Project Structure

```
ansible_windows_inventory/
├── discover-windows-state.yml       # Phase 1: Discovery playbook
├── interactive-selection.yml        # Phase 2: Interactive menu launcher
├── deploy-to-destination.yml        # Phase 3: Deployment playbook
├── inventory.ini                    # Server inventory and connection settings
├── ansible.cfg                      # Ansible configuration
├── requirements.yml                 # Ansible collection dependencies
├── scripts/
│   └── interactive-menu.ps1         # PowerShell interactive selection UI
├── vars/
│   ├── discovery_output.json        # Generated discovery data
│   ├── selection_results.json       # Generated selection results
│   └── deployment_log.json          # Generated deployment log
└── README.md                        # This file
```

---

## 🚀 Quick Start

### Step 1: Prerequisites

**On Control Machine (Where you run Ansible):**
```bash
# Install Ansible
pip install ansible>=2.10

# Install required collections
ansible-galaxy install -r requirements.yml

# Verify installation
ansible --version
```

**On Windows Servers (Source & Destination):**
- Windows PowerShell 5.0+
- WinRM enabled and configured
- Network connectivity between control machine and Windows servers

---

### Step 2: Configure Inventory

Edit `inventory.ini` and replace hostnames/IPs:

```ini
[source_server]
source_server ansible_host=YOUR_SOURCE_IP ansible_user=Administrator

[destination_server]
destination_server ansible_host=YOUR_DESTINATION_IP ansible_user=Administrator
```

### Step 3: Enable WinRM on Windows Servers

Run as **Administrator** on each Windows server:

```powershell
# Enable WinRM
Enable-PSRemoting -Force

# Configure WinRM for Ansible (HTTP)
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*"

# Or for specific IPs
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.1.100"
```

### Step 4: Test Connectivity

```bash
ansible -i inventory.ini source_server -m win_ping
ansible -i inventory.ini destination_server -m win_ping
```

---

## 🔄 Execution Workflow

### Run Complete Workflow (Recommended)

```bash
# Run master playbook that chains all three steps
ansible-playbook discover-windows-state.yml
ansible-playbook interactive-selection.yml
ansible-playbook deploy-to-destination.yml
```

### Or Run Individual Steps

```bash
# Step 1: Discover
ansible-playbook discover-windows-state.yml

# Step 2: Select (PowerShell UI will launch)
ansible-playbook interactive-selection.yml

# Step 3: Deploy
ansible-playbook deploy-to-destination.yml
```

---

## 📊 What Gets Discovered

### Software Inventory
- Software name, version, publisher
- Installation location
- Architecture (x86 vs x64)
- Uninstall string

### IIS Configuration
- Site names and states
- Physical paths
- Application pools
- Bindings (protocols, ports, hostnames)
- Applications and their virtual paths

### Application Files
- File listings per site
- Directory structure
- File counts

---

## 🎯 Interactive Selection Menu

The PowerShell menu (`scripts/interactive-menu.ps1`) provides:

- **Checkbox-style selection** for discovered items
- **Multi-item selection** (comma-separated numbers)
- **Real-time confirmation** before deployment
- **JSON output** for downstream processing

Example menu flow:
```
[1] Microsoft Visual C++ 2019
[2] .NET Framework 4.8
[3] Node.js
...
Select items (comma-separated numbers): 1,3
```

---

## 📝 Output Files

Generated automatically in `vars/` directory:

- **discovery_output.json** - Complete discovery results
- **selection_results.json** - User selections from menu
- **deployment_log.json** - Deployment execution log

---

## 🔧 Configuration Options

### Modify Discovery Behavior

Edit `discover-windows-state.yml`:
- Change registry paths for software discovery
- Adjust IIS query depth
- Modify file search patterns/limits

### Customize Deployment Logic

Edit `deploy-to-destination.yml`:
- Add custom software installation handlers
- Modify IIS site creation parameters
- Configure application file handling

### Adjust Menu Display

Edit `scripts/interactive-menu.ps1`:
- Change menu colors/formatting
- Modify selection limits
- Add validation rules

---

## 🐛 Troubleshooting

### "Win_ping failed"
```bash
# Check WinRM service on Windows
Get-Service WinRM
Start-Service WinRM

# Check firewall
New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "Windows Remote Management (HTTP-In)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5985
```

### "PowerShell script not found"
- Ensure scripts directory path is correct
- Check file permissions: `Get-Item -Force scripts/interactive-menu.ps1`

### "JSON parsing errors"
- Validate JSON files: `Test-Json (Get-Content vars/discovery_output.json)`
- Check for special characters in names

### "IIS not installed"
- Playbook will skip IIS-related tasks
- To install IIS: `Add-WindowsFeature -Name Web-Server -IncludeAllSubFeature`

---

## 🔐 Security Considerations

1. **Credentials:**
   - Never hardcode passwords in playbooks
   - Use Ansible vault: `ansible-vault edit inventory.ini`
   - Use Windows authentication when possible

2. **Network:**
   - Use HTTPS (port 5986) in production
   - Configure firewall rules appropriately
   - Restrict TrustedHosts to specific IPs

3. **File Permissions:**
   - Ensure proper ACLs on application directories
   - Backup before deployment
   - Test in non-production first

---

## 📚 Examples

### Deploy only software (skip IIS)
```powershell
# In menu, select 0 when prompted for IIS sites
```

### Deploy only IIS sites
```powershell
# In menu, select 0 when prompted for software
```

### Schedule automatic deployment
```bash
# Use cron (Linux) or Task Scheduler (Windows)
# Run discovery daily, manual selection, or schedule complete workflow
```

---

## 🤝 Extending the Solution

### Add Custom Discovery
Edit `discover-windows-state.yml` to add:
- Database server instances
- Network shares
- Certificate information
- Custom application registries

### Add Custom Deployment Logic
Edit `deploy-to-destination.yml` to:
- Install packages from repository
- Configure security policies
- Set up monitoring/logging
- Create user accounts

### Integrate with External Systems
- Store results in database
- Post to web service
- Create tickets in ITSM system
- Update CMDB

---

## 📖 Documentation

### Ansible Windows Collections
- https://docs.ansible.com/ansible/latest/collections/ansible/windows/

### Win_powershell Module
- https://docs.ansible.com/ansible/latest/collections/ansible/windows/win_powershell_module.html

### IIS Management Modules
- win_iis_website
- win_iis_webapppool
- win_iis_webbinding

---

## 📝 License

Internal Use Only

---

## 💡 Tips & Best Practices

1. **Always test in lab first** - Never run discovery/deploy in production without testing
2. **Keep backups** - Backup IIS configuration before deployment
3. **Monitor execution** - Check logs in `ansible_execution.log`
4. **Validate selections** - Review JSON files before deployment proceeds
5. **Use ansible-vault** - Protect sensitive credentials
6. **Run with verbose** - Use `-v` or `-vv` for debugging

---

## 🆘 Support

For issues, check:
1. WinRM connectivity: `winrs -r:hostname hostname`
2. PowerShell execution policy: `Get-ExecutionPolicy`
3. Ansible debug output: `ansible-playbook -vvv`
4. JSON syntax: Online JSON validators
