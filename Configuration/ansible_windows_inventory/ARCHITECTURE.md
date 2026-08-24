# 🏗️ Architecture & Implementation Summary

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        CONTROL MACHINE (Linux/Mac/Windows)              │
│                         (Where you run Ansible)                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────────────────────┐                                    │
│  │  Ansible Playbooks              │                                    │
│  ├─────────────────────────────────┤                                    │
│  │ ✓ run-complete-workflow.yml     │                                    │
│  │ ✓ discover-windows-state.yml    │                                    │
│  │ ✓ interactive-selection.yml     │                                    │
│  │ ✓ deploy-to-destination.yml     │                                    │
│  └─────────────────────────────────┘                                    │
│                      │                                                    │
│                      ▼                                                    │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  Ansible Collections & Python Modules                           │   │
│  │  - ansible.windows (win_* modules)                              │   │
│  │  - community.windows (additional Windows support)               │   │
│  │  - community.general (utilities)                                │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
                    │ WinRM (Port 5985/5986)
                    │ (HTTP or HTTPS)
                    │
                    ├─────────────────────────────────────┐
                    ▼                                      ▼
        ┌──────────────────────┐         ┌──────────────────────┐
        │   SOURCE SERVER      │         │ DESTINATION SERVER   │
        │   (Windows)          │         │   (Windows)          │
        │                      │         │                      │
        ├──────────────────────┤         ├──────────────────────┤
        │ PHASE 1:             │         │ PHASE 3:             │
        │ DISCOVERY            │         │ DEPLOYMENT           │
        │                      │         │                      │
        │ Registry Scan        │         │ Install Software     │
        │ ↓                    │         │ ↓                    │
        │ Software List        │         │ Create IIS Sites     │
        │ ↓                    │         │ ↓                    │
        │ IIS Scan             │         │ Configure Bindings   │
        │ ↓                    │         │ ↓                    │
        │ Sites & Pools        │         │ Deploy Files         │
        │ ↓                    │         │                      │
        │ File Inventory       │         │ ← ← ← ← ←           │
        │                      │         │ Selected Items       │
        └──────────────────────┘         └──────────────────────┘
```

---

## Data Flow Diagram

```
SOURCE SERVER                CONTROL MACHINE                   DESTINATION SERVER
    │                              │                                 │
    │  Phase 1: Discovery          │                                 │
    │◄─────────────────────────────┤                                 │
    │                              │                                 │
    ├─ Read Registry              │                                 │
    ├─ Query IIS Config           │                                 │
    ├─ Scan File System           │                                 │
    │                              │                                 │
    │  discovery_output.json       │                                 │
    ├─────────────────────────────►├──► (saved to local vars/)      │
    │                              │                                 │
    │                              │  Phase 2: Selection             │
    │                              │                                 │
    │                              │  ┌──────────────────────┐       │
    │                              │  │  PowerShell Menu UI  │       │
    │                              │  │  (Interactive)       │       │
    │                              │  │  ✓ Show Software     │       │
    │                              │  │  ✓ Show IIS Sites    │       │
    │                              │  │  ✓ Show App Paths    │       │
    │                              │  │  ✓ User Selects      │       │
    │                              │  └──────────────────────┘       │
    │                              │                                 │
    │                              │  selection_results.json         │
    │                              │  (saved to local vars/)         │
    │                              │                                 │
    │                              │  Phase 3: Deployment            │
    │                              ├────────────────────────────────►│
    │                              │                                 │
    │                              │  selection_results.json         │
    │                              ├────────────────────────────────►│
    │                              │                                 │
    │                              │  Read selections                │
    │                              │  ├─ Create IIS Sites           │
    │                              │  ├─ Configure App Pools        │
    │                              │  ├─ Setup Bindings             │
    │                              │  ├─ Deploy Files               │
    │                              │                                 │
    │                              │  deployment_log.json           │
    │                              │◄────────────────────────────────┤
    │                              │  (saved to local vars/)         │
    │                              │                                 │
```

---

## File Relationships & Dependencies

```
inventory.ini (Server Config)
     │
     ├──► ansible.cfg (Settings)
     │
     ├──► requirements.yml (Dependencies)
     │    │
     │    └──► ansible.windows, community.windows modules
     │
     ├──► run-complete-workflow.yml (Master)
     │    │
     │    ├──► discover-windows-state.yml
     │    │    └──► vars/discovery_output.json (generated)
     │    │
     │    ├──► interactive-selection.yml
     │    │    ├──► scripts/interactive-menu.ps1
     │    │    └──► vars/selection_results.json (generated)
     │    │
     │    └──► deploy-to-destination.yml
     │         └──► vars/deployment_log.json (generated)
     │
     └──► Individual playbooks (can run separately)
```

---

## Module & Function Mapping

```
DISCOVERY PHASE
├── ansible.windows.win_reg_stat
│   └── Reads Windows registry for software
├── ansible.windows.win_powershell
│   ├── Import-Module WebAdministration
│   ├── Get-ChildItem (IIS sites)
│   ├── Get-WebBinding (IIS bindings)
│   └── Get-WebApplication (IIS apps)
└── ansible.builtin.find
    └── Scans for application files

SELECTION PHASE
├── ansible.windows.win_powershell
│   └── scripts/interactive-menu.ps1
│       ├── Show-Menu() - Display items
│       ├── Get-MultiSelect() - Capture selections
│       └── Categorize-Software() - Organize items
└── JSON file I/O for persistence

DEPLOYMENT PHASE
├── ansible.windows.win_feature
│   └── Install IIS roles/features
├── ansible.windows.win_iis_webapppool
│   └── Create application pools
├── ansible.windows.win_iis_website
│   └── Create IIS websites
├── ansible.windows.win_iis_webbinding
│   └── Configure HTTP/HTTPS bindings
└── ansible.windows.win_file
    └── Create directories for apps
```

---

## Configuration & Customization Points

```
ansible_windows_inventory/
│
├── 🔧 MODIFY SERVERS
│   └── inventory.ini
│       ├── [source_server]
│       ├── [destination_server]
│       └── [windows:vars]
│
├── 🔧 MODIFY DISCOVERY
│   └── discover-windows-state.yml
│       ├── Registry paths (lines 25-30)
│       ├── IIS query depth (lines 50-80)
│       └── File search patterns (lines 100-120)
│
├── 🔧 MODIFY MENU
│   └── scripts/interactive-menu.ps1
│       ├── Menu appearance (colors, formatting)
│       ├── Item categorization
│       └── Selection validation
│
├── 🔧 MODIFY DEPLOYMENT
│   └── deploy-to-destination.yml
│       ├── IIS site creation (lines 60-100)
│       ├── App pool configuration (lines 110-130)
│       └── File deployment logic (lines 140-160)
│
└── 🔧 MODIFY SETTINGS
    └── ansible.cfg
        ├── Verbosity
        ├── Timeouts
        ├── Logging
        └── Callbacks
```

---

## Execution Flow with Timing

```
Phase 1: DISCOVERY (2-5 minutes)
├── Initialize playbook variables
├── Connect to source server (WinRM)
├── Scan 32-bit software registry (~30 seconds)
├── Scan 64-bit software registry (~30 seconds)
├── Extract software details (~30 seconds)
├── Query IIS configuration (~1 minute)
├── Scan application directories (~1-2 minutes)
├── Generate discovery report (~10 seconds)
└── Save vars/discovery_output.json

   ↓ User reviews discovery results ↓

Phase 2: INTERACTIVE SELECTION (2-10 minutes)
├── Load discovery data (instant)
├── Launch PowerShell interactive menu
├── Display software list
├── User selects software (user-dependent)
├── Display IIS sites list
├── User selects IIS sites (user-dependent)
├── Display application paths
├── User selects app paths (user-dependent)
├── Show selection summary
├── User confirms (yes/no)
└── Save vars/selection_results.json

   ↓ Automatic transition ↓

Phase 3: DEPLOYMENT (5-15 minutes)
├── Load selection results (instant)
├── Ensure IIS is installed (~1-2 minutes)
├── Create application pools (~1 minute)
├── Create IIS websites (~1 minute)
├── Configure bindings (~30 seconds)
├── Create destination directories (~30 seconds)
├── Deploy application files (variable)
├── Generate deployment report (~10 seconds)
└── Save vars/deployment_log.json

TOTAL TIME: 10-30+ minutes (depending on selections)
```

---

## Security Architecture

```
LAYER 1: Transport Security
├── WinRM over HTTPS (port 5986) - for production
├── WinRM over HTTP (port 5985) - for testing
└── TLS certificate management

LAYER 2: Authentication
├── Windows credentials (domain or local)
├── Basic auth (username/password)
├── Kerberos (domain environments)
└── Vault-encrypted credentials (Ansible Vault)

LAYER 3: Authorization
├── Windows NTFS permissions
├── IIS permissions
├── Registry permissions
└── Service account privileges

LAYER 4: Audit & Logging
├── Ansible execution logs
├── JSON audit trails
├── Windows Event logs
└── Deployment history in vars/
```

---

## Error Handling & Recovery

```
Discovery Phase Errors
├── If registry unreadable
│   └── Skip and continue with available data
├── If IIS not installed
│   └── Skip IIS discovery, continue with software
└── If file scan fails
    └── Log error, skip affected paths

Selection Phase Errors
├── If discovery data missing
│   └── Abort - inform user to run discovery
├── If user cancels menu
│   └── Exit gracefully
└── If invalid JSON
    └── Warn - check file format

Deployment Phase Errors
├── If selection data missing
│   └── Abort - inform user to run selection
├── If IIS installation fails
│   └── Log error and continue
├── If site creation fails
│   └── Log error, try next site
└── If file copy fails
    └── Log error, continue
```

---

## Scaling Considerations

### Single Source → Single Destination
```
Primary Use Case
✓ Most common scenario
✓ Simple linear workflow
```

### Multiple Sources → Single Destination
```
Collect from multiple sources
├── Run discovery on each source server
├── Merge results (manual or scripted)
├── Run single deployment
└── Result: Consolidated environment
```

### Multiple Sources → Multiple Destinations
```
Distributed deployment
├── Run discovery on each source
├── Create selections for each destination
├── Deploy to each destination in parallel
└── Result: Replicated environments
```

### Centralized Management
```
Hub-and-spoke architecture
├── Control machine as hub
├── Multiple source/destination servers
├── Parallel execution via serial settings
└── Centralized logging and reporting
```

---

## Integration Points

```
With External Systems
├── Email Notifications
│   └── Send deployment status to ops team
├── Slack/Teams Integration
│   └── Post deployment updates to channels
├── Database Logging
│   └── Store deployment history in database
├── CI/CD Pipeline
│   └── Trigger deployments from Jenkins/GitHub
├── ITSM Systems
│   └── Create/update tickets (ServiceNow, Jira)
├── Configuration Management Database
│   └── Update CMDB with deployed configurations
└── Monitoring Systems
    └── Alert on deployment failures
```

---

## Technology Stack

```
CONTROL MACHINE
├── Python 3.9+
├── Ansible 2.10+
├── Ansible Collections
│   ├── ansible.windows
│   ├── community.windows
│   └── community.general
└── Git (for version control)

SOURCE/DESTINATION SERVERS
├── Windows Server 2012 R2+
├── Windows 10/11
├── PowerShell 5.0+
├── WinRM (built-in)
├── IIS (if applicable)
└── .NET Framework (if applicable)

DATA FORMAT
└── JSON (human-readable, parseable)
```

---

## Performance Characteristics

```
Discovery Phase
├── Small infrastructure (1-50 software items):
│   └── ~2 minutes
├── Medium infrastructure (50-200 items):
│   └── ~3-4 minutes
├── Large infrastructure (200+ items):
│   └── ~5-10 minutes
└── Factors: Registry size, IIS complexity, file count

Selection Phase
├── With menu interactions:
│   └── 2-10 minutes (user-dependent)
└── Factors: Item count, user response time

Deployment Phase
├── Small deployment (1-5 items):
│   └── ~5 minutes
├── Medium deployment (5-15 items):
│   └── ~10-15 minutes
├── Large deployment (15+ items):
│   └── ~15-30+ minutes
└── Factors: Software complexity, file size, network
```

---

## Maintenance & Support

```
Regular Maintenance
├── Update Ansible collections
│   └── ansible-galaxy install -r requirements.yml --upgrade
├── Review and archive old logs
│   └── Maintain vars/ directory size
├── Update server inventory
│   └── Keep inventory.ini current
└── Validate playbook syntax
    └── ansible-playbook --syntax-check

Troubleshooting Support
├── Check logs: ansible_execution.log
├── Validate JSON: python -m json.tool vars/*.json
├── Test connectivity: ansible -m win_ping
├── Review event logs on Windows servers
└── Consult TROUBLESHOOTING.md

Backup & Recovery
├── Backup discovery output
├── Backup selection results
├── Backup deployment logs
├── Backup IIS configuration (before deployment)
└── Version control playbooks (git)
```

---

## Summary

This solution provides:

1. **Automated Discovery** - No manual inventory needed
2. **Interactive Selection** - User chooses what to deploy
3. **Safe Deployment** - Audit trail with JSON outputs
4. **Production-Ready** - Error handling and logging
5. **Scalable** - Works with single or multiple servers
6. **Extensible** - Easy to customize for your needs
7. **Well-Documented** - Comprehensive guides and examples

The three-phase approach separates concerns and allows for review/approval between phases, making it enterprise-ready.

---

**For implementation details, see:**
- QUICK_START.md - Fast start guide
- README.md - Complete documentation
- ADVANCED_CONFIG.md - Customization guide
- TROUBLESHOOTING.md - Problem solving
