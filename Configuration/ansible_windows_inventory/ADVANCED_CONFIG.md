# Advanced Configuration & Customization Guide

## 🎯 Customizing Discovery

### Modify Software Discovery

Edit `discover-windows-state.yml` to customize software detection:

```yaml
# Example: Add custom software registry path
- name: "Get custom installed software"
  ansible.windows.win_reg_stat:
    path: "HKLM:\\Software\\MyCompany\\InstalledProducts"
  register: custom_software_keys

# Example: Filter software by name
- name: "Filter Microsoft products only"
  set_fact:
    microsoft_software: "{{ installed_software | selectattr('publisher', 'search', 'Microsoft') | list }}"
```

### Customize IIS Discovery

Add more IIS configuration details:

```yaml
- name: "Get IIS virtual directories"
  ansible.windows.win_powershell:
    script: |
      Import-Module WebAdministration
      Get-WebVirtualDirectory | ConvertTo-Json -Depth 5
  register: iis_vdirs

- name: "Get IIS handler mappings"
  ansible.windows.win_powershell:
    script: |
      Import-Module WebAdministration
      Get-WebHandler | ConvertTo-Json -Depth 5
  register: iis_handlers
```

### Adjust File Discovery

Change file scanning behavior in `discover-windows-state.yml`:

```yaml
# Example: Limit file types to exclude large media files
- name: "Find application files (code only)"
  ansible.builtin.find:
    paths: "{{ item.physicalPath }}"
    recurse: yes
    file_type: file
    patterns: "*.cs,*.aspx,*.js,*.html,*.json,*.config"
  register: app_files_raw

# Example: Get file details with timestamps
- name: "Find files with metadata"
  ansible.builtin.find:
    paths: "{{ item.physicalPath }}"
    recurse: yes
    file_type: file
    get_checksum: yes
    checksum_algorithm: md5
  register: app_files_detailed
```

---

## 🎨 Customizing the Interactive Menu

### Add Categories/Groups

Edit `scripts/interactive-menu.ps1`:

```powershell
# Add software categorization
function Categorize-Software {
    param([array]$Software)
    
    $categories = @{
        'Frameworks' = @()
        'Runtimes' = @()
        'Tools' = @()
        'Libraries' = @()
    }
    
    foreach ($app in $Software) {
        if ($app -match '\.NET|Framework') { $categories['Frameworks'] += $app }
        elseif ($app -match 'Node|Python|Java|Ruby') { $categories['Runtimes'] += $app }
        elseif ($app -match 'Git|Visual Studio|VSCode') { $categories['Tools'] += $app }
        else { $categories['Libraries'] += $app }
    }
    
    return $categories
}

# Display categorized menu
$categorized = Categorize-Software -Software $softwareNames

foreach ($category in $categorized.GetEnumerator()) {
    Write-Host $category.Key -ForegroundColor Yellow
    $category.Value | ForEach-Object { Write-Host "  - $_" }
}
```

### Add Search/Filter

```powershell
# Add search functionality
function Search-Items {
    param(
        [array]$Items,
        [string]$SearchTerm
    )
    
    return $Items | Where-Object { $_ -like "*$SearchTerm*" }
}

# In menu
$searchTerm = Read-Host "Search (or press Enter to skip)"
if ($searchTerm) {
    $filtered = Search-Items -Items $softwareNames -SearchTerm $searchTerm
    # Display filtered results
}
```

### Add Deselect Option

```powershell
# Allow removing items from selection
function Remove-Selection {
    param(
        [array]$CurrentSelections,
        [array]$AllItems
    )
    
    Show-Menu -Title "REMOVE ITEMS FROM SELECTION" -Items $CurrentSelections
    $input = Read-Host "Enter items to remove (comma-separated)"
    # Remove logic here
}
```

---

## 🔄 Customizing Deployment

### Add Software Installation Logic

Edit `deploy-to-destination.yml`:

```yaml
- name: "Install software from repository"
  block:
    - name: "Download installers for selected software"
      ansible.windows.win_command: |
        powershell -Command "
          $software = @({{ selections.selected_software | to_json }})
          foreach ($app in $software) {
            Write-Host 'Installing: $app'
            # Add custom installation logic
          }
        "

    - name: "Handle installation dependencies"
      block:
        - name: "Install .NET Framework first"
          when: '"Framework" in selections.selected_software'
          debug:
            msg: "Installing .NET Framework"

        - name: "Install other software"
          debug:
            msg: "Installing other applications"
```

### Add IIS Application Pool Configuration

```yaml
- name: "Configure application pool settings"
  ansible.windows.win_powershell:
    script: |
      Import-Module WebAdministration
      
      foreach ($site in $sites) {
        $appPool = Get-Item "IIS:\AppPools\$($site.appPool)"
        
        # Set .NET version
        Set-ItemProperty -Path "IIS:\AppPools\$($site.appPool)" -Name ".NET Framework Version" -Value "v4.0"
        
        # Set pipeline mode
        Set-ItemProperty -Path "IIS:\AppPools\$($site.appPool)" -Name "pipelineMode" -Value "Integrated"
        
        # Set recycling options
        Set-ItemProperty -Path "IIS:\AppPools\$($site.appPool)" -Name "recycleConfig" -Value @{
          disallowRotationOnConfigChange = $true
          recyclePeriodicRestart = @{ memory = 262144 }
        }
      }
```

### Add SSL Certificate Binding

```yaml
- name: "Configure SSL bindings"
  block:
    - name: "Import certificates"
      ansible.windows.win_certificate_store:
        path: "C:\\certs\\mycert.pfx"
        state: present
        thumbprint: "{{ cert_thumbprint }}"
        store_location: "LocalMachine"
        store_name: "My"

    - name: "Create HTTPS binding"
      ansible.windows.win_powershell:
        script: |
          Import-Module WebAdministration
          New-WebBinding -Name "{{ site_name }}" -Protocol https -Port 443 -HostHeader "{{ hostname }}" -SslFlags 1
```

---

## 📊 Advanced Features

### Email Notifications

Add email notifications for deployment status:

```yaml
- name: "Send deployment notification"
  community.general.mail:
    host: "{{ mail_server }}"
    port: 587
    username: "{{ mail_user }}"
    password: "{{ mail_password }}"
    from: "ansible@company.com"
    to: "ops@company.com"
    subject: "Deployment Complete"
    body: |
      Deployment to {{ inventory_hostname }} completed.
      Deployed items:
      - Software: {{ selections.selected_software | length }}
      - IIS Sites: {{ selections.selected_iis_sites | length }}
      Status: Success
```

### Slack Integration

```yaml
- name: "Send Slack notification"
  community.general.slack:
    token: "{{ slack_token }}"
    channel: "#deployments"
    msg: |
      Deployment Complete
      Server: {{ inventory_hostname }}
      Software: {{ selections.selected_software | length }} items
      IIS Sites: {{ selections.selected_iis_sites | length }} sites
    color: "good"
  ignore_errors: yes
```

### Database Logging

```yaml
- name: "Log deployment to database"
  community.general.mysql_query:
    login_host: "{{ db_host }}"
    login_user: "{{ db_user }}"
    login_password: "{{ db_password }}"
    login_db: "deployment_logs"
    query: |
      INSERT INTO deployments 
      (hostname, timestamp, software_count, iis_sites_count, status)
      VALUES 
      (%s, %s, %s, %s, %s)
    named_args:
      hostname: "{{ inventory_hostname }}"
      timestamp: "{{ ansible_date_time.iso8601 }}"
      software_count: "{{ selections.selected_software | length }}"
      iis_sites_count: "{{ selections.selected_iis_sites | length }}"
      status: "completed"
```

---

## 🔐 Security Enhancements

### Use Ansible Vault for Credentials

Create encrypted credentials file:

```bash
ansible-vault create vars/credentials.yml
```

Content:
```yaml
vault_ansible_user: Administrator
vault_ansible_password: "{{ secure_password }}"
vault_db_password: "{{ secure_db_password }}"
```

Use in playbooks:
```yaml
- name: "Use vaulted credentials"
  set_fact:
    ansible_user: "{{ vault_ansible_user }}"
    ansible_password: "{{ vault_ansible_password }}"
  no_log: yes
```

### Restrict to Specific IPs

Edit `ansible.cfg`:
```ini
[defaults]
# Only allow connections from trusted IPs
allowed_ip_ranges = 
    192.168.1.0/24
    10.0.0.0/8
```

### Audit Logging

```yaml
- name: "Log all deployments"
  block:
    - name: "Create audit log entry"
      copy:
        content: |
          Deployment Date: {{ ansible_date_time.iso8601 }}
          User: {{ ansible_user_id }}
          Source: {{ ansible_default_ipv4.address }}
          Destination: {{ inventory_hostname }}
          Action: Deployed {{ selections.selected_software | length }} software items
          Status: Success
        dest: "C:\\DeploymentAudit\\{{ ansible_date_time.date }}_audit.log"
      delegate_to: "{{ inventory_hostname }}"
```

---

## 🔧 Performance Optimization

### Parallel Execution

```yaml
- name: "Run tasks in parallel"
  hosts: destination_server
  serial: 1  # Run on one server at a time
  strategy: free  # Don't wait for all hosts
  
  tasks:
    - name: "Parallel deployment"
      async: 300  # Timeout in seconds
      poll: 0     # Don't wait for completion
      shell: "deploy-software.bat"
      register: deployment_job

    - name: "Check job status"
      async_status:
        jid: "{{ deployment_job.ansible_job_id }}"
      register: job_result
      until: job_result.finished
      retries: 30
      delay: 10
```

### Batch Operations

```yaml
- name: "Deploy in batches"
  set_fact:
    software_batches: "{{ selections.selected_software | batch(5) | list }}"

- name: "Deploy each batch"
  block:
    - name: "Install batch of software"
      debug:
        msg: "Installing: {{ item }}"
      loop: "{{ batch }}"
  loop: "{{ software_batches }}"
  loop_control:
    loop_var: batch
```

---

## 🐛 Debugging

### Enable Verbose Logging

```bash
# Run with maximum verbosity
ansible-playbook -vvvv run-complete-workflow.yml

# Save debug output to file
ansible-playbook -vvvv run-complete-workflow.yml 2>&1 | tee debug.log
```

### Debug Single Task

```yaml
- name: "Debug discovery data"
  debug:
    var: installed_software
    verbosity: 2  # Only show when -vv or higher
```

### Enable PowerShell Debugging

```yaml
- name: "Run PowerShell with debugging"
  ansible.windows.win_powershell:
    script: |
      Set-PSDebug -Trace 1  # Enable tracing
      # Your PowerShell code
      Set-PSDebug -Trace 0  # Disable tracing
```

---

## 📈 Scaling to Multiple Servers

### Discover from Multiple Source Servers

```yaml
---
- name: "Multi-server discovery"
  hosts: all_source_servers
  serial: 1
  
  tasks:
    - name: "Run discovery on each server"
      include: discover-windows-state.yml
      vars:
        server_discovery_file: "{{ playbook_dir }}/vars/discovery_{{ inventory_hostname }}.json"
```

### Deploy to Multiple Destinations

```yaml
---
- name: "Multi-server deployment"
  hosts: all_destination_servers
  serial: 2  # Deploy to 2 servers at a time
  
  tasks:
    - name: "Deploy to each destination"
      include: deploy-to-destination.yml
```

---

## 📝 Custom Report Generation

### Generate HTML Report

```yaml
- name: "Generate deployment report"
  template:
    src: "deployment_report.html.j2"
    dest: "{{ playbook_dir }}/reports/deployment_{{ ansible_date_time.date }}.html"
  delegate_to: localhost
```

Template file (`templates/deployment_report.html.j2`):
```html
<!DOCTYPE html>
<html>
<head>
    <title>Deployment Report</title>
    <style>
        body { font-family: Arial; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
    </style>
</head>
<body>
    <h1>Deployment Report</h1>
    <p>Deployment Date: {{ deployment_log.start_time }}</p>
    
    <h2>Summary</h2>
    <table>
        <tr>
            <th>Metric</th>
            <th>Count</th>
        </tr>
        <tr>
            <td>Software Deployed</td>
            <td>{{ deployment_log.software_count }}</td>
        </tr>
        <tr>
            <td>IIS Sites Created</td>
            <td>{{ deployment_log.iis_sites_count }}</td>
        </tr>
    </table>
</body>
</html>
```

---

For more customization options, refer to:
- [Ansible Windows Collection Docs](https://docs.ansible.com/ansible/latest/collections/ansible/windows/)
- [Jinja2 Templating Guide](https://jinja.palletsprojects.com/)
