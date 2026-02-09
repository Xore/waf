# Plaintext Scripts Naming Convention - Final Standard

**Project:** Windows Automation Framework (WAF)  
**Date:** February 9, 2026  
**Version:** 2.0 - Simplified Schema  
**Status:** Official Standard

---

## Naming Convention Schema

### Format

```
[Human_Readable_Short][Number].ps1
```

**Components:**

1. **Human_Readable_Short**
   - Brief descriptive name
   - Maximum 8 words
   - Uses underscores for spaces
   - Describes what the script does
   - PascalCase for each word

2. **Number**
   - Sequential number starting from 1
   - Increments for each script
   - No leading zeros
   - No category prefixes

3. **Extension**
   - Always `.ps1` (PowerShell)
   - All batch scripts converted to PowerShell

---

## Examples

### Good Examples

```
Active_Directory_Domain_Controller_Health_Monitor1.ps1
Active_Directory_Get_OU_Members2.ps1
Active_Directory_Join_Computer_to_Domain3.ps1
Firewall_Status_Audit_Monitor4.ps1
SMBv1_Compliance_Check5.ps1
Battery_Health_Monitor6.ps1
Blue_Screen_Alert_Monitor7.ps1
Install_Dell_Command_Update8.ps1
Clear_DNS_Cache9.ps1
Map_Network_Drives10.ps1
```

### Bad Examples

```
❌ Script_01_Active_Directory_Monitor.ps1  (has "Script_" prefix)
❌ 01_Active_Directory.ps1                  (has leading zero)
❌ active-directory-monitor.ps1             (uses hyphens)
❌ ActiveDirectoryDomainControllerHealthReportMonitoringScript.ps1  (>8 words)
❌ AD_DC_Mon.ps1                            (abbreviations unclear)
```

---

## Rules

### 1. Human Readable Portion

**Length:**
- Minimum: 2 words
- Maximum: 8 words
- Aim for 3-5 words for clarity

**Word Choice:**
- Use full words (avoid abbreviations except well-known ones)
- Be descriptive but concise
- Include action verb when applicable (Monitor, Install, Remove, Get, Set, Clear, etc.)

**Capitalization:**
- PascalCase for each word
- First letter of each word capitalized
- No all-caps words

**Separators:**
- Use underscores `_` between words
- No hyphens `-`
- No spaces ` `

**Allowed Abbreviations:**
- AD (Active Directory)
- DC (Domain Controller)
- OU (Organizational Unit)
- DNS (Domain Name System)
- DHCP (Dynamic Host Configuration Protocol)
- RDP (Remote Desktop Protocol)
- SQL (Structured Query Language)
- IIS (Internet Information Services)
- VM (Virtual Machine)
- SSL (Secure Sockets Layer)
- UAC (User Account Control)
- GPO (Group Policy Object)
- NTP (Network Time Protocol)
- BSOD (Blue Screen of Death)
- WiFi (Wireless Fidelity)
- VPN (Virtual Private Network)

### 2. Number Portion

**Format:**
- Sequential integers: 1, 2, 3, 4, ..., 164
- No leading zeros
- No gaps in sequence
- Starts at 1 for first script

**Ordering:**
- Alphabetical by human readable portion
- Within same category, alphabetically sorted

### 3. Extension

**Required:**
- Always `.ps1`
- All scripts must be PowerShell
- Batch scripts (.bat, .cmd) converted to PowerShell first

---

## Numbering System

### Sequential Numbering by Alphabetical Order

Scripts are numbered 1-164 in alphabetical order by their human-readable name:

```
Active_Directory_Domain_Controller_Health1.ps1
Active_Directory_Get_OU_Members2.ps1
Active_Directory_Join_Computer3.ps1
Active_Directory_Remove_Computer4.ps1
Active_Directory_Repair_Trust5.ps1
Active_Directory_Replication_Health6.ps1
Active_Power_Plan_Report7.ps1
Add_Wifi_Profile_Moeller8.ps1
Alert_DHCP_Lease_Low9.ps1
Alert_Stopped_Automatic_Services10.ps1
...
Windows_Update_Diagnostic164.ps1
```

### No Category Prefixes

Unlike the old system, we do NOT use:
- ❌ `Script_XX_` prefix for monitors
- ❌ `XX_` prefix for automation
- ✅ Just human readable + number

Script type (monitor vs automation) is determined by:
1. Content of the script
2. Documentation in header
3. Field updates (monitors set fields)

---

## Word Count Guidelines

### 2 Words (Minimum)
```
Clear_DNS9.ps1
Map_Drives10.ps1
```

### 3-4 Words (Ideal)
```
Battery_Health_Monitor6.ps1
Firewall_Status_Audit4.ps1
Install_Office_365_Custom34.ps1
```

### 5-6 Words (Good)
```
Active_Directory_Domain_Controller_Health1.ps1
Windows_11_Upgrade_Compatibility_Check55.ps1
```

### 7-8 Words (Maximum)
```
Enable_Mini_Dumps_for_BSOD_Analysis100.ps1
Install_and_Run_BGInfo_Desktop_Background37.ps1
```

### Over 8 Words (Too Long - Simplify)
```
❌ Active_Directory_Domain_Controller_Health_Report_Monitor_and_Alert.ps1
✅ Active_Directory_DC_Health_Monitor1.ps1

❌ Install_Microsoft_Office_365_with_Custom_Configuration_Options.ps1
✅ Install_Office_365_Custom34.ps1

❌ Get_List_of_All_Stopped_Windows_Services_That_Should_Be_Running.ps1
✅ Alert_Stopped_Automatic_Services10.ps1
```

---

## Category Organization

While the filename doesn't include category prefixes, scripts are still organized by function:

### Active Directory (AD)
```
Active_Directory_DC_Health_Monitor1.ps1
Active_Directory_Get_OU_Members2.ps1
Active_Directory_Join_Computer3.ps1
Active_Directory_Remove_Computer4.ps1
Active_Directory_Repair_Trust5.ps1
Active_Directory_Replication_Monitor6.ps1
```

### Security & Compliance
```
Antivirus_Detection_Monitor15.ps1
Brute_Force_Login_Alert_Monitor14.ps1
Credential_Guard_Status_Monitor9.ps1
Firewall_Status_Audit_Monitor27.ps1
Secure_Boot_Compliance_Monitor17.ps1
SMBv1_Compliance_Check13.ps1
SSD_Wear_Health_Alert18.ps1
Unencrypted_Disk_Alert19.ps1
Unsigned_Driver_Alert20.ps1
```

### Network
```
Alert_DHCP_Lease_Low22.ps1
Clear_DNS_Cache9.ps1
Deploy_WiFi_Profile10.ps1
LLDP_Information_Monitor24.ps1
Rogue_DHCP_Detection23.ps1
Set_DNS_Server_Address12.ps1
WiFi_Report25.ps1
Wired_Network_Speed_Alert26.ps1
```

### System Operations
```
Battery_Health_Monitor6.ps1
Blue_Screen_Alert_Monitor7.ps1
Device_Uptime_Monitor10.ps1
Last_Reboot_Reason_Monitor11.ps1
Power_Plan_Report4.ps1
System_Performance_Monitor12.ps1
UAC_Level_Audit5.ps1
```

---

## Conversion Examples

### From Old Inventory

| Old Name | New Name |
|----------|----------|
| Active Directory - Domain Controller Health Report.txt | Active_Directory_DC_Health_Monitor1.ps1 |
| Active Directory - Get OU Members.txt | Active_Directory_Get_OU_Members2.ps1 |
| Firewall - Audit Status.txt | Firewall_Status_Audit27.ps1 |
| Check Battery Health.txt | Battery_Health_Monitor6.ps1 |
| Blue Screen Alert.txt | Blue_Screen_Alert_Monitor7.ps1 |
| Install Office 365 with options.txt | Install_Office_365_Custom34.ps1 |
| Clear DNS Cache.txt | Clear_DNS_Cache9.ps1 |
| Enable or Disable Remote Desktop (RDP).txt | Configure_Remote_Desktop18.ps1 |
| Get WiFi Driver Info.txt | Get_WiFi_Driver_Info11.ps1 |
| Map Network Drives.txt | Map_Network_Drives68.ps1 |

---

## Automated Renaming Script

### Script: `scripts/Rename-Scripts-New-Convention.ps1`

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Renames all plaintext scripts using simplified naming convention.

.DESCRIPTION
    Applies new naming convention: [Human_Readable_Short][Number].ps1
    - Human readable: 2-8 words with underscores
    - Number: Sequential 1-164 in alphabetical order
    - Extension: .ps1 only

.PARAMETER ScriptsPath
    Path to plaintext_scripts folder

.PARAMETER MappingFile
    CSV file with old names and new short names

.PARAMETER WhatIf
    Show what would be renamed without actually renaming

.EXAMPLE
    .\Rename-Scripts-New-Convention.ps1 -WhatIf
    
.EXAMPLE
    .\Rename-Scripts-New-Convention.ps1 -MappingFile "rename_map.csv"
#>

param(
    [string]$ScriptsPath = "plaintext_scripts",
    [string]$MappingFile = "docs/tracking/rename_mapping_simplified.csv",
    [switch]$WhatIf
)

Write-Host "WAF Script Renaming - Simplified Convention" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $MappingFile)) {
    Write-Error "Mapping file not found: $MappingFile"
    Write-Host "Please run: .\Generate-Simplified-Rename-Mapping.ps1" -ForegroundColor Yellow
    exit 1
}

# Load mapping
$mapping = Import-Csv $MappingFile
Write-Host "Loaded $($mapping.Count) rename mappings" -ForegroundColor Green

# Sort by new name to ensure alphabetical numbering
$mapping = $mapping | Sort-Object NewName

# Apply sequential numbering
$counter = 1
foreach ($item in $mapping) {
    # Extract name without number if present
    $baseName = $item.NewName -replace '\d+\.ps1$', ''
    $item.FinalName = "$baseName$counter.ps1"
    $counter++
}

Write-Host ""
Write-Host "Rename Plan:" -ForegroundColor Cyan
Write-Host "------------" -ForegroundColor Cyan

foreach ($item in $mapping | Select-Object -First 10) {
    Write-Host "$($item.OldName)" -ForegroundColor Yellow
    Write-Host "  -> $($item.FinalName)" -ForegroundColor Green
}

Write-Host "... and $($mapping.Count - 10) more" -ForegroundColor White
Write-Host ""

if ($WhatIf) {
    Write-Host "WHATIF MODE - No files will be renamed" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($item in $mapping) {
        Write-Host "[WHATIF] $($item.OldName) -> $($item.FinalName)" -ForegroundColor Cyan
    }
    
    exit 0
}

# Confirm
$response = Read-Host "Proceed with renaming $($mapping.Count) files? (yes/no)"
if ($response -ne 'yes') {
    Write-Host "Rename cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Renaming files..." -ForegroundColor Cyan

$renamed = 0
$errors = 0

foreach ($item in $mapping) {
    $oldPath = Join-Path $ScriptsPath $item.OldName
    $newPath = Join-Path $ScriptsPath $item.FinalName
    
    if (-not (Test-Path $oldPath)) {
        Write-Warning "Source file not found: $($item.OldName)"
        $errors++
        continue
    }
    
    if (Test-Path $newPath) {
        Write-Warning "Target file already exists: $($item.FinalName)"
        $errors++
        continue
    }
    
    try {
        Rename-Item -Path $oldPath -NewName $item.FinalName -ErrorAction Stop
        Write-Host "✓ $($item.FinalName)" -ForegroundColor Green
        $renamed++
    }
    catch {
        Write-Error "Failed to rename $($item.OldName): $($_.Exception.Message)"
        $errors++
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Rename Summary:" -ForegroundColor Cyan
Write-Host "  Renamed: $renamed" -ForegroundColor Green
Write-Host "  Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Total: $($mapping.Count)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if ($renamed -gt 0) {
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Review renamed files" -ForegroundColor White
    Write-Host "2. Run: git add plaintext_scripts/" -ForegroundColor White
    Write-Host "3. Run: git commit -m 'Apply simplified naming convention'" -ForegroundColor White
    Write-Host "4. Run: git push" -ForegroundColor White
}
```

---

## Mapping Generation Script

### Script: `scripts/Generate-Simplified-Rename-Mapping.ps1`

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Generates simplified rename mapping for all plaintext scripts.

.DESCRIPTION
    Creates CSV mapping with:
    - Original filename
    - Simplified human-readable name (2-8 words)
    - Sequential number assignment (alphabetical)

.OUTPUTS
    docs/tracking/rename_mapping_simplified.csv
#>

param(
    [string]$ScriptsPath = "plaintext_scripts",
    [string]$OutputPath = "docs/tracking",
    [string]$InventoryFile = "docs/PLAINTEXT_SCRIPTS_INVENTORY.md"
)

Write-Host "Generating Simplified Rename Mapping..." -ForegroundColor Cyan

# Simplification rules
function Get-SimplifiedName {
    param([string]$Name)
    
    # Remove common prefixes/suffixes
    $name = $Name -replace '^(Script_\d+_|\d+_)', ''  # Remove Script_XX_ or XX_
    $name = $name -replace '_Monitor\.ps1$', '_Monitor'  # Temporarily remove extension
    $name = $name -replace '\.ps1$', ''  # Remove .ps1
    $name = $name -replace '\.txt$', ''  # Remove .txt
    
    # Split into words
    $words = $name -split '_' | Where-Object { $_ -ne '' }
    
    # Apply simplification
    $simplified = @()
    
    foreach ($word in $words) {
        # Skip common fillers if over 6 words
        if ($words.Count -gt 6 -and $word -in @('and', 'the', 'for', 'with', 'from', 'to')) {
            continue
        }
        
        # Add word
        $simplified += $word
        
        # Stop at 8 words
        if ($simplified.Count -eq 8) {
            break
        }
    }
    
    # Rejoin
    $result = $simplified -join '_'
    
    # Ensure minimum 2 words
    if ($simplified.Count -lt 2) {
        return $null
    }
    
    return $result
}

# Load existing inventory if available
$existingMapping = @{}
if (Test-Path $InventoryFile) {
    $content = Get-Content $InventoryFile -Raw
    
    # Parse table entries
    $matches = [regex]::Matches($content, '\|\s*([^|]+?)\s*\|\s*([^|]+?)\.ps1\s*\|')
    foreach ($match in $matches) {
        $oldName = $match.Groups[1].Value.Trim()
        $newName = $match.Groups[2].Value.Trim()
        
        if ($oldName -ne '' -and $oldName -notmatch '^(#|---|Current|Old)') {
            $existingMapping[$oldName] = $newName
        }
    }
}

Write-Host "Loaded $($existingMapping.Count) existing mappings" -ForegroundColor Green

# Get all scripts
$scripts = Get-ChildItem -Path $ScriptsPath -File | Where-Object {
    $_.Extension -in @('.ps1', '.txt', '.bat', '.cmd')
}

Write-Host "Found $($scripts.Count) scripts to map" -ForegroundColor Green

$mapping = @()

foreach ($script in $scripts) {
    $oldName = $script.Name
    
    # Check if we have existing mapping
    if ($existingMapping.ContainsKey($oldName)) {
        $newName = Get-SimplifiedName -Name $existingMapping[$oldName]
    }
    else {
        # Generate from old name
        $newName = Get-SimplifiedName -Name $oldName
    }
    
    if ($null -eq $newName) {
        Write-Warning "Could not simplify: $oldName"
        $newName = $oldName -replace '\.(txt|bat|cmd)$', ''
    }
    
    $mapping += [PSCustomObject]@{
        OldName = $oldName
        NewName = $newName
        WordCount = ($newName -split '_').Count
        Category = if ($newName -match '^Active_Directory') { 'AD' }
                   elseif ($newName -match '(Firewall|Security|Antivirus|Encryption)') { 'Security' }
                   elseif ($newName -match '(Network|DNS|DHCP|WiFi|IP)') { 'Network' }
                   elseif ($newName -match '(SQL|Exchange|Hyper|IIS|Server)') { 'Server' }
                   elseif ($newName -match '(Install|Remove|Uninstall)') { 'Software' }
                   else { 'Other' }
    }
}

# Sort alphabetically by new name
$mapping = $mapping | Sort-Object NewName

# Add sequential numbers
$counter = 1
foreach ($item in $mapping) {
    $item | Add-Member -NotePropertyName 'FinalNumber' -NotePropertyValue $counter
    $item | Add-Member -NotePropertyName 'FinalName' -NotePropertyValue "$($item.NewName)$counter.ps1"
    $counter++
}

# Save mapping
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
$mapping | Export-Csv "$OutputPath/rename_mapping_simplified.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Saved: $OutputPath/rename_mapping_simplified.csv" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "Mapping Summary:" -ForegroundColor Cyan
Write-Host "  Total Scripts: $($mapping.Count)" -ForegroundColor White
Write-Host ""
Write-Host "By Word Count:" -ForegroundColor Cyan
$mapping | Group-Object WordCount | Sort-Object Name | ForEach-Object {
    Write-Host "  $($_.Name) words: $($_.Count) scripts" -ForegroundColor White
}

Write-Host ""
Write-Host "By Category:" -ForegroundColor Cyan
$mapping | Group-Object Category | Sort-Object Count -Descending | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) scripts" -ForegroundColor White
}

Write-Host ""
Write-Host "Sample Mappings:" -ForegroundColor Cyan
$mapping | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.OldName)" -ForegroundColor Yellow
    Write-Host "    -> $($_.FinalName)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next: Run .\Rename-Scripts-New-Convention.ps1 -WhatIf" -ForegroundColor Yellow
```

---

## Validation Script

### Script: `scripts/Validate-Naming-Convention.ps1`

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Validates scripts follow simplified naming convention.

.DESCRIPTION
    Checks:
    - Format: [Human_Readable][Number].ps1
    - Word count: 2-8 words
    - Extension: .ps1 only
    - Sequential numbering
#>

param(
    [string]$ScriptsPath = "plaintext_scripts"
)

Write-Host "Validating Naming Convention..." -ForegroundColor Cyan

$scripts = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" | Sort-Object Name
$issues = @()

foreach ($script in $scripts) {
    $name = $script.BaseName
    
    # Check format: ends with number
    if ($name -notmatch '\d+$') {
        $issues += "❌ $($script.Name): Does not end with number"
        continue
    }
    
    # Extract parts
    $number = [regex]::Match($name, '\d+$').Value
    $humanPart = $name -replace '\d+$', ''
    
    # Count words
    $words = ($humanPart -split '_' | Where-Object { $_ -ne '' })
    $wordCount = $words.Count
    
    # Validate word count
    if ($wordCount -lt 2) {
        $issues += "❌ $($script.Name): Too few words ($wordCount, need 2-8)"
    }
    elseif ($wordCount -gt 8) {
        $issues += "❌ $($script.Name): Too many words ($wordCount, max 8)"
    }
    
    # Check for hyphens
    if ($name -match '-') {
        $issues += "❌ $($script.Name): Contains hyphens (use underscores)"
    }
    
    # Check for spaces
    if ($script.Name -match ' ') {
        $issues += "❌ $($script.Name): Contains spaces"
    }
}

# Check sequential numbering
$numbers = $scripts | ForEach-Object {
    if ($_.BaseName -match '(\d+)$') {
        [int]$matches[1]
    }
} | Sort-Object

for ($i = 0; $i -lt $numbers.Count; $i++) {
    if ($numbers[$i] -ne ($i + 1)) {
        $issues += "⚠️  Numbering gap or duplicate at: $($numbers[$i])"
    }
}

# Report
Write-Host ""
if ($issues.Count -eq 0) {
    Write-Host "✓ All $($scripts.Count) scripts follow naming convention" -ForegroundColor Green
}
else {
    Write-Host "Found $($issues.Count) issues:" -ForegroundColor Red
    Write-Host ""
    $issues | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
}

Write-Host ""
Write-Host "Convention: [Human_Readable_Short][Number].ps1" -ForegroundColor Cyan
Write-Host "  - Human readable: 2-8 words with underscores" -ForegroundColor White
Write-Host "  - Number: Sequential 1-$($scripts.Count)" -ForegroundColor White
Write-Host "  - Extension: .ps1" -ForegroundColor White
```

---

## Summary

### Key Changes from Previous Convention

| Aspect | Old Convention | New Convention |
|--------|----------------|----------------|
| Format | Script_XX_Name_Monitor.ps1 | Name_Monitor1.ps1 |
| Prefixes | Script_XX_ or XX_ | None |
| Numbering | By category | Sequential 1-164 |
| Word Limit | No limit | 2-8 words |
| Separators | Underscores | Underscores |
| Extension | .ps1 | .ps1 |

### Benefits

1. **Simpler:** No category prefixes to remember
2. **Shorter:** Human readable portion only, shorter names
3. **Clearer:** Descriptive names up to 8 words
4. **Sequential:** Easy to track (1-164)
5. **Sortable:** Alphabetical by function
6. **Consistent:** One format for all scripts

### Implementation

```powershell
# Generate mapping
.\scripts\Generate-Simplified-Rename-Mapping.ps1

# Preview changes
.\scripts\Rename-Scripts-New-Convention.ps1 -WhatIf

# Apply renaming
.\scripts\Rename-Scripts-New-Convention.ps1

# Validate results
.\scripts\Validate-Naming-Convention.ps1

# Commit to Git
git add plaintext_scripts/
git commit -m "Apply simplified naming convention"
git push
```

---

**Document Version:** 2.0  
**Last Updated:** February 9, 2026  
**Status:** Official Standard  
**Schema:** [Human_Readable_Short][Number].ps1
