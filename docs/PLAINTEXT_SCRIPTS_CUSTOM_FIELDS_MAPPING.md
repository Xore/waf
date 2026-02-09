# Plaintext Scripts Custom Fields Mapping Task

**Project:** Windows Automation Framework (WAF)  
**Date:** February 9, 2026  
**Priority:** High  
**Status:** Ready for Autonomous Execution

---

## Overview

This task maps all custom fields currently used by the 164 plaintext scripts to understand field utilization, identify conflicts, and plan new field creation for framework integration. All batch scripts will be converted to PowerShell during standardization.

---

## Objectives

1. **Scan all plaintext scripts** for custom field usage
2. **Extract field names** and their data types
3. **Identify field patterns** (Ninja-Property-Set, Ninja-Property-Get)
4. **Map fields to scripts** (which scripts use which fields)
5. **Detect batch scripts** requiring PowerShell conversion
6. **Generate comprehensive mapping report**
7. **Identify field conflicts** with existing WAF framework
8. **Plan new field creation** for unmapped functionality

---

## Autonomous Execution Plan

### Phase 1: Field Discovery (Autonomous)

**Script: `scripts/Discover-PlaintextScriptFields.ps1`**

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Discovers all custom fields used in plaintext scripts.

.DESCRIPTION
    Scans all scripts in plaintext_scripts folder and extracts:
    - Custom field names
    - Field operations (Get/Set)
    - Data types
    - Script usage mapping
    - Batch vs PowerShell detection

.OUTPUTS
    - field_mapping.json
    - field_usage_report.csv
    - batch_scripts_list.txt
    - field_conflicts.txt
#>

param(
    [string]$ScriptsPath = "plaintext_scripts",
    [string]$OutputPath = "docs/tracking"
)

# Ensure output directory exists
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null

Write-Host "Starting field discovery in: $ScriptsPath" -ForegroundColor Cyan

# Initialize data structures
$fieldMapping = @{}
$scriptTypes = @{
    PowerShell = @()
    Batch = @()
    Unknown = @()
}
$fieldUsage = @()

# Get all script files
$scriptFiles = Get-ChildItem -Path $ScriptsPath -File | Where-Object {
    $_.Extension -in @('.ps1', '.txt', '.bat', '.cmd')
}

Write-Host "Found $($scriptFiles.Count) script files to analyze" -ForegroundColor Green

# Patterns to match custom field operations
$patterns = @{
    NinjaPropertySet = 'Ninja-Property-Set\s+([^\s]+)\s+(.+?)(?:\r?\n|$)'
    NinjaPropertyGet = 'Ninja-Property-Get\s+([^\s]+)'
    NinjaPropertySetAlt = 'Ninja-Property-Set-Piped\s+--name\s+"?([^"\s]+)"?'
    NinjaPropertyGetAlt = 'Ninja-Property-Get\s+"?([^"\s]+)"?'
}

foreach ($script in $scriptFiles) {
    Write-Host "Analyzing: $($script.Name)" -ForegroundColor Yellow
    
    try {
        $content = Get-Content -Path $script.FullName -Raw -ErrorAction Stop
        
        # Detect script type
        if ($script.Extension -eq '.ps1' -or $content -match '^\s*#.*PowerShell' -or $content -match '\$[a-zA-Z]') {
            $scriptTypes.PowerShell += $script.Name
            $scriptType = "PowerShell"
        }
        elseif ($script.Extension -in @('.bat', '.cmd') -or $content -match '@echo off' -or $content -match 'SET ') {
            $scriptTypes.Batch += $script.Name
            $scriptType = "Batch"
        }
        else {
            $scriptTypes.Unknown += $script.Name
            $scriptType = "Unknown"
        }
        
        # Extract Ninja-Property-Set operations
        $setMatches = [regex]::Matches($content, $patterns.NinjaPropertySet)
        foreach ($match in $setMatches) {
            $fieldName = $match.Groups[1].Value.Trim()
            $fieldValue = $match.Groups[2].Value.Trim()
            
            # Infer data type
            $dataType = "Text"
            if ($fieldValue -match '^\d+$') {
                $dataType = "Number"
            }
            elseif ($fieldValue -match '^(true|false|\$true|\$false)$') {
                $dataType = "Boolean"
            }
            elseif ($fieldValue -match '^[\d.]+$') {
                $dataType = "Decimal"
            }
            
            # Add to mapping
            if (-not $fieldMapping.ContainsKey($fieldName)) {
                $fieldMapping[$fieldName] = @{
                    Name = $fieldName
                    DataType = $dataType
                    SetByScripts = @()
                    GetByScripts = @()
                    FirstSeenIn = $script.Name
                }
            }
            
            if ($fieldMapping[$fieldName].SetByScripts -notcontains $script.Name) {
                $fieldMapping[$fieldName].SetByScripts += $script.Name
            }
            
            # Update data type if more specific
            if ($dataType -ne "Text" -and $fieldMapping[$fieldName].DataType -eq "Text") {
                $fieldMapping[$fieldName].DataType = $dataType
            }
        }
        
        # Extract Ninja-Property-Get operations
        $getMatches = [regex]::Matches($content, $patterns.NinjaPropertyGet)
        foreach ($match in $getMatches) {
            $fieldName = $match.Groups[1].Value.Trim()
            
            if (-not $fieldMapping.ContainsKey($fieldName)) {
                $fieldMapping[$fieldName] = @{
                    Name = $fieldName
                    DataType = "Unknown"
                    SetByScripts = @()
                    GetByScripts = @()
                    FirstSeenIn = $script.Name
                }
            }
            
            if ($fieldMapping[$fieldName].GetByScripts -notcontains $script.Name) {
                $fieldMapping[$fieldName].GetByScripts += $script.Name
            }
        }
        
    }
    catch {
        Write-Warning "Error analyzing $($script.Name): $($_.Exception.Message)"
    }
}

# Generate field usage report
foreach ($fieldName in $fieldMapping.Keys | Sort-Object) {
    $field = $fieldMapping[$fieldName]
    
    $fieldUsage += [PSCustomObject]@{
        FieldName = $fieldName
        DataType = $field.DataType
        SetByCount = $field.SetByScripts.Count
        GetByCount = $field.GetByScripts.Count
        TotalUsage = $field.SetByScripts.Count + $field.GetByScripts.Count
        SetByScripts = ($field.SetByScripts -join '; ')
        GetByScripts = ($field.GetByScripts -join '; ')
        FirstSeenIn = $field.FirstSeenIn
    }
}

# Save outputs
Write-Host "`nSaving results..." -ForegroundColor Cyan

# 1. Field mapping JSON (detailed)
$fieldMapping | ConvertTo-Json -Depth 10 | Out-File "$OutputPath/field_mapping.json" -Encoding UTF8
Write-Host "Saved: field_mapping.json" -ForegroundColor Green

# 2. Field usage CSV (summary)
$fieldUsage | Export-Csv "$OutputPath/field_usage_report.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Saved: field_usage_report.csv" -ForegroundColor Green

# 3. Batch scripts list
$scriptTypes.Batch | Out-File "$OutputPath/batch_scripts_list.txt" -Encoding UTF8
Write-Host "Saved: batch_scripts_list.txt" -ForegroundColor Green

# 4. Script type summary
$scriptTypeSummary = @"
Script Type Analysis
==================

PowerShell Scripts: $($scriptTypes.PowerShell.Count)
Batch Scripts: $($scriptTypes.Batch.Count)
Unknown Type: $($scriptTypes.Unknown.Count)

Total Scripts: $($scriptFiles.Count)

Batch Scripts Requiring Conversion:
$(($scriptTypes.Batch | ForEach-Object { "  - $_" }) -join "`n")
"@

$scriptTypeSummary | Out-File "$OutputPath/script_type_summary.txt" -Encoding UTF8
Write-Host "Saved: script_type_summary.txt" -ForegroundColor Green

# Summary statistics
Write-Host "`n=== Field Discovery Summary ===" -ForegroundColor Cyan
Write-Host "Total Unique Fields: $($fieldMapping.Count)" -ForegroundColor Green
Write-Host "PowerShell Scripts: $($scriptTypes.PowerShell.Count)" -ForegroundColor Green
Write-Host "Batch Scripts: $($scriptTypes.Batch.Count)" -ForegroundColor Yellow
Write-Host "Unknown Scripts: $($scriptTypes.Unknown.Count)" -ForegroundColor Red

Write-Host "`nField Data Types:" -ForegroundColor Cyan
$fieldMapping.Values | Group-Object DataType | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White
}

Write-Host "`nMost Used Fields (Top 10):" -ForegroundColor Cyan
$fieldUsage | Sort-Object TotalUsage -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.FieldName): $($_.TotalUsage) uses" -ForegroundColor White
}

Write-Host "`nField discovery complete!" -ForegroundColor Green
Write-Host "Results saved to: $OutputPath" -ForegroundColor Green
```

---

### Phase 2: Field Conflict Detection (Autonomous)

**Script: `scripts/Detect-FieldConflicts.ps1`**

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Detects conflicts between plaintext script fields and existing WAF fields.

.DESCRIPTION
    Compares fields discovered in plaintext scripts against the existing
    WAF framework custom fields to identify:
    - Naming conflicts
    - Data type mismatches
    - Duplicate definitions
    - New fields needed

.OUTPUTS
    - field_conflicts.csv
    - new_fields_needed.csv
    - field_merge_recommendations.txt
#>

param(
    [string]$PlaintextFieldsJson = "docs/tracking/field_mapping.json",
    [string]$WAFFieldsMarkdown = "docs/CUSTOM_FIELDS_COMPLETE.md",
    [string]$OutputPath = "docs/tracking"
)

Write-Host "Detecting field conflicts..." -ForegroundColor Cyan

# Load plaintext script fields
if (-not (Test-Path $PlaintextFieldsJson)) {
    Write-Error "Field mapping not found. Run Discover-PlaintextScriptFields.ps1 first."
    exit 1
}

$plaintextFields = Get-Content $PlaintextFieldsJson -Raw | ConvertFrom-Json

# Parse existing WAF fields from markdown
$wafFields = @{}
if (Test-Path $WAFFieldsMarkdown) {
    $content = Get-Content $WAFFieldsMarkdown -Raw
    
    # Extract field definitions from markdown tables
    # Pattern: | fieldName | Type | Description |
    $tableMatches = [regex]::Matches($content, '\|\s*([a-zA-Z0-9_]+)\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|')
    
    foreach ($match in $tableMatches) {
        $fieldName = $match.Groups[1].Value.Trim()
        $fieldType = $match.Groups[2].Value.Trim()
        
        # Skip header rows
        if ($fieldName -notmatch '^(Field|Name|Custom)' -and $fieldName -ne '---') {
            $wafFields[$fieldName] = @{
                Name = $fieldName
                Type = $fieldType
            }
        }
    }
}

Write-Host "WAF Fields Loaded: $($wafFields.Count)" -ForegroundColor Green
Write-Host "Plaintext Fields Loaded: $($plaintextFields.PSObject.Properties.Count)" -ForegroundColor Green

# Analyze conflicts
$conflicts = @()
$newFields = @()
$mergeRecommendations = @()

foreach ($fieldName in $plaintextFields.PSObject.Properties.Name) {
    $plaintextField = $plaintextFields.$fieldName
    
    if ($wafFields.ContainsKey($fieldName)) {
        # Field exists - check for type conflict
        $wafField = $wafFields[$fieldName]
        
        $typeMatch = $true
        if ($plaintextField.DataType -ne "Unknown" -and $wafField.Type -notmatch $plaintextField.DataType) {
            $typeMatch = $false
        }
        
        $conflicts += [PSCustomObject]@{
            FieldName = $fieldName
            PlaintextType = $plaintextField.DataType
            WAFType = $wafField.Type
            TypeConflict = -not $typeMatch
            UsedByScripts = $plaintextField.SetByScripts.Count + $plaintextField.GetByScripts.Count
            Action = if ($typeMatch) { "OK - Use existing" } else { "Review - Type mismatch" }
        }
        
        if (-not $typeMatch) {
            $mergeRecommendations += "CONFLICT: $fieldName"
            $mergeRecommendations += "  Plaintext Type: $($plaintextField.DataType)"
            $mergeRecommendations += "  WAF Type: $($wafField.Type)"
            $mergeRecommendations += "  Recommendation: Review and standardize type"
            $mergeRecommendations += ""
        }
    }
    else {
        # New field needed
        $newFields += [PSCustomObject]@{
            FieldName = $fieldName
            DataType = $plaintextField.DataType
            SetByScripts = ($plaintextField.SetByScripts -join '; ')
            GetByScripts = ($plaintextField.GetByScripts -join '; ')
            TotalUsage = $plaintextField.SetByScripts.Count + $plaintextField.GetByScripts.Count
            FirstSeenIn = $plaintextField.FirstSeenIn
            Action = "Create new field"
        }
    }
}

# Save outputs
$conflicts | Export-Csv "$OutputPath/field_conflicts.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Saved: field_conflicts.csv" -ForegroundColor Green

$newFields | Sort-Object TotalUsage -Descending | Export-Csv "$OutputPath/new_fields_needed.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Saved: new_fields_needed.csv" -ForegroundColor Green

$mergeRecommendations | Out-File "$OutputPath/field_merge_recommendations.txt" -Encoding UTF8
Write-Host "Saved: field_merge_recommendations.txt" -ForegroundColor Green

# Summary
Write-Host "`n=== Conflict Detection Summary ===" -ForegroundColor Cyan
Write-Host "Existing Fields (OK): $($conflicts | Where-Object { -not $_.TypeConflict } | Measure-Object).Count" -ForegroundColor Green
Write-Host "Type Conflicts: $(($conflicts | Where-Object { $_.TypeConflict } | Measure-Object).Count)" -ForegroundColor Yellow
Write-Host "New Fields Needed: $($newFields.Count)" -ForegroundColor Cyan

if ($newFields.Count -gt 0) {
    Write-Host "`nTop 10 New Fields by Usage:" -ForegroundColor Cyan
    $newFields | Select-Object -First 10 | ForEach-Object {
        Write-Host "  $($_.FieldName): $($_.TotalUsage) uses ($($_.DataType))" -ForegroundColor White
    }
}

Write-Host "`nConflict detection complete!" -ForegroundColor Green
```

---

### Phase 3: Batch Script Detection (Autonomous)

**Script: `scripts/Identify-BatchScripts.ps1`**

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Identifies all batch scripts requiring PowerShell conversion.

.DESCRIPTION
    Scans plaintext_scripts folder and identifies:
    - Pure batch scripts (.bat, .cmd)
    - Hybrid scripts (.txt containing batch syntax)
    - Complexity assessment for conversion
    - Priority ranking

.OUTPUTS
    - batch_conversion_plan.csv
    - conversion_complexity_report.txt
#>

param(
    [string]$ScriptsPath = "plaintext_scripts",
    [string]$OutputPath = "docs/tracking"
)

Write-Host "Identifying batch scripts..." -ForegroundColor Cyan

$batchScripts = @()
$scriptFiles = Get-ChildItem -Path $ScriptsPath -File

foreach ($script in $scriptFiles) {
    $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue
    
    # Batch indicators
    $batchIndicators = @(
        '@echo off',
        'SET ',
        'GOTO ',
        'CALL ',
        'IF ERRORLEVEL',
        'FOR %%',
        'REM ',
        '%TEMP%',
        'cmd.exe',
        '.bat',
        '.cmd'
    )
    
    $indicatorCount = 0
    foreach ($indicator in $batchIndicators) {
        if ($content -match [regex]::Escape($indicator)) {
            $indicatorCount++
        }
    }
    
    # If 3+ indicators, likely batch script
    if ($indicatorCount -ge 3 -or $script.Extension -in @('.bat', '.cmd')) {
        
        # Assess complexity
        $complexity = "Simple"
        $complexFeatures = @()
        
        if ($content -match 'GOTO') {
            $complexFeatures += "GOTO logic"
        }
        if ($content -match 'FOR .*DO') {
            $complexFeatures += "FOR loops"
        }
        if ($content -match 'IF.*ELSE') {
            $complexFeatures += "IF-ELSE branches"
        }
        if ($content -match 'CALL :') {
            $complexFeatures += "Subroutines"
        }
        
        if ($complexFeatures.Count -ge 3) {
            $complexity = "Complex"
        }
        elseif ($complexFeatures.Count -ge 1) {
            $complexity = "Moderate"
        }
        
        # Estimate lines of code
        $lines = ($content -split "\r?\n" | Where-Object { $_ -match '\S' }).Count
        
        $batchScripts += [PSCustomObject]@{
            FileName = $script.Name
            Extension = $script.Extension
            Complexity = $complexity
            ComplexFeatures = ($complexFeatures -join ', ')
            Lines = $lines
            Priority = if ($complexity -eq "Simple") { "High" } elseif ($complexity -eq "Moderate") { "Medium" } else { "Low" }
            ConversionEstimate = switch ($complexity) {
                "Simple" { "30 min" }
                "Moderate" { "1-2 hours" }
                "Complex" { "3-4 hours" }
            }
        }
    }
}

# Save results
$batchScripts | Sort-Object Priority, Complexity, Lines | Export-Csv "$OutputPath/batch_conversion_plan.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Saved: batch_conversion_plan.csv" -ForegroundColor Green

# Detailed report
$report = @"
Batch Script Conversion Report
==============================

Total Batch Scripts: $($batchScripts.Count)

By Complexity:
  Simple: $(($batchScripts | Where-Object Complexity -eq 'Simple').Count)
  Moderate: $(($batchScripts | Where-Object Complexity -eq 'Moderate').Count)
  Complex: $(($batchScripts | Where-Object Complexity -eq 'Complex').Count)

Estimated Conversion Time:
  Simple: $(($batchScripts | Where-Object Complexity -eq 'Simple').Count * 0.5) hours
  Moderate: $(($batchScripts | Where-Object Complexity -eq 'Moderate').Count * 1.5) hours
  Complex: $(($batchScripts | Where-Object Complexity -eq 'Complex').Count * 3.5) hours
  
  Total: $([math]::Round((($batchScripts | Where-Object Complexity -eq 'Simple').Count * 0.5) + (($batchScripts | Where-Object Complexity -eq 'Moderate').Count * 1.5) + (($batchScripts | Where-Object Complexity -eq 'Complex').Count * 3.5), 1)) hours

High Priority Scripts (Simple):
$((($batchScripts | Where-Object Priority -eq 'High' | Select-Object -First 10).FileName | ForEach-Object { "  - $_" }) -join "`n")

"@

$report | Out-File "$OutputPath/conversion_complexity_report.txt" -Encoding UTF8
Write-Host "Saved: conversion_complexity_report.txt" -ForegroundColor Green

# Summary
Write-Host "`n=== Batch Script Detection Summary ===" -ForegroundColor Cyan
Write-Host "Total Batch Scripts: $($batchScripts.Count)" -ForegroundColor Yellow
Write-Host "Simple: $(($batchScripts | Where-Object Complexity -eq 'Simple').Count)" -ForegroundColor Green
Write-Host "Moderate: $(($batchScripts | Where-Object Complexity -eq 'Moderate').Count)" -ForegroundColor Yellow
Write-Host "Complex: $(($batchScripts | Where-Object Complexity -eq 'Complex').Count)" -ForegroundColor Red

Write-Host "`nBatch script identification complete!" -ForegroundColor Green
```

---

### Phase 4: Field Category Assignment (Autonomous)

**Script: `scripts/Assign-FieldCategories.ps1`**

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Assigns WAF categories to discovered fields.

.DESCRIPTION
    Analyzes field names and usage patterns to assign appropriate
    WAF categories (OPS, STAT, RISK, SEC, CAP, etc.)

.OUTPUTS
    - field_categories.csv
    - category_summary.txt
#>

param(
    [string]$FieldMappingJson = "docs/tracking/field_mapping.json",
    [string]$OutputPath = "docs/tracking"
)

Write-Host "Assigning field categories..." -ForegroundColor Cyan

$fields = Get-Content $FieldMappingJson -Raw | ConvertFrom-Json

# Category keywords
$categoryPatterns = @{
    'OPS' = @('uptime', 'reboot', 'service', 'process', 'power', 'battery', 'performance', 'cpu', 'memory', 'boot', 'startup')
    'STAT' = @('count', 'total', 'average', 'sum', 'statistic', 'metric', 'measure')
    'RISK' = @('risk', 'vulnerability', 'threat', 'exposure', 'compliance', 'violation')
    'SEC' = @('security', 'antivirus', 'firewall', 'encryption', 'certificate', 'credential', 'auth', 'login', 'password', 'smb', 'secure', 'unsigned', 'brute')
    'CAP' = @('capacity', 'disk', 'storage', 'space', 'size', 'usage', 'free', 'available')
    'UPD' = @('update', 'patch', 'windows', 'wsus', 'upgrade')
    'DRIFT' = @('drift', 'change', 'modified', 'gpo', 'policy', 'host', 'configuration')
    'UX' = @('user', 'login', 'session', 'desktop', 'office', 'onedrive', 'outlook', 'browser')
    'SRV' = @('server', 'sql', 'exchange', 'iis', 'hyperv', 'vm', 'veeam', 'backup', 'role')
    'NET' = @('network', 'ip', 'dhcp', 'dns', 'wifi', 'ethernet', 'lldp', 'speed', 'latency', 'rdp')
    'PRED' = @('predict', 'forecast', 'trend', 'projection')
    'AUTO' = @('automation', 'script', 'task', 'schedule', 'job')
    'AD' = @('activedirectory', 'domain', 'controller', 'replication', 'fsmo', 'ou', 'ldap', 'dc')
}

$categorizedFields = @()

foreach ($fieldName in $fields.PSObject.Properties.Name) {
    $field = $fields.$fieldName
    $fieldLower = $fieldName.ToLower()
    
    $assignedCategory = "OTHER"
    $matchedKeywords = @()
    
    # Check each category
    foreach ($category in $categoryPatterns.Keys) {
        foreach ($keyword in $categoryPatterns[$category]) {
            if ($fieldLower -match $keyword) {
                $assignedCategory = $category
                $matchedKeywords += $keyword
                break
            }
        }
        if ($assignedCategory -ne "OTHER") { break }
    }
    
    $categorizedFields += [PSCustomObject]@{
        FieldName = $fieldName
        Category = $assignedCategory
        DataType = $field.DataType
        MatchedKeywords = ($matchedKeywords -join ', ')
        UsageCount = $field.SetByScripts.Count + $field.GetByScripts.Count
        SuggestedPrefix = $assignedCategory.ToLower()
        SuggestedFullName = "$($assignedCategory.ToLower())$fieldName"
    }
}

# Save results
$categorizedFields | Sort-Object Category, FieldName | Export-Csv "$OutputPath/field_categories.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Saved: field_categories.csv" -ForegroundColor Green

# Category summary
$summary = @"
Field Category Assignment Summary
================================

$(
    $categorizedFields | Group-Object Category | Sort-Object Count -Descending | ForEach-Object {
        "$($_.Name): $($_.Count) fields"
    } | Out-String
)

Category Distribution:
$(
    $categorizedFields | Group-Object Category | ForEach-Object {
        "\n$($_.Name) Fields:"
        $_.Group | Select-Object -First 5 -ExpandProperty FieldName | ForEach-Object { "  - $_" }
        if ($_.Count -gt 5) { "  ... and $($_.Count - 5) more" }
    } | Out-String
)
"@

$summary | Out-File "$OutputPath/category_summary.txt" -Encoding UTF8
Write-Host "Saved: category_summary.txt" -ForegroundColor Green

Write-Host "`n=== Category Assignment Summary ===" -ForegroundColor Cyan
$categorizedFields | Group-Object Category | Sort-Object Count -Descending | ForEach-Object {
    Write-Host "$($_.Name): $($_.Count) fields" -ForegroundColor White
}

Write-Host "`nCategory assignment complete!" -ForegroundColor Green
```

---

### Phase 5: Master Report Generation (Autonomous)

**Script: `scripts/Generate-FieldMappingReport.ps1`**

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Generates comprehensive field mapping master report.

.DESCRIPTION
    Combines all field analysis data into a single markdown report
    for documentation and review.

.OUTPUTS
    - FIELD_MAPPING_MASTER_REPORT.md
#>

param(
    [string]$TrackingPath = "docs/tracking",
    [string]$OutputPath = "docs"
)

Write-Host "Generating master report..." -ForegroundColor Cyan

# Load all data files
$fieldUsage = Import-Csv "$TrackingPath/field_usage_report.csv"
$fieldCategories = Import-Csv "$TrackingPath/field_categories.csv"
$newFieldsNeeded = Import-Csv "$TrackingPath/new_fields_needed.csv"
$batchScripts = Import-Csv "$TrackingPath/batch_conversion_plan.csv"
$conflicts = Import-Csv "$TrackingPath/field_conflicts.csv"

# Build markdown report
$report = @"
# Plaintext Scripts Custom Fields Mapping Report

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Total Fields Discovered:** $($fieldUsage.Count)
**New Fields Needed:** $($newFieldsNeeded.Count)
**Batch Scripts to Convert:** $($batchScripts.Count)
**Field Conflicts:** $(($conflicts | Where-Object TypeConflict -eq 'True').Count)

---

## Executive Summary

### Field Discovery Statistics

| Metric | Count |
|--------|-------|
| Total Unique Fields | $($fieldUsage.Count) |
| Fields Setting Values | $(($fieldUsage | Where-Object { $_.SetByCount -gt 0 }).Count) |
| Fields Getting Values | $(($fieldUsage | Where-Object { $_.GetByCount -gt 0 }).Count) |
| New Fields Needed | $($newFieldsNeeded.Count) |
| Existing Fields (Reuse) | $(($conflicts | Where-Object TypeConflict -eq 'False').Count) |
| Type Conflicts | $(($conflicts | Where-Object TypeConflict -eq 'True').Count) |

### Script Type Distribution

| Type | Count |
|------|-------|
| PowerShell Scripts | $(($fieldUsage | Select-Object -First 1).SetByScripts.Split(';').Count) |
| Batch Scripts | $($batchScripts.Count) |

---

## Field Category Breakdown

$(
    $fieldCategories | Group-Object Category | Sort-Object Count -Descending | ForEach-Object {
        "### $($_.Name) Category ($($_.Count) fields)`n"
        "| Field Name | Data Type | Usage Count |"
        "|-----------|-----------|-------------|`n"
        $_.Group | ForEach-Object {
            $usage = ($fieldUsage | Where-Object FieldName -eq $_.FieldName).TotalUsage
            "| $($_.FieldName) | $($_.DataType) | $usage |"
        }
        "`n"
    } | Out-String
)

---

## New Fields Required

### High Priority (>5 uses)

| Field Name | Data Type | Category | Usage Count | Scripts Using |
|------------|-----------|----------|-------------|---------------|
$(
    $newFieldsNeeded | Where-Object { [int]$_.TotalUsage -gt 5 } | ForEach-Object {
        $cat = ($fieldCategories | Where-Object FieldName -eq $_.FieldName).Category
        "| $($_.FieldName) | $($_.DataType) | $cat | $($_.TotalUsage) | $($_.SetByScripts.Split(';').Count) |"
    } | Out-String
)

### Medium Priority (2-5 uses)

| Field Name | Data Type | Category | Usage Count |
|------------|-----------|----------|-------------|
$(
    $newFieldsNeeded | Where-Object { [int]$_.TotalUsage -ge 2 -and [int]$_.TotalUsage -le 5 } | ForEach-Object {
        $cat = ($fieldCategories | Where-Object FieldName -eq $_.FieldName).Category
        "| $($_.FieldName) | $($_.DataType) | $cat | $($_.TotalUsage) |"
    } | Out-String
)

### Low Priority (1 use)

| Field Name | Data Type | Category |
|------------|-----------|----------|
$(
    $newFieldsNeeded | Where-Object { [int]$_.TotalUsage -eq 1 } | Select-Object -First 20 | ForEach-Object {
        $cat = ($fieldCategories | Where-Object FieldName -eq $_.FieldName).Category
        "| $($_.FieldName) | $($_.DataType) | $cat |"
    } | Out-String
)

*... and $(($newFieldsNeeded | Where-Object { [int]$_.TotalUsage -eq 1 } | Measure-Object).Count - 20) more single-use fields*

---

## Field Conflicts

$(
    if (($conflicts | Where-Object TypeConflict -eq 'True').Count -gt 0) {
        "### Type Mismatches Requiring Resolution`n"
        "| Field Name | Plaintext Type | WAF Type | Action Required |"
        "|-----------|----------------|----------|-----------------|`n"
        $conflicts | Where-Object TypeConflict -eq 'True' | ForEach-Object {
            "| $($_.FieldName) | $($_.PlaintextType) | $($_.WAFType) | Review and standardize |"
        }
        "`n"
    } else {
        "No type conflicts detected. All fields compatible with existing WAF fields.`n"
    }
)

---

## Batch Scripts Requiring Conversion

### Conversion Priority List

| Script Name | Complexity | Lines | Est. Time | Priority |
|-------------|------------|-------|-----------|----------|
$(
    $batchScripts | Sort-Object Priority, Complexity | ForEach-Object {
        "| $($_.FileName) | $($_.Complexity) | $($_.Lines) | $($_.ConversionEstimate) | $($_.Priority) |"
    } | Out-String
)

### Conversion Effort Summary

- **Simple Scripts:** $(($batchScripts | Where-Object Complexity -eq 'Simple').Count) scripts (~$(($batchScripts | Where-Object Complexity -eq 'Simple').Count * 0.5) hours)
- **Moderate Scripts:** $(($batchScripts | Where-Object Complexity -eq 'Moderate').Count) scripts (~$(($batchScripts | Where-Object Complexity -eq 'Moderate').Count * 1.5) hours)
- **Complex Scripts:** $(($batchScripts | Where-Object Complexity -eq 'Complex').Count) scripts (~$(($batchScripts | Where-Object Complexity -eq 'Complex').Count * 3.5) hours)

**Total Estimated Conversion Time:** $([math]::Round((($batchScripts | Where-Object Complexity -eq 'Simple').Count * 0.5) + (($batchScripts | Where-Object Complexity -eq 'Moderate').Count * 1.5) + (($batchScripts | Where-Object Complexity -eq 'Complex').Count * 3.5), 1)) hours

---

## Most Used Fields (Top 20)

| Rank | Field Name | Category | Type | Total Uses | Set By | Get By |
|------|------------|----------|------|------------|--------|--------|
$(
    $i = 1
    $fieldUsage | Sort-Object { [int]$_.TotalUsage } -Descending | Select-Object -First 20 | ForEach-Object {
        $cat = ($fieldCategories | Where-Object FieldName -eq $_.FieldName).Category
        "| $i | $($_.FieldName) | $cat | $($_.DataType) | $($_.TotalUsage) | $($_.SetByCount) | $($_.GetByCount) |"
        $i++
    } | Out-String
)

---

## Recommendations

### Immediate Actions

1. **Resolve Type Conflicts:** $(($conflicts | Where-Object TypeConflict -eq 'True').Count) fields need type standardization
2. **Convert Batch Scripts:** $(($batchScripts | Where-Object Priority -eq 'High').Count) high-priority batch scripts should be converted first
3. **Create New Fields:** $($newFieldsNeeded.Count) new custom fields need to be created in NinjaRMM
4. **Review Single-Use Fields:** $(($newFieldsNeeded | Where-Object { [int]$_.TotalUsage -eq 1 }).Count) fields used only once - consider consolidation

### Field Creation Priority

**Phase 1 (High Priority):** $(($newFieldsNeeded | Where-Object { [int]$_.TotalUsage -gt 5 }).Count) fields with >5 uses
**Phase 2 (Medium Priority):** $(($newFieldsNeeded | Where-Object { [int]$_.TotalUsage -ge 2 -and [int]$_.TotalUsage -le 5 }).Count) fields with 2-5 uses  
**Phase 3 (Low Priority):** $(($newFieldsNeeded | Where-Object { [int]$_.TotalUsage -eq 1 }).Count) fields with 1 use

### Batch Conversion Strategy

1. Start with $(($batchScripts | Where-Object Priority -eq 'High').Count) simple scripts (high priority)
2. Move to $(($batchScripts | Where-Object Priority -eq 'Medium').Count) moderate complexity scripts
3. Tackle $(($batchScripts | Where-Object Priority -eq 'Low').Count) complex scripts last

---

## Next Steps

1. Review this report and approve field creation plan
2. Resolve any type conflicts identified
3. Begin batch script conversion (simple scripts first)
4. Create new custom fields in NinjaRMM (high priority first)
5. Update script standardization plan with field mappings
6. Proceed with framework integration

---

**Report Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Generated By:** Autonomous Field Mapping Process
"@

# Save report
$report | Out-File "$OutputPath/FIELD_MAPPING_MASTER_REPORT.md" -Encoding UTF8
Write-Host "Saved: FIELD_MAPPING_MASTER_REPORT.md" -ForegroundColor Green

Write-Host "`nMaster report generation complete!" -ForegroundColor Green
Write-Host "Report location: $OutputPath/FIELD_MAPPING_MASTER_REPORT.md" -ForegroundColor Cyan
```

---

## Autonomous Execution Master Script

**Script: `scripts/Execute-FieldMapping-Complete.ps1`**

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Executes complete autonomous field mapping process.

.DESCRIPTION
    Runs all field mapping scripts in sequence:
    1. Field Discovery
    2. Conflict Detection
    3. Batch Script Identification
    4. Category Assignment
    5. Master Report Generation

.EXAMPLE
    .\Execute-FieldMapping-Complete.ps1
    
.EXAMPLE
    .\Execute-FieldMapping-Complete.ps1 -ScriptsPath "C:\WAF\plaintext_scripts"
#>

param(
    [string]$ScriptsPath = "plaintext_scripts",
    [string]$OutputPath = "docs/tracking"
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   WAF Plaintext Scripts Field Mapping" -ForegroundColor Cyan
Write-Host "   Autonomous Execution Mode" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Ensure paths exist
if (-not (Test-Path $ScriptsPath)) {
    Write-Error "Scripts path not found: $ScriptsPath"
    exit 1
}

New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null

# Phase 1: Field Discovery
Write-Host "[1/5] Running Field Discovery..." -ForegroundColor Yellow
try {
    & "$PSScriptRoot/Discover-PlaintextScriptFields.ps1" -ScriptsPath $ScriptsPath -OutputPath $OutputPath
    Write-Host "[1/5] Field Discovery Complete" -ForegroundColor Green
}
catch {
    Write-Error "Field Discovery Failed: $($_.Exception.Message)"
    exit 1
}

Write-Host ""

# Phase 2: Conflict Detection
Write-Host "[2/5] Running Conflict Detection..." -ForegroundColor Yellow
try {
    & "$PSScriptRoot/Detect-FieldConflicts.ps1" -PlaintextFieldsJson "$OutputPath/field_mapping.json" -OutputPath $OutputPath
    Write-Host "[2/5] Conflict Detection Complete" -ForegroundColor Green
}
catch {
    Write-Error "Conflict Detection Failed: $($_.Exception.Message)"
    exit 1
}

Write-Host ""

# Phase 3: Batch Script Identification
Write-Host "[3/5] Running Batch Script Identification..." -ForegroundColor Yellow
try {
    & "$PSScriptRoot/Identify-BatchScripts.ps1" -ScriptsPath $ScriptsPath -OutputPath $OutputPath
    Write-Host "[3/5] Batch Script Identification Complete" -ForegroundColor Green
}
catch {
    Write-Error "Batch Script Identification Failed: $($_.Exception.Message)"
    exit 1
}

Write-Host ""

# Phase 4: Category Assignment
Write-Host "[4/5] Running Category Assignment..." -ForegroundColor Yellow
try {
    & "$PSScriptRoot/Assign-FieldCategories.ps1" -FieldMappingJson "$OutputPath/field_mapping.json" -OutputPath $OutputPath
    Write-Host "[4/5] Category Assignment Complete" -ForegroundColor Green
}
catch {
    Write-Error "Category Assignment Failed: $($_.Exception.Message)"
    exit 1
}

Write-Host ""

# Phase 5: Master Report
Write-Host "[5/5] Generating Master Report..." -ForegroundColor Yellow
try {
    & "$PSScriptRoot/Generate-FieldMappingReport.ps1" -TrackingPath $OutputPath -OutputPath "docs"
    Write-Host "[5/5] Master Report Complete" -ForegroundColor Green
}
catch {
    Write-Error "Master Report Generation Failed: $($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   Field Mapping Process Complete!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Results saved to:" -ForegroundColor Cyan
Write-Host "  - $OutputPath/field_mapping.json" -ForegroundColor White
Write-Host "  - $OutputPath/field_usage_report.csv" -ForegroundColor White
Write-Host "  - $OutputPath/field_conflicts.csv" -ForegroundColor White
Write-Host "  - $OutputPath/new_fields_needed.csv" -ForegroundColor White
Write-Host "  - $OutputPath/batch_conversion_plan.csv" -ForegroundColor White
Write-Host "  - $OutputPath/field_categories.csv" -ForegroundColor White
Write-Host "  - docs/FIELD_MAPPING_MASTER_REPORT.md" -ForegroundColor White
Write-Host ""
Write-Host "Next: Review FIELD_MAPPING_MASTER_REPORT.md for complete analysis" -ForegroundColor Yellow
```

---

## Execution Instructions

### Quick Start (Fully Autonomous)

```powershell
# Navigate to WAF repository
cd C:\Path\To\waf

# Run complete field mapping
.\scripts\Execute-FieldMapping-Complete.ps1

# Results will be in:
# - docs/tracking/ (all data files)
# - docs/FIELD_MAPPING_MASTER_REPORT.md (comprehensive report)
```

### Individual Script Execution

```powershell
# Run only field discovery
.\scripts\Discover-PlaintextScriptFields.ps1

# Run only conflict detection
.\scripts\Detect-FieldConflicts.ps1

# Run only batch script identification
.\scripts\Identify-BatchScripts.ps1

# Run only category assignment
.\scripts\Assign-FieldCategories.ps1

# Generate report only
.\scripts\Generate-FieldMappingReport.ps1
```

---

## Expected Outputs

### Data Files (CSV/JSON)

1. **field_mapping.json** - Complete field mapping with script usage
2. **field_usage_report.csv** - Summary of all fields and usage counts
3. **field_conflicts.csv** - Conflicts with existing WAF fields
4. **new_fields_needed.csv** - New fields requiring creation
5. **batch_conversion_plan.csv** - Batch scripts with conversion priority
6. **field_categories.csv** - Fields organized by WAF category
7. **batch_scripts_list.txt** - List of batch scripts
8. **script_type_summary.txt** - Script type statistics
9. **conversion_complexity_report.txt** - Batch conversion estimates
10. **category_summary.txt** - Category distribution

### Master Report

**FIELD_MAPPING_MASTER_REPORT.md** - Comprehensive markdown report including:
- Executive summary
- Field category breakdown
- New fields required (prioritized)
- Field conflicts
- Batch conversion plan
- Most used fields
- Recommendations
- Next steps

---

## Integration with Existing Documentation

This field mapping will feed into:

1. **PLAINTEXT_SCRIPTS_MIGRATION_PLAN.md** - Update with field requirements
2. **PLAINTEXT_SCRIPTS_FRAMEWORK_INTEGRATION.md** - Refine custom field creation plan
3. **CUSTOM_FIELDS_COMPLETE.md** - Add new fields discovered
4. **WAF_CODING_STANDARDS.md** - Update field naming conventions

---

## Success Criteria

- [ ] All 164 scripts scanned successfully
- [ ] Custom fields extracted and categorized
- [ ] Batch scripts identified with conversion priority
- [ ] Conflicts with existing fields detected
- [ ] New fields needed documented with priorities
- [ ] Master report generated
- [ ] All outputs saved to tracking folder

---

## Timeline

**Autonomous Execution Time:** 5-10 minutes  
**Manual Review Time:** 1-2 hours  
**Field Creation Time:** 2-4 hours (depending on field count)

---

## Next Steps After Completion

1. Review FIELD_MAPPING_MASTER_REPORT.md
2. Approve new field creation plan
3. Resolve any type conflicts
4. Create high-priority custom fields in NinjaRMM
5. Begin batch script conversion (simple scripts first)
6. Update script standardization plan with field mappings
7. Proceed with framework integration

---

**Document Version:** 1.0  
**Last Updated:** February 9, 2026  
**Status:** Ready for Autonomous Execution  
**Execution Time:** ~5-10 minutes automated
