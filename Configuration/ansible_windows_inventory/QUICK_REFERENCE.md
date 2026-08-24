# Quick Reference Guide

## Complete Workflow

### Step 1: Discover Infrastructure
```bash
ansible-playbook discover-windows-state.yml
```
**What it does:** Scans source server and discovers all software, IIS sites, and application files.

**Output:** Creates `vars/discovery_output.json` with all discovered items.

---

### Step 2: Interactive Selection
```bash
ansible-playbook interactive-selection.yml
```
**What it does:** Launches interactive menu to select items you want to deploy.

**Menu Commands:**
- `[1]` `[2]` etc → Toggle selection of item number
- `[a]` → Select ALL items
- `[n]` → Deselect ALL items
- `[f]` → Filter by keyword (name/publisher)
- `[v]` → View current selections
- `[h]` → Show help
- `[0]` → Continue to next step

**Output:** Creates `vars/selection_results.json` with your selections.

---

### Step 3a: Preview Deployment (DRY-RUN - Safe)
```bash
ansible-playbook deploy-to-destination.yml -e dryrun=true
```
**What it does:** Shows what WOULD be deployed without making any changes.

**Benefits:**
- ✓ Safe to test multiple times
- ✓ Validates configuration
- ✓ Shows all operations that will run
- ✓ No actual changes to destination server

---

### Step 3b: Deploy to Destination (Production)
```bash
ansible-playbook deploy-to-destination.yml
```
**What it does:** Actually deploys the selected items to destination server.

**Safety Features:**
- ✓ Validates selection results first
- ✓ Checks destination connectivity
- ✓ Verifies disk space
- ✓ Shows deployment plan
- ✓ Requires your confirmation before deploying

**Output:** Creates `vars/deployment_log.json` with deployment results.

---

## Common Scenarios

### Scenario 1: Select Specific Microsoft Software
```bash
# After launch: ansible-playbook interactive-selection.yml
# In menu → Press 'f' → Type 'Microsoft' → Select items → Press '0'
```

### Scenario 2: Select Only IIS Sites (Skip Software)
```bash
# In menu Step 1 → Press 'n' (none)
# In menu Step 2 → Select specific IIS sites
# In menu Step 3 → Select application paths
```

### Scenario 3: Test Before Deploying
```bash
# First, test everything:
ansible-playbook deploy-to-destination.yml -e dryrun=true

# If output looks good, deploy:
ansible-playbook deploy-to-destination.yml
```

### Scenario 4: Select All Items
```bash
# In each menu step, press 'a' to select all
```

---

## File Locations

```
ansible_windows_inventory/
├── vars/
│   ├── discovery_output.json      ← Output from discover step
│   ├── selection_results.json     ← Output from selection step
│   └── deployment_log.json        ← Output from deployment step
├── scripts/
│   └── interactive-menu.ps1       ← PowerShell menu script
├── deploy-to-destination.yml      ← Deployment playbook
├── discover-windows-state.yml     ← Discovery playbook
└── interactive-selection.yml      ← Selection launcher
```

---

## Display Examples

### Interactive Menu (Software Selection)
```
=================================================================================
SELECT INSTALLED SOFTWARE TO DEPLOY
Selected: 2 items | Total: 47 items
=================================================================================

[ ] 1. .NET Framework 4.8
[✓] 2. Node.js
[ ] 3. Python 3.9
[✓] 4. Visual Studio Code

Enter command:
```

### Deployment Plan Display
```
============================================================
DEPLOYMENT PLAN
============================================================
Destination: DEST-SERVER-02
Items to deploy:
  - Software: 6 items
  - IIS Sites: 2 sites
  - Application Files: 1 paths
============================================================
```

---

## Troubleshooting

### Error: "Selection results not found"
```
→ Run discovery first: ansible-playbook discover-windows-state.yml
→ Then run selection: ansible-playbook interactive-selection.yml
```

### Error: "Cannot reach destination server"
```
→ Check if destination server is online
→ Verify network connectivity
→ Check firewall rules
→ Verify WinRM is enabled on destination
```

### Error: "Insufficient disk space"
```
→ Check available space on destination (shown in console)
→ Free up space or select fewer items
→ Choose items that require less disk space
```

### Nothing was selected
```
→ You'll get a confirmation warning
→ Go back and select items (press 'a' to select all)
→ Use filter 'f' to find specific items
```

---

## Tips & Tricks

1. **Use Filter for Large Lists**
   - Press 'f' then type 'Microsoft' to find Microsoft products
   - Type 'IIS' to find IIS-related software

2. **View Selections Anytime**
   - Press 'v' to see current selections
   - Helps verify before moving to next step

3. **Test with Dry-Run First**
   - Always use dry-run before production deployment
   - It's safe to run multiple times
   - Helps catch configuration issues

4. **Check Deployment Log After**
   - Review `deployment_log.json` for details
   - Useful for troubleshooting or auditing

5. **Filter by Publisher**
   - Most items show publisher info
   - Press 'f' and search by company name
   - Example: 'Adobe', 'Microsoft', 'Oracle'

---

## Expected Time

- **Discovery:** 1-3 minutes (depends on server complexity)
- **Selection:** 2-5 minutes (interactive)
- **Dry-Run:** 30-60 seconds (validation only)
- **Deployment:** 2-10 minutes (depends on items deployed)

---

## Success Indicators

✅ **Discovery Complete When You See:**
```
PLAY RECAP
source_server         : ok=X   changed=0   unreachable=0   failed=0
```

✅ **Selection Complete When You See:**
```
✓ Selection results saved to: /vars/selection_results.json
✓ Ready for deployment!
```

✅ **Dry-Run Complete When You See:**
```
DEPLOYMENT DRY-RUN COMPLETED
Status: completed
```

✅ **Deployment Complete When You See:**
```
DEPLOYMENT COMPLETED
Mode: PRODUCTION (Changes applied)
Status: completed
```

---

## Next Steps

1. ✓ Verify discovery works: `ansible-playbook discover-windows-state.yml`
2. ✓ Test selection menu: `ansible-playbook interactive-selection.yml`
3. ✓ Preview deployment: `ansible-playbook deploy-to-destination.yml -e dryrun=true`
4. ✓ Deploy to production: `ansible-playbook deploy-to-destination.yml`
5. ✓ Verify deployment: `ansible-playbook discover-windows-state.yml`

For detailed sample outputs, see [SAMPLE_OUTPUTS.md](SAMPLE_OUTPUTS.md)
