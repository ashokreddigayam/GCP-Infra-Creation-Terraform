# 📖 Complete File Reference Guide

## Project Structure Overview

```
ansible_windows_inventory/
├── 📋 Core Playbooks
│   ├── run-complete-workflow.yml           # Master playbook (runs all 3 phases)
│   ├── discover-windows-state.yml          # Phase 1: Discovery
│   ├── interactive-selection.yml           # Phase 2: Interactive menu
│   └── deploy-to-destination.yml           # Phase 3: Deployment
│
├── 🔧 Configuration Files
│   ├── inventory.ini                       # Server definitions & WinRM settings
│   ├── ansible.cfg                         # Ansible configuration
│   └── requirements.yml                    # Ansible collection dependencies
│
├── 📁 Scripts & Tools
│   └── scripts/
│       └── interactive-menu.ps1            # PowerShell interactive selection UI
│
├── 📊 Generated Output (Auto-created)
│   └── vars/
│       ├── discovery_output.json           # Discovery results
│       ├── selection_results.json          # User selections
│       ├── deployment_log.json             # Deployment results
│       └── workflow_execution.log          # Execution log
│
├── 📚 Documentation
│   ├── README.md                           # Full project documentation
│   ├── QUICK_START.md                      # 5-minute quick start guide
│   ├── ADVANCED_CONFIG.md                  # Customization guide
│   ├── TROUBLESHOOTING.md                  # Common issues & fixes
│   └── FILE_REFERENCE.md                   # This file
│
├── 🚀 Setup Scripts
│   ├── setup.sh                            # Setup for Linux/Mac
│   └── setup.bat                           # Setup for Windows
│
└── 📜 License & Info
    └── LICENSE                             # License information
```

---

## 📋 Core Playbooks

### `run-complete-workflow.yml`
**Purpose:** Master orchestration playbook

**What it does:**
- Chains all three phases together
- Adds user confirmation pauses between phases
- Provides workflow summary
- Minimal modifications needed

**When to use:**
- First time setup
- Complete end-to-end execution
- Scheduled/automated deployments

**Key features:**
- Includes discovery, selection, and deployment
- Pauses for user confirmation
- Comprehensive logging
- Error handling

**Example run:**
```bash
ansible-playbook run-complete-workflow.yml
```

---

### `discover-windows-state.yml`
**Purpose:** Discover infrastructure from source server

**What it does:**
- Scans Windows registry for installed software
- Queries IIS configuration (sites, app pools, bindings)
- Finds application files in IIS physical paths
- Generates JSON discovery report

**When to use:**
- Running discovery only
- Testing discovery phase
- Updating infrastructure inventory

**Key sections:**
1. Software discovery (32-bit & 64-bit)
2. IIS configuration scanning
3. Application file inventory
4. Report generation

**Variables to customize:**
- Registry paths
- IIS query depth
- File search patterns
- Output file location

**Example run:**
```bash
ansible-playbook discover-windows-state.yml
```

**Output file:**
```json
vars/discovery_output.json
```

---

### `interactive-selection.yml`
**Purpose:** Launch interactive selection menu

**What it does:**
- Verifies discovery data exists
- Loads discovery results
- Launches PowerShell interactive menu
- Saves user selections

**When to use:**
- Manual selection phase
- After discovery completion
- When testing menu functionality

**Key steps:**
1. Load discovery data
2. Launch `interactive-menu.ps1`
3. Capture user selections
4. Validate and save results

**Variables:**
- discovery_data_file (input)
- selection_results_file (output)

**Example run:**
```bash
ansible-playbook interactive-selection.yml
```

**Output file:**
```json
vars/selection_results.json
```

---

### `deploy-to-destination.yml`
**Purpose:** Deploy selected items to destination server

**What it does:**
- Loads selection results
- Installs IIS (if selected)
- Creates IIS sites and app pools
- Configures bindings
- Deploys application files
- Generates deployment log

**When to use:**
- After selection complete
- Deploying to destination
- Testing deployment phase

**Key sections:**
1. Pre-validation (check selections exist)
2. Software deployment
3. IIS setup and configuration
4. File deployment
5. Deployment logging

**Variables to customize:**
- Software installation paths
- IIS configuration parameters
- File deployment logic
- Error handling

**Example run:**
```bash
ansible-playbook deploy-to-destination.yml
```

**Output file:**
```json
vars/deployment_log.json
```

---

## 🔧 Configuration Files

### `inventory.ini`
**Purpose:** Define Windows servers and connection settings

**Key sections:**
```ini
[source_server]          # Source server for discovery
[destination_server]    # Target server for deployment
[windows:vars]          # Common Windows connection vars
```

**What to configure:**
- Host IPs or hostnames
- Administrator usernames
- WinRM port (5985 for HTTP, 5986 for HTTPS)
- Authentication method

**Example:**
```ini
[source_server]
prod-server-01 ansible_host=192.168.1.100 ansible_user=Administrator

[destination_server]
prod-server-02 ansible_host=192.168.1.101 ansible_user=Administrator

[windows:vars]
ansible_connection=winrm
ansible_port=5985
ansible_winrm_transport=basic
```

---

### `ansible.cfg`
**Purpose:** Configure Ansible behavior and defaults

**Key settings:**
- Inventory file location
- Logging configuration
- Host key checking
- Verbosity level
- Module defaults
- Timeout values

**When to modify:**
- Change logging verbosity
- Adjust timeout values
- Modify host patterns
- Configure callback plugins

---

### `requirements.yml`
**Purpose:** Define Ansible collection dependencies

**Required collections:**
- `ansible.windows` - Core Windows modules
- `community.windows` - Additional Windows support
- `community.general` - General utilities

**Install:**
```bash
ansible-galaxy install -r requirements.yml
```

**When to modify:**
- Adding new community modules
- Updating collection versions
- Adding Python dependencies

---

## 📁 Scripts & Tools

### `scripts/interactive-menu.ps1`
**Purpose:** PowerShell-based interactive selection menu

**Functions:**
- Displays discovered items
- Captures multi-item selection
- Shows selection summary
- Saves results to JSON

**Features:**
- Menu-driven UI
- Category filtering
- Selection validation
- Confirmation before proceeding

**When to modify:**
- Add new categories
- Change menu appearance
- Add search functionality
- Customize validation

**Usage (automatic via playbook):**
```powershell
.\scripts\interactive-menu.ps1 `
    -DiscoveryDataFile "vars/discovery_output.json" `
    -SelectionOutputFile "vars/selection_results.json"
```

---

## 📊 Generated Output Files

### `vars/discovery_output.json`
**Generated by:** `discover-windows-state.yml`

**Contains:**
```json
{
  "timestamp": "ISO8601 timestamp",
  "hostname": "source server name",
  "os_version": "Windows version",
  "software_count": 142,
  "installed_software": [
    {
      "name": "software name",
      "version": "version",
      "publisher": "publisher",
      "install_location": "path",
      "architecture": "x86|x64"
    }
  ],
  "iis_sites_count": 5,
  "iis_sites": [
    {
      "name": "site name",
      "state": "Started|Stopped",
      "physicalPath": "C:\\path",
      "appPool": "AppPoolName",
      "bindings": []
    }
  ],
  "application_files": []
}
```

**Usage:**
- Input for `interactive-selection.yml`
- Reference for manual deployments
- Archive for auditing

---

### `vars/selection_results.json`
**Generated by:** `interactive-selection.yml`

**Contains:**
```json
{
  "timestamp": "2024-01-15 10:35:22",
  "hostname": "source server",
  "selected_software": ["software1", "software2"],
  "selected_iis_sites": [
    {
      "name": "site name",
      "physicalPath": "path",
      "appPool": "pool name"
    }
  ],
  "selected_app_paths": [
    {
      "site_name": "site",
      "physical_path": "path"
    }
  ]
}
```

**Usage:**
- Input for `deploy-to-destination.yml`
- Audit trail of deployments
- Rollback reference

---

### `vars/deployment_log.json`
**Generated by:** `deploy-to-destination.yml`

**Contains:**
```json
{
  "start_time": "ISO8601 timestamp",
  "end_time": "ISO8601 timestamp",
  "destination_host": "destination hostname",
  "status": "completed|failed|partial",
  "software_count": 5,
  "iis_sites_count": 3,
  "app_paths_count": 2,
  "errors": []
}
```

**Usage:**
- Deployment status verification
- Audit log
- Rollback decision making

---

### `ansible_execution.log`
**Generated by:** Ansible playbook execution

**Contains:**
- Task execution details
- Error messages
- Warnings and debug info
- Timing information

**View live:**
```bash
tail -f ansible_execution.log
```

---

## 📚 Documentation Files

### `README.md`
**What:** Complete project documentation

**Sections:**
- Overview
- Project structure
- Prerequisites
- Configuration
- Execution workflow
- Output explanation
- Troubleshooting
- Extending solution
- Security considerations

**Who should read:** Everyone, especially first-time users

---

### `QUICK_START.md`
**What:** 5-minute quick start guide

**Sections:**
- Quick setup
- Server configuration
- WinRM setup
- Connectivity testing
- Workflow execution
- Phase descriptions
- Common issues
- Pro tips

**Who should read:** New users who want to get running fast

---

### `ADVANCED_CONFIG.md`
**What:** Customization and advanced features

**Sections:**
- Custom discovery logic
- Interactive menu customization
- Deployment customization
- Advanced features (emails, Slack, DB)
- Security enhancements
- Performance optimization
- Debugging techniques
- Multi-server scaling
- Report generation

**Who should read:** Advanced users customizing the solution

---

### `TROUBLESHOOTING.md`
**What:** Common issues and solutions

**Sections:**
- WinRM & connectivity issues
- PowerShell & discovery issues
- File & permission issues
- JSON & data issues
- Performance issues
- Deployment issues
- Logging & debugging
- Network & firewall
- Reset & recovery

**Who should read:** Anyone experiencing problems

---

### `FILE_REFERENCE.md`
**What:** This file - complete file guide

**Usage:**
- Quick navigation reference
- Understanding file purpose
- Finding what to modify
- Integration point mapping

---

## 🚀 Setup Scripts

### `setup.sh` (Linux/Mac)
**Purpose:** Automated setup on Linux/Mac control machines

**Does:**
1. Checks Python installation
2. Checks pip installation
3. Installs/upgrades Ansible
4. Installs required collections
5. Creates vars directory
6. Sets file permissions

**Usage:**
```bash
chmod +x setup.sh
./setup.sh
```

---

### `setup.bat` (Windows)
**Purpose:** Automated setup on Windows control machines

**Does:**
1. Checks Python installation
2. Checks pip installation
3. Installs/upgrades Ansible
4. Installs required collections
5. Creates vars directory

**Usage:**
```cmd
setup.bat
```

---

## 🔄 Typical Workflow

### Scenario: Deploy software to new server

1. **Prepare:**
   ```bash
   # Edit inventory.ini with server IPs
   # Enable WinRM on Windows servers
   # Run setup script
   ```

2. **Execute Discovery:**
   ```bash
   ansible-playbook discover-windows-state.yml
   # Check vars/discovery_output.json
   ```

3. **Select Items:**
   ```bash
   ansible-playbook interactive-selection.yml
   # Interactive menu will launch
   # Check vars/selection_results.json after
   ```

4. **Deploy:**
   ```bash
   ansible-playbook deploy-to-destination.yml
   # Check vars/deployment_log.json for status
   ```

---

## 📝 Quick Reference

### Running Playbooks

```bash
# Complete workflow
ansible-playbook run-complete-workflow.yml

# Discovery only
ansible-playbook discover-windows-state.yml

# Selection only (after discovery)
ansible-playbook interactive-selection.yml

# Deployment only (after selection)
ansible-playbook deploy-to-destination.yml

# Verbose output
ansible-playbook -vvv discover-windows-state.yml

# Dry run
ansible-playbook --syntax-check discover-windows-state.yml
```

### Testing

```bash
# Test connectivity
ansible -i inventory.ini source_server -m win_ping

# Get system facts
ansible -i inventory.ini source_server -m setup

# Run command
ansible -i inventory.ini source_server -m win_command -a "hostname"
```

### Troubleshooting

```bash
# Check WinRM on server
Test-WSMan

# View Ansible log
tail -f ansible_execution.log

# Validate JSON
python -m json.tool vars/discovery_output.json

# WinRM service
Get-Service WinRM | Restart-Service
```

---

## 🎯 File Modification Guide

### I want to...

| Goal | File to Modify | Section |
|------|---|---|
| Add/remove servers | `inventory.ini` | [source_server] or [destination_server] |
| Increase timeout | `ansible.cfg` | [defaults] timeout = |
| Change discovery scope | `discover-windows-state.yml` | Registry paths, IIS query |
| Customize menu | `scripts/interactive-menu.ps1` | Show-Menu function |
| Modify deployment | `deploy-to-destination.yml` | Task blocks |
| Add custom logic | New `roles/` files | Create reusable roles |
| Archive results | `vars/` | Reference JSON files |
| Debug issues | `TROUBLESHOOTING.md` | Search by symptom |
| Advanced features | `ADVANCED_CONFIG.md` | Reference examples |

---

## 📞 Support Resources

- **Ansible Docs:** https://docs.ansible.com/
- **Windows Collection:** https://docs.ansible.com/ansible/latest/collections/ansible/windows/
- **PowerShell Docs:** https://docs.microsoft.com/en-us/powershell/
- **WinRM Docs:** https://docs.microsoft.com/en-us/windows/win32/winrm/

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-01-15 | Initial release |

---

**Last Updated:** 2024-01-15
**Maintained By:** Infrastructure Team
