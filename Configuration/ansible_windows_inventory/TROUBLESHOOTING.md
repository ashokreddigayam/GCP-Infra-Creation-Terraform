# Troubleshooting Guide

## 🔍 Common Issues & Solutions

---

## WinRM & Connectivity Issues

### Issue: "Timeout waiting for privilege escalation prompt"

**Symptom:**
```
FATAL! failed to execute module, could not match supplied host pattern, got error:
WinRM Error: Timeout waiting for privilege escalation prompt
```

**Solutions:**

1. **Check WinRM is running:**
   ```powershell
   Get-Service WinRM | Select-Object Status
   Start-Service WinRM -Force
   ```

2. **Enable WinRM (as Administrator):**
   ```powershell
   Enable-PSRemoting -Force
   ```

3. **Configure AllowUnencrypted:**
   ```powershell
   Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true
   ```

4. **Add control machine to TrustedHosts:**
   ```powershell
   Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.1.50"
   # Or allow all (insecure)
   Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*"
   ```

---

### Issue: "HTTP Error 401: Access Denied"

**Symptom:**
```
HTTP Error 401: Access Denied
Failed to parse result from HTTP response
```

**Solutions:**

1. **Verify credentials are correct:**
   ```bash
   ansible -i inventory.ini source_server -u Administrator -k -m win_ping
   # When prompted, enter password
   ```

2. **Enable basic auth:**
   ```powershell
   Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
   ```

3. **For domain accounts, use UPN format:**
   ```ini
   # In inventory.ini
   ansible_user=domain\username
   # Or
   ansible_user=username@domain.com
   ```

---

### Issue: "Connection refused" on port 5985

**Symptom:**
```
Error: Cannot connect to remote host - Connection refused
Port: 5985
```

**Solutions:**

1. **Open firewall for WinRM:**
   ```powershell
   New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "Windows Remote Management (HTTP-In)" `
     -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5985
   ```

2. **For HTTPS (port 5986):**
   ```powershell
   New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "Windows Remote Management (HTTPS-In)" `
     -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5986
   ```

3. **Verify WinRM listener exists:**
   ```powershell
   Get-WSManInstance -ResourceURI winrm/config/listener -Enumerate
   ```

---

### Issue: "SSH_DISCONNECT_SERVICE_NOT_AVAILABLE"

**Symptom:**
```
fatal: [server]: UNREACHABLE! => {
    "changed": false,
    "msg": "SSH_DISCONNECT_SERVICE_NOT_AVAILABLE",
    "unreachable": true
}
```

**Solution:** You're trying to use SSH instead of WinRM. Change in `inventory.ini`:

```ini
[windows:vars]
ansible_connection=winrm
ansible_port=5985
```

---

## PowerShell & Discovery Issues

### Issue: "PowerShell script cannot be loaded"

**Symptom:**
```
Cannot be loaded because running scripts is disabled on this system
```

**Solution:**

1. **Change execution policy:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   # Or for all users
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
   ```

2. **Verify new policy:**
   ```powershell
   Get-ExecutionPolicy -List
   ```

---

### Issue: "Module not found: WebAdministration"

**Symptom:**
```
Import-Module: The specified module 'WebAdministration' was not loaded because no valid module file was found
```

**Solutions:**

1. **IIS not installed:**
   ```powershell
   # Install IIS (as Administrator)
   Add-WindowsFeature Web-Server -IncludeAllSubFeature
   ```

2. **On Server Core:**
   ```powershell
   Import-Module WebAdministration -ListAvailable
   Install-WindowsFeature Web-Server -IncludeManagementTools
   ```

---

### Issue: "Get-ChildItem IIS:\ fails"

**Symptom:**
```
Get-ChildItem: The system cannot find the path specified
```

**Solutions:**

1. **Verify IIS is running:**
   ```powershell
   Get-Service W3SVC
   Start-Service W3SVC -Force
   ```

2. **Reload IIS provider:**
   ```powershell
   Remove-Module WebAdministration -Force
   Import-Module WebAdministration -Force
   ```

---

## File & Permission Issues

### Issue: "Access to the path is denied"

**Symptom:**
```
An error occurred while retrieving attributes for file
Access to the path is denied
```

**Solutions:**

1. **Run Ansible with elevated privileges:**
   In `inventory.ini`:
   ```ini
   ansible_become=yes
   ansible_become_method=runas
   ```

2. **Add read permissions for discovery:**
   ```powershell
   # As Administrator
   icacls "C:\inetpub\wwwroot" /grant:r "EVERYONE:(OI)(CI)RX"
   ```

3. **Use service account with elevated privileges:**
   ```ini
   ansible_user=domain\service_account
   ansible_password={{ vault_password }}
   ansible_become=yes
   ```

---

### Issue: "File not found in discovery"

**Symptom:**
```
examined: 0
files: []
```

**Solutions:**

1. **Check physical path exists:**
   ```powershell
   Test-Path "C:\inetpub\wwwroot"
   Get-Item "C:\inetpub\wwwroot"
   ```

2. **Update discovery to handle missing paths:**
   Edit `discover-windows-state.yml`:
   ```yaml
   - name: "Find application files"
     ansible.builtin.find:
       paths: "{{ item.physicalPath }}"
       recurse: yes
     register: app_files_raw
     when: item.physicalPath | length > 0
     failed_when: false
   ```

---

## JSON & Data Issues

### Issue: "Failed to parse JSON"

**Symptom:**
```
json.decoder.JSONDecodeError: Expecting value
```

**Solutions:**

1. **Validate JSON files:**
   ```powershell
   # In PowerShell
   Test-Json (Get-Content vars/discovery_output.json)
   ```

2. **Check for encoding issues:**
   ```powershell
   Get-Content vars/discovery_output.json -Encoding UTF8
   ```

3. **Pretty-print for debugging:**
   ```bash
   python -m json.tool vars/discovery_output.json
   ```

---

### Issue: "Special characters in software names"

**Symptom:**
```
JSON contains invalid characters in software name
UnicodeDecodeError: 'utf-8' codec can't decode
```

**Solution:** Update discovery to handle special characters:

```yaml
- name: "Sanitize software names"
  set_fact:
    installed_software: "{{ installed_software | map(attribute='name') | map('regex_replace', '[^\w\s-]', '') | list }}"
```

---

## Performance Issues

### Issue: "Discovery is taking too long"

**Symptom:**
```
Task hangs for 10+ minutes
```

**Solutions:**

1. **Reduce registry scan depth:**
   In `discover-windows-state.yml`, add:
   ```yaml
   - name: "Get software (filtered)"
     ansible.windows.win_reg_stat:
       path: "HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
     register: software_keys
     # Limit results
   ```

2. **Use timeout:**
   ```yaml
   - name: "Get IIS sites"
     ansible.windows.win_powershell:
       script: |
         # PowerShell script
       timeout: 30  # 30 second timeout
     register: iis_result
   ```

3. **Disable fact gathering on subsequent runs:**
   ```yaml
   - name: "Quick discovery (reuse facts)"
     hosts: source_server
     gather_facts: no  # Skip expensive fact gathering
   ```

---

### Issue: "Interactive menu is slow"

**Symptom:**
```
Menu takes 30+ seconds to display
```

**Solution:** Reduce item count in `scripts/interactive-menu.ps1`:

```powershell
# Limit software list to top 100
$softwareNames = $discoveryData.installed_software | 
    Select-Object -ExpandProperty name | 
    Sort-Object -Unique | 
    Select-Object -First 100
```

---

## Deployment Issues

### Issue: "IIS site creation failed"

**Symptom:**
```
The site name already exists
```

**Solution:** Add condition to `deploy-to-destination.yml`:

```yaml
- name: "Check if site exists"
  ansible.windows.win_powershell:
    script: |
      Import-Module WebAdministration
      $site = Get-Website -Name "{{ item.name }}" -ErrorAction SilentlyContinue
      if ($site) { return $true } else { return $false }
  register: site_exists

- name: "Create IIS website"
  when: not site_exists.output
  # Create site task
```

---

### Issue: "AppPool doesn't start"

**Symptom:**
```
Application pool stopped or not responding
```

**Solutions:**

1. **Check .NET version:**
   ```powershell
   Get-ItemProperty IIS:\AppPools\DefaultAppPool | Select-Object ManagedRuntimeVersion
   ```

2. **Start app pool:**
   ```powershell
   Start-WebAppPool -Name "DefaultAppPool"
   ```

3. **Check event logs:**
   ```powershell
   Get-EventLog -LogName Application -Source "WAS" -Newest 10
   ```

---

## Logging & Debugging

### Enable Ansible Debug Mode

```bash
# Set debug environment variable
$env:ANSIBLE_DEBUG=1
ansible-playbook run-complete-workflow.yml -vvvv
```

### Enable PowerShell Debugging

```yaml
- name: "Run with PowerShell tracing"
  ansible.windows.win_powershell:
    script: |
      Set-PSDebug -Trace 2
      Import-Module WebAdministration
      Get-Website
      Set-PSDebug -Trace 0
```

### Check Ansible Execution Log

```bash
# Monitor log in real-time
tail -f ansible_execution.log

# Search for errors
grep -i "error\|failed\|failed_when" ansible_execution.log
```

### Check Windows Event Logs

```powershell
# WinRM events
Get-EventLog -LogName System -Source WinRM -Newest 20

# PowerShell events
Get-EventLog -LogName Windows PowerShell -Newest 20

# Application events
Get-EventLog -LogName Application -Newest 20
```

---

## Network & Firewall Issues

### Issue: "Network path not found"

**Symptom:**
```
The network path cannot be found
```

**Solution:**

1. **Test network connectivity:**
   ```bash
   ping 192.168.1.100
   ansible -i inventory.ini source_server -m win_ping
   ```

2. **Check firewall rules:**
   ```powershell
   Get-NetFirewallRule -DisplayName "*Remote*"
   ```

3. **Test specific ports:**
   ```bash
   # Use Test-NetConnection
   Test-NetConnection -ComputerName 192.168.1.100 -Port 5985
   ```

---

## Reset & Recovery

### Reset WinRM to Defaults

```powershell
# As Administrator
Remove-Item -Path WSMan:\localhost\Listener\* -Force
Enable-PSRemoting -Force
```

### Reset IIS

```powershell
# Backup first
iisreset /backup

# Reset to defaults
iisreset /reset
```

### Clean Ansible Cache

```bash
rm -rf ~/.ansible/
ansible-galaxy install -r requirements.yml --force
```

---

## Getting Help

If issue persists:

1. **Collect diagnostics:**
   ```bash
   # Collect system info
   ansible -i inventory.ini source_server -m setup > system_info.json
   
   # Run with maximum verbosity
   ansible-playbook -vvvv run-complete-workflow.yml 2>&1 | tee troubleshoot.log
   ```

2. **Review Windows Event Viewer:**
   ```powershell
   eventvwr.msc
   # Check: System, Application, Windows PowerShell logs
   ```

3. **Check community forums:**
   - [Ansible Windows Collection Issues](https://github.com/ansible-collections/ansible.windows/issues)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/ansible)
   - [Server Fault](https://serverfault.com/questions/tagged/ansible)
