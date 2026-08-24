# Sample Outputs - Infrastructure Dashboard Testing

This document shows realistic examples of what users will see when running the enhanced playbooks.

---

## SCENARIO 1: Interactive Menu - Software Selection

### Command:
```bash
ansible-playbook discover-windows-state.yml
ansible-playbook interactive-selection.yml
```

### Step 1: Initial Screen

```
=================================================================================
WINDOWS INFRASTRUCTURE SELECTION TOOL
=================================================================================

Hostname: PROD-SERVER-01
OS: Microsoft Windows Server 2019 Standard

Discovery Summary:
  - Installed Software: 47 items
  - IIS Installed: True
  - IIS Sites: 3 sites

Features:
  - Toggle selections with item number
  - Filter by keyword (f)
  - Select/Deselect all (a/n)
  - View selections (v)

Press Enter to start selection process
```

---

## SCENARIO 2: Interactive Menu - Software Selection Screen

### Display After Pressing Enter:

```
=================================================================================
SELECT INSTALLED SOFTWARE TO DEPLOY (Filter enabled - use 'f' to search by name/publisher)
Selected: 0 items | Total: 47 items
=================================================================================

[ ] 1. .NET Framework 4.8
      Publisher: Microsoft | Version: 4.8.3928.0

[ ] 2. Adobe Reader DC
      Publisher: Adobe Systems | Version: 21.011.20039

[ ] 3. Apache HTTP Server 2.4.48
      Publisher: Apache Software Foundation | Version: 2.4.48

[✓] 4. IIS URL Rewrite Module 2.1
      Publisher: Microsoft | Version: 2.1.2

[✓] 5. IIS Application Request Routing 3.2
      Publisher: Microsoft | Version: 3.2.1

[ ] 6. Git for Windows
      Publisher: Software Freedom Conservancy | Version: 2.34.1

[✓] 7. Java Runtime Environment 11
      Publisher: Oracle Corporation | Version: 11.0.13

[ ] 8. Microsoft Edge
      Publisher: Microsoft | Version: 96.0.1054.43

[✓] 9. Microsoft SQL Server Management Studio 18
      Publisher: Microsoft | Version: 18.12.1

[✓] 10. Node.js
      Publisher: Node.js Foundation | Version: 16.13.2

[ ] 11. Python 3.9.10
      Publisher: Python Software Foundation | Version: 3.9.10

[✓] 12. Visual Studio Code
      Publisher: Microsoft | Version: 1.63.2

COMMANDS:
  [#]       - Toggle selection of item number #
  [a]       - Select All items
  [n]       - Deselect All items
  [f]       - Filter by keyword
  [v]       - View current selections
  [0]       - Continue to next step
  [h]       - Show this help

Enter command: v
```

---

## SCENARIO 3: View Current Selections

```
CURRENT SELECTIONS (6 items):
=================================
  ✓ IIS URL Rewrite Module 2.1
  ✓ IIS Application Request Routing 3.2
  ✓ Java Runtime Environment 11
  ✓ Microsoft SQL Server Management Studio 18
  ✓ Node.js
  ✓ Visual Studio Code

Press Enter to continue
```

---

## SCENARIO 4: Filter by Keyword

```
Enter command: f
Enter filter keyword: Microsoft

Found 12 matching items

=================================================================================
SELECT INSTALLED SOFTWARE TO DEPLOY (Filter enabled - use 'f' to search by name/publisher)
Selected: 3 items | Total: 12 items
=================================================================================

[✓] 1. IIS URL Rewrite Module 2.1
      Publisher: Microsoft | Version: 2.1.2

[✓] 2. IIS Application Request Routing 3.2
      Publisher: Microsoft | Version: 3.2.1

[ ] 3. Microsoft Edge
      Publisher: Microsoft | Version: 96.0.1054.43

[✓] 4. Microsoft SQL Server Management Studio 18
      Publisher: Microsoft | Version: 18.12.1

[ ] 5. Microsoft Office 365
      Publisher: Microsoft | Version: 2112

COMMANDS:
  [#]       - Toggle selection of item number #
  [a]       - Select All items
  [n]       - Deselect All items
  [f]       - Filter by keyword
  [v]       - View current selections
  [0]       - Continue to next step
  [h]       - Show this help

Enter command: 0
```

---

## SCENARIO 5: IIS Sites Selection

```
Step 2 of 3: SELECT IIS SITES

=================================================================================
SELECT IIS SITES TO DEPLOY
Selected: 2 items | Total: 3 items
=================================================================================

[✓] 1. Default Web Site
      AppPool: DefaultAppPool | Path: C:\inetpub\wwwroot

[ ] 2. Production API
      AppPool: ProductionAPI-Pool | Path: D:\Apps\API\v2

[✓] 3. Legacy App
      AppPool: LegacyPool | Path: E:\LegacyApps\WebApp1

COMMANDS:
  [#]       - Toggle selection of item number #
  [a]       - Select All items
  [n]       - Deselect All items
  [f]       - Filter by keyword
  [v]       - View current selections
  [0]       - Continue to next step
  [h]       - Show this help

Enter command: 0

Selected 2 IIS sites
```

---

## SCENARIO 6: Application Paths Selection

```
Step 3 of 3: SELECT APPLICATION PATHS

=================================================================================
SELECT APPLICATION PATHS TO DEPLOY
Selected: 1 items | Total: 3 items
=================================================================================

[✓] 1. Default Web Site ➜ C:\inetpub\wwwroot
[✓] 2. Production API ➜ D:\Apps\API\v2
[ ] 3. Legacy App ➜ E:\LegacyApps\WebApp1

COMMANDS:
  [#]       - Toggle selection of item number #
  [a]       - Select All items
  [n]       - Deselect All items
  [f]       - Filter by keyword
  [v]       - View current selections
  [0]       - Continue to next step
  [h]       - Show this help

Enter command: 0

Selected 1 application paths
```

---

## SCENARIO 7: Selection Summary & Confirmation

```
=================================================================================
SELECTION SUMMARY & CONFIRMATION
=================================================================================

SELECTED ITEMS: 9

Software: 6 items
  ✓ IIS URL Rewrite Module 2.1
      Publisher: Microsoft
  ✓ IIS Application Request Routing 3.2
      Publisher: Microsoft
  ✓ Java Runtime Environment 11
      Publisher: Oracle Corporation
  ✓ Microsoft SQL Server Management Studio 18
      Publisher: Microsoft
  ✓ Node.js
      Publisher: Node.js Foundation
  ✓ Visual Studio Code
      Publisher: Microsoft

IIS Sites: 2 sites
  ✓ Default Web Site (Pool: DefaultAppPool, Path: C:\inetpub\wwwroot)
  ✓ Legacy App (Pool: LegacyPool, Path: E:\LegacyApps\WebApp1)

Application Paths: 1 paths
  ✓ Default Web Site ➜ C:\inetpub\wwwroot

=================================================================================

Confirm selections? (Y/N): Y

✓ Selection results saved to: /vars/selection_results.json
✓ Ready for deployment!

Next steps:
  1. Run: ansible-playbook deploy-to-destination.yml
  2. Or use dry-run: ansible-playbook deploy-to-destination.yml -e dryrun=true
```

---

## SCENARIO 8: Deployment - Dry-Run Mode

### Command:
```bash
ansible-playbook deploy-to-destination.yml -e dryrun=true
```

### Output:

```
=================================================================================
DEPLOYMENT MODE
=================================================================================
Dry-Run: True
NOTE: This is a DRY-RUN. No actual changes will be made.
=================================================================================

=================================================================================
DEPLOYMENT PLAN
=================================================================================
Destination: DEST-SERVER-02
Timestamp: 2026-07-24T14:32:45.123456+00:00

Items to deploy:
  - Software: 6 items
  - IIS Sites: 2 sites
  - Application Files: 1 paths

Total items: 9

Software to deploy:
  - IIS URL Rewrite Module 2.1 (Publisher: Microsoft)
  - IIS Application Request Routing 3.2 (Publisher: Microsoft)
  - Java Runtime Environment 11 (Publisher: Oracle Corporation)
  - Microsoft SQL Server Management Studio 18 (Publisher: Microsoft)
  - Node.js (Publisher: Node.js Foundation)
  - Visual Studio Code (Publisher: Microsoft)

IIS Sites to deploy:
  - Default Web Site (AppPool: DefaultAppPool, Path: C:\inetpub\wwwroot)
  - Legacy App (AppPool: LegacyPool, Path: E:\LegacyApps\WebApp1)

Application Paths to deploy:
  - Default Web Site ➜ C:\inetpub\wwwroot
  - Legacy App ➜ E:\LegacyApps\WebApp1

=================================================================================

TASK [Validate destination connectivity] ************************************
ok: [destination_server]

TASK [Check destination disk space] *******************************************
C: - Free: 250.5GB / Total: 500GB
D: - Free: 420.3GB / Total: 1000GB
E: - Free: 85.2GB / Total: 500GB

TASK [Display Deployment Plan] ************************************************
ok: [destination_server] =>
msg: (shown above)

TASK [Validate IIS sites] *****************************************************
ok: [destination_server] => (item=Default Web Site) =>
  msg: '[VALIDATION] IIS site: Default Web Site (AppPool: DefaultAppPool, Path: C:\inetpub\wwwroot)'

ok: [destination_server] => (item=Legacy App) =>
  msg: '[VALIDATION] IIS site: Legacy App (AppPool: LegacyPool, Path: E:\LegacyApps\WebApp1)'

TASK [Create IIS sites (dry-run)] *********************************************
ok: [destination_server] => (item=Default Web Site) =>
  msg: '[DRY-RUN] Would create IIS site: Default Web Site'

ok: [destination_server] => (item=Legacy App) =>
  msg: '[DRY-RUN] Would create IIS site: Legacy App'

TASK [Validate application pool configuration (dry-run)] **********************
ok: [destination_server] => (item=Default Web Site) =>
  msg: '[DRY-RUN] Would create app pool: DefaultAppPool'

ok: [destination_server] => (item=Legacy App) =>
  msg: '[DRY-RUN] Would create app pool: LegacyPool'

TASK [Validate IIS website configuration (dry-run)] ***************************
ok: [destination_server] => (item=Default Web Site) =>
  msg: '[DRY-RUN] Would create website: Default Web Site at C:\inetpub\wwwroot'

ok: [destination_server] => (item=Legacy App) =>
  msg: '[DRY-RUN] Would create website: Legacy App at E:\LegacyApps\WebApp1'

TASK [Validate application paths (dry-run)] **********************************
ok: [destination_server] => (item={'site_name': 'Default Web Site', 'physical_path': 'C:\\inetpub\\wwwroot'}) =>
  msg: '[VALIDATION] Application path: Default Web Site ➜ C:\inetpub\wwwroot'

ok: [destination_server] => (item={'site_name': 'Legacy App', 'physical_path': 'E:\LegacyApps\WebApp1'}) =>
  msg: '[VALIDATION] Application path: Legacy App ➜ E:\LegacyApps\WebApp1'

TASK [Create destination directories (dry-run)] ******************************
ok: [destination_server] => (item={'site_name': 'Default Web Site', 'physical_path': 'C:\\inetpub\\wwwroot'}) =>
  msg: '[DRY-RUN] Would create directory: C:\inetpub\wwwroot'

ok: [destination_server] => (item={'site_name': 'Legacy App', 'physical_path': 'E:\LegacyApps\WebApp1'}) =>
  msg: '[DRY-RUN] Would create directory: E:\LegacyApps\WebApp1'

TASK [Display deployment summary] *********************************************
ok: [destination_server] =>
msg: |-

  ============================================================
  DEPLOYMENT DRY-RUN COMPLETED
  ============================================================
  Destination: DEST-SERVER-02
  Start Time: 2026-07-24T14:32:45.123456+00:00
  End Time: 2026-07-24T14:32:52.654321+00:00
  Mode: DRY-RUN (No changes applied)
  Status: completed

  Deployed Items:
    - Software: 6
    - IIS Sites: 2
    - Application Paths: 1
    - TOTAL: 9

  Deployment log saved to: /vars/deployment_log.json

  ============================================================

PLAY RECAP ********************************************************************
destination_server         : ok=12   changed=0   unreachable=0   failed=0   skipped=0   warned=0

=================================================================================
NEXT STEPS
=================================================================================

Dry-run completed successfully. Review the output above.

To apply the deployment:
  ansible-playbook deploy-to-destination.yml

=================================================================================
```

---

## SCENARIO 9: Deployment - Production Mode

### Command:
```bash
ansible-playbook deploy-to-destination.yml
```

### Confirmation Prompt:

```
⚠ IMPORTANT: Review the deployment plan above.

This will deploy 9 items to DEST-SERVER-02.
Changes will be APPLIED to the destination server.

Press ENTER to continue or Ctrl+C to cancel
```

### Output After Confirmation:

```
PLAY [Deploy Selected Infrastructure to Destination] **************************

TASK [Display Deployment Mode] ************************************************
ok: [destination_server] =>
msg: |-
  ============================================================
  DEPLOYMENT MODE
  ============================================================
  Dry-Run: False
  ============================================================

TASK [Verify selection results exist] ******************************************
ok: [destination_server]

TASK [Load selection results] **************************************************
ok: [destination_server]

TASK [Validate selection results structure] ************************************
ok: [destination_server]

TASK [Validate destination connectivity] **************************************
ok: [destination_server]

TASK [Check destination disk space] ********************************************
C: - Free: 250.5GB / Total: 500GB
D: - Free: 420.3GB / Total: 1000GB
E: - Free: 85.2GB / Total: 500GB

TASK [Ensure IIS is installed] *************************************************
changed: [destination_server]

TASK [Create application pools (production)] **********************************
changed: [destination_server] => (item=Default Web Site)
  msg: 'Application pool DefaultAppPool created successfully'

changed: [destination_server] => (item=Legacy App)
  msg: 'Application pool LegacyPool created successfully'

TASK [Create IIS websites (production)] ****************************************
changed: [destination_server] => (item=Default Web Site)
  msg: 'IIS website Default Web Site created successfully at C:\inetpub\wwwroot'

changed: [destination_server] => (item=Legacy App)
  msg: 'IIS website Legacy App created successfully at E:\LegacyApps\WebApp1'

TASK [Configure IIS bindings (production)] *************************************
changed: [destination_server] => (item=Default Web Site)
  msg: 'Binding created: port 80, protocol http'

changed: [destination_server] => (item=Legacy App)
  msg: 'Binding created: port 80, protocol http'

TASK [Create destination directories (production)] ****************************
changed: [destination_server] => (item={'site_name': 'Default Web Site', 'physical_path': 'C:\\inetpub\\wwwroot'})
  msg: 'Directory created: C:\inetpub\wwwroot'

changed: [destination_server] => (item={'site_name': 'Legacy App', 'physical_path': 'E:\LegacyApps\WebApp1'})
  msg: 'Directory created: E:\LegacyApps\WebApp1'

TASK [Create final deployment report] ******************************************
ok: [destination_server]

TASK [Save deployment log] *****************************************************
changed: [destination_server]

TASK [Display deployment summary] **********************************************
ok: [destination_server] =>
msg: |-

  ============================================================
  DEPLOYMENT COMPLETED
  ============================================================
  Destination: DEST-SERVER-02
  Start Time: 2026-07-24T14:35:10.123456+00:00
  End Time: 2026-07-24T14:35:28.654321+00:00
  Mode: PRODUCTION (Changes applied)
  Status: completed

  Deployed Items:
    - Software: 6
    - IIS Sites: 2
    - Application Paths: 1
    - TOTAL: 9

  Deployment log saved to: /vars/deployment_log.json

  ============================================================

PLAY RECAP ********************************************************************
destination_server         : ok=14   changed=7   unreachable=0   failed=0   skipped=0   warned=0

=================================================================================
NEXT STEPS
=================================================================================

Deployment completed. Check deployment_log.json for details.

To verify deployed items:
  ansible-playbook discover-windows-state.yml

=================================================================================
```

---

## SCENARIO 10: Deployment Log (JSON Output)

### File: `vars/deployment_log.json`

```json
{
  "start_time": "2026-07-24T14:35:10.123456+00:00",
  "destination_host": "DEST-SERVER-02",
  "dry_run": false,
  "software_deployments": [],
  "iis_deployments": [
    {
      "site_name": "Default Web Site",
      "app_pool": "DefaultAppPool",
      "physical_path": "C:\\inetpub\\wwwroot",
      "status": "success",
      "timestamp": "2026-07-24T14:35:15.000000+00:00"
    },
    {
      "site_name": "Legacy App",
      "app_pool": "LegacyPool",
      "physical_path": "E:\\LegacyApps\\WebApp1",
      "status": "success",
      "timestamp": "2026-07-24T14:35:20.000000+00:00"
    }
  ],
  "file_deployments": [
    {
      "site_name": "Default Web Site",
      "physical_path": "C:\\inetpub\\wwwroot",
      "files_count": 150,
      "status": "success",
      "timestamp": "2026-07-24T14:35:25.000000+00:00"
    },
    {
      "site_name": "Legacy App",
      "physical_path": "E:\\LegacyApps\\WebApp1",
      "files_count": 320,
      "status": "success",
      "timestamp": "2026-07-24T14:35:28.000000+00:00"
    }
  ],
  "errors": [],
  "skipped": [],
  "end_time": "2026-07-24T14:35:28.654321+00:00",
  "status": "completed",
  "software_count": 6,
  "iis_sites_count": 2,
  "app_paths_count": 1,
  "total_items": 9
}
```

---

## SCENARIO 11: Error Handling - Selection File Not Found

### Command:
```bash
ansible-playbook deploy-to-destination.yml
```

### Output (without running selection first):

```
PLAY [Deploy Selected Infrastructure to Destination] **************************

TASK [Display Deployment Mode] ************************************************
ok: [destination_server]

TASK [Verify selection results exist] ******************************************
fatal: [destination_server]: FAILED! => {
    "msg": "Selection results not found at /vars/selection_results.json\n\nPlease run the selection process first:\n  1. ansible-playbook discover-windows-state.yml\n  2. ansible-playbook interactive-selection.yml"
}

PLAY RECAP ********************************************************************
destination_server         : ok=1    changed=0   unreachable=0   failed=1   skipped=0   warned=0

Aborting on control failure due to a failed requirement check
```

---

## SCENARIO 12: Error Handling - Destination Unreachable

### Output (if destination server is offline):

```
TASK [Validate destination connectivity] **************************************
fatal: [destination_server]: FAILED! => {
    "ping": "ping",
    "msg": "Cannot reach destination server DEST-SERVER-02"
}

PLAY RECAP ********************************************************************
destination_server         : ok=8    changed=0   unreachable=0   failed=1   skipped=0   warned=0

Aborting on control failure due to a failed assertion
```

---

## Key Features Demonstrated:

✅ **Interactive Menu Features:**
- Toggle selections with numbers
- Filter by keyword
- Select All / Deselect All
- View current selections
- Color-coded display

✅ **Validation:**
- Selection structure validation
- Destination connectivity checks
- Disk space verification
- Clear error messages

✅ **Dry-Run Mode:**
- Shows what would be deployed
- No actual changes made
- Perfect for testing

✅ **Production Deployment:**
- Confirmation prompt
- Actual changes applied
- Comprehensive logging
- Success/failure tracking

✅ **Error Handling:**
- Missing selection files
- Unreachable servers
- Invalid configurations
- Clear remediation steps
