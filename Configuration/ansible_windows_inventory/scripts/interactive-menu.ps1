# ==============================================================================
# SCRIPT: interactive-menu.ps1
# PURPOSE: Interactive menu for selecting software, IIS sites, and files
# DESCRIPTION: Displays discovered items with filtering, formatting, and toggle select/deselect
# OUTPUT: JSON file with selected items
# ==============================================================================

param(
    [string]$DiscoveryDataFile = "$PSScriptRoot\..\vars\discovery_output.json",
    [string]$SelectionOutputFile = "$PSScriptRoot\..\vars\selection_results.json"
)

# Import discovery data
if (-not (Test-Path $DiscoveryDataFile)) {
    Write-Host "Error: Discovery data file not found at $DiscoveryDataFile" -ForegroundColor Red
    exit 1
}

$discoveryData = Get-Content $DiscoveryDataFile | ConvertFrom-Json

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

function Show-FormattedTable {
    param(
        [string]$Title,
        [array]$Items,
        [string]$ItemProperty = "name",
        [array]$SelectedItems = @(),
        [array]$ColumnProperties = @()
    )
    
    Clear-Host
    Write-Host "=================================================================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "Selected: $($SelectedItems.Count) items | Total: $($Items.Count) items" -ForegroundColor Yellow
    Write-Host "=================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $item = $Items[$i]
        $isSelected = $SelectedItems | Where-Object { $_ -eq $item }
        $status = if ($isSelected) { "[✓]" } else { "[ ]" }
        $statusColor = if ($isSelected) { "Green" } else { "Gray" }
        
        $displayName = if ($item -is [string]) { $item } else { $item.$ItemProperty }
        
        Write-Host "$status $($i + 1). $displayName" -ForegroundColor $statusColor
        
        # Show additional details if available
        if ($item -is [object] -and $null -ne $item.publisher) {
            Write-Host "      Publisher: $($item.publisher) | Version: $($item.version)" -ForegroundColor Gray
        }
        elseif ($item -is [object] -and $null -ne $item.appPool) {
            Write-Host "      AppPool: $($item.appPool) | Path: $($item.physicalPath)" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

function Show-Help {
    Write-Host "COMMANDS:" -ForegroundColor Cyan
    Write-Host "  [#]       - Toggle selection of item number #" -ForegroundColor Cyan
    Write-Host "  [a]       - Select All items" -ForegroundColor Cyan
    Write-Host "  [n]       - Deselect All items" -ForegroundColor Cyan
    Write-Host "  [f]       - Filter by keyword" -ForegroundColor Cyan
    Write-Host "  [v]       - View current selections" -ForegroundColor Cyan
    Write-Host "  [0]       - Continue to next step" -ForegroundColor Cyan
    Write-Host "  [h]       - Show this help" -ForegroundColor Cyan
    Write-Host ""
}

function Get-FilteredItems {
    param(
        [array]$Items,
        [string]$Filter,
        [string]$ItemProperty = "name"
    )
    
    if ([string]::IsNullOrWhiteSpace($Filter)) {
        return $Items
    }
    
    $Items | Where-Object {
        $displayName = if ($_ -is [string]) { $_ } else { $_.$ItemProperty }
        $displayName -like "*$Filter*"
    }
}

function Get-MultiSelectToggle {
    param(
        [string]$Title,
        [array]$Items,
        [string]$ItemProperty = "name",
        [string]$FilterProperty = $null
    )
    
    $selected = @()
    $allItems = $Items
    $filteredItems = $allItems
    $currentFilter = ""
    
    while ($true) {
        Show-FormattedTable -Title $Title -Items $filteredItems -ItemProperty $ItemProperty -SelectedItems $selected
        
        if ($filteredItems.Count -gt 20) {
            Write-Host "Showing $($filteredItems.Count) items (current filter: '$currentFilter')" -ForegroundColor Yellow
        }
        
        Show-Help
        
        $input = Read-Host "Enter command"
        
        if ($input -eq "0") {
            break
        }
        elseif ($input -eq "a") {
            $selected = $filteredItems
            Write-Host "Selected all $($selected.Count) items" -ForegroundColor Green
            Read-Host "Press Enter to continue"
        }
        elseif ($input -eq "n") {
            $selected = @()
            Write-Host "Deselected all items" -ForegroundColor Yellow
            Read-Host "Press Enter to continue"
        }
        elseif ($input -eq "f") {
            $currentFilter = Read-Host "Enter filter keyword"
            $filteredItems = Get-FilteredItems -Items $allItems -Filter $currentFilter -ItemProperty $ItemProperty
            Write-Host "Found $($filteredItems.Count) matching items" -ForegroundColor Yellow
            Read-Host "Press Enter to continue"
        }
        elseif ($input -eq "v") {
            Clear-Host
            Write-Host "CURRENT SELECTIONS ($($selected.Count) items):" -ForegroundColor Green
            Write-Host "=================================" -ForegroundColor Green
            if ($selected.Count -eq 0) {
                Write-Host "No items selected yet" -ForegroundColor Gray
            } else {
                $selected | ForEach-Object {
                    $displayName = if ($_ -is [string]) { $_ } else { $_.$ItemProperty }
                    Write-Host "  ✓ $displayName" -ForegroundColor Green
                }
            }
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
        elseif ($input -eq "h") {
            Write-Host ""
            Write-Host "DETAILED HELP:" -ForegroundColor Cyan
            Show-Help
            Read-Host "Press Enter to continue"
        }
        elseif ([int]::TryParse($input, [ref]0) -and [int]$input -gt 0 -and [int]$input -le $filteredItems.Count) {
            $selectedItem = $filteredItems[[int]$input - 1]
            $isCurrentlySelected = $selected | Where-Object { $_ -eq $selectedItem }
            
            if ($isCurrentlySelected) {
                $selected = @($selected | Where-Object { $_ -ne $selectedItem })
                Write-Host "Deselected item $input" -ForegroundColor Yellow
            } else {
                $selected += $selectedItem
                Write-Host "Selected item $input" -ForegroundColor Green
            }
            Read-Host "Press Enter to continue"
        }
        else {
            Write-Host "Invalid input. Enter a number, 'a' (all), 'n' (none), 'f' (filter), 'v' (view), 'h' (help), or '0' (continue)" -ForegroundColor Red
            Read-Host "Press Enter to continue"
        }
    }
    
    return $selected
}

# ==============================================================================
# MAIN SELECTION FLOW
# ==============================================================================

# ==============================================================================
# MAIN SELECTION FLOW
# ==============================================================================

Clear-Host
Write-Host "=================================================================================" -ForegroundColor Yellow
Write-Host "WINDOWS INFRASTRUCTURE SELECTION TOOL" -ForegroundColor Yellow
Write-Host "=================================================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Hostname: $($discoveryData.hostname)" -ForegroundColor Cyan
Write-Host "OS: $($discoveryData.os_version)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Discovery Summary:"
Write-Host "  - Installed Software: $($discoveryData.software_count) items"
Write-Host "  - IIS Installed: $($discoveryData.iis_installed)"
Write-Host "  - IIS Sites: $($discoveryData.iis_sites_count) sites"
Write-Host ""
Write-Host "Features:" -ForegroundColor Cyan
Write-Host "  - Toggle selections with item number" -ForegroundColor Gray
Write-Host "  - Filter by keyword (f)" -ForegroundColor Gray
Write-Host "  - Select/Deselect all (a/n)" -ForegroundColor Gray
Write-Host "  - View selections (v)" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to start selection process"

# ==============================================================================
# STEP 1: Select Software with Filtering
# ==============================================================================

$selectedSoftware = @()

if ($discoveryData.installed_software.Count -gt 0) {
    Write-Host "Step 1 of 3: SELECT SOFTWARE" -ForegroundColor Yellow
    Write-Host ""
    
    $softwareList = $discoveryData.installed_software | Sort-Object -Property publisher, name -Unique
    
    $selectedSoftware = Get-MultiSelectToggle -Title "SELECT INSTALLED SOFTWARE TO DEPLOY (Filter enabled - use 'f' to search by name/publisher)" `
                                              -Items $softwareList `
                                              -ItemProperty "name"
    
    Write-Host "Selected $($selectedSoftware.Count) software items" -ForegroundColor Green
    Start-Sleep -Seconds 1
}

# ==============================================================================
# STEP 2: Select IIS Sites
# ==============================================================================

$selectedSites = @()

if ($discoveryData.iis_sites.Count -gt 0) {
    Write-Host "Step 2 of 3: SELECT IIS SITES" -ForegroundColor Yellow
    Write-Host ""
    
    $siteList = $discoveryData.iis_sites | Sort-Object -Property name
    
    $selectedSites = Get-MultiSelectToggle -Title "SELECT IIS SITES TO DEPLOY" `
                                          -Items $siteList `
                                          -ItemProperty "name"
    
    Write-Host "Selected $($selectedSites.Count) IIS sites" -ForegroundColor Green
    Start-Sleep -Seconds 1
}

# ==============================================================================
# STEP 3: Select Application Files
# ==============================================================================

$selectedAppPaths = @()

if ($discoveryData.application_files.Count -gt 0) {
    Write-Host "Step 3 of 3: SELECT APPLICATION PATHS" -ForegroundColor Yellow
    Write-Host ""
    
    $appPaths = $discoveryData.application_files | Select-Object -Property site_name, physical_path -Unique | Sort-Object -Property site_name
    $appPathObjects = @()
    foreach ($path in $appPaths) {
        $appPathObjects += @{
            site_name = $path.site_name
            physical_path = $path.physical_path
            display_name = "$($path.site_name) ➜ $($path.physical_path)"
        }
    }
    
    $selectedPaths = Get-MultiSelectToggle -Title "SELECT APPLICATION PATHS TO DEPLOY" `
                                          -Items $appPathObjects `
                                          -ItemProperty "display_name"
    
    foreach ($selected in $selectedPaths) {
        $selectedAppPaths += @{
            site_name = $selected.site_name
            physical_path = $selected.physical_path
        }
    }
    
    Write-Host "Selected $($selectedAppPaths.Count) application paths" -ForegroundColor Green
    Start-Sleep -Seconds 1
}

# ==============================================================================
# STEP 4: Build Selection Summary and Save Results
# ==============================================================================

Clear-Host
Write-Host "=================================================================================" -ForegroundColor Green
Write-Host "SELECTION SUMMARY & CONFIRMATION" -ForegroundColor Green
Write-Host "=================================================================================" -ForegroundColor Green
Write-Host ""

$totalSelected = $selectedSoftware.Count + $selectedSites.Count + $selectedAppPaths.Count

if ($totalSelected -eq 0) {
    Write-Host "⚠ WARNING: No items selected!" -ForegroundColor Yellow
    Write-Host ""
    $proceed = Read-Host "Do you want to continue with empty selection? (Y/N)"
    if ($proceed -ne "Y" -and $proceed -ne "y") {
        Write-Host "Selection cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "SELECTED ITEMS: $totalSelected" -ForegroundColor Cyan
Write-Host ""

Write-Host "Software: $($selectedSoftware.Count) items" -ForegroundColor Yellow
if ($selectedSoftware.Count -gt 0) {
    $selectedSoftware | ForEach-Object {
        $softwareName = if ($_ -is [string]) { $_ } else { $_.name }
        $publisher = if ($_ -is [string]) { "Unknown" } else { $_.publisher }
        Write-Host "  ✓ $softwareName" -ForegroundColor Green
        Write-Host "      Publisher: $publisher" -ForegroundColor Gray
    }
} else {
    Write-Host "  (none)" -ForegroundColor Gray
}
Write-Host ""

Write-Host "IIS Sites: $($selectedSites.Count) sites" -ForegroundColor Yellow
if ($selectedSites.Count -gt 0) {
    $selectedSites | ForEach-Object { Write-Host "  ✓ $($_.name) (Pool: $($_.appPool), Path: $($_.physicalPath))" -ForegroundColor Green }
} else {
    Write-Host "  (none)" -ForegroundColor Gray
}
Write-Host ""

Write-Host "Application Paths: $($selectedAppPaths.Count) paths" -ForegroundColor Yellow
if ($selectedAppPaths.Count -gt 0) {
    $selectedAppPaths | ForEach-Object { Write-Host "  ✓ $($_.site_name) ➜ $($_.physical_path)" -ForegroundColor Green }
} else {
    Write-Host "  (none)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "=================================================================================" -ForegroundColor Green
Write-Host ""

$confirm = Read-Host "Confirm selections? (Y/N)"

if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Selection cancelled." -ForegroundColor Yellow
    exit 0
}

# ==============================================================================
# Save Selection Results
# ==============================================================================

$selectionResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    hostname = $discoveryData.hostname
    total_selected = $totalSelected
    selected_software = @($selectedSoftware)
    selected_iis_sites = @($selectedSites)
    selected_app_paths = @($selectedAppPaths)
    source_discovery_file = $DiscoveryDataFile
}

try {
    $selectionResults | ConvertTo-Json -Depth 10 | Out-File $SelectionOutputFile -Force
    Write-Host ""
    Write-Host "✓ Selection results saved to: $SelectionOutputFile" -ForegroundColor Green
    Write-Host "✓ Ready for deployment!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Run: ansible-playbook deploy-to-destination.yml" -ForegroundColor Cyan
    Write-Host "  2. Or use dry-run: ansible-playbook deploy-to-destination.yml -e dryrun=true" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host "✗ ERROR: Failed to save selection results" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    exit 1
}

exit 0
