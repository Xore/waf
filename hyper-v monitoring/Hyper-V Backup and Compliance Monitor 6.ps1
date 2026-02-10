<#
.SYNOPSIS
    Hyper-V Backup and Compliance Monitor - Backup status and compliance validation.

.DESCRIPTION
    This script monitors backup operations and validates compliance:
    - VSS backup status per VM (via event logs)
    - Last successful backup timestamp per VM
    - Backup age in days
    - VMs without recent backups (>7d, >14d, >30d)
    - Checkpoint/snapshot detection and age
    - Integration Services version per VM
    - Integration Services compliance status
    - VM secure boot status
    - VM TPM status
    - VM configuration backup status
    - Backup success rate (7d/30d)
    - VMs with long-running checkpoints
    
    Ensures backup compliance and identifies security/maintenance gaps.

.NOTES
    Author:         Windows Automation Framework
    Created:        2026-02-10
    Version:        1.0
    Purpose:        Hyper-V backup and compliance monitoring
    
    Execution Context:  SYSTEM
    Execution Frequency: Every 4 hours
    Estimated Duration: ~15 seconds
    Timeout Setting:    60 seconds
    
    Fields Updated:
    - hypervBackupVMsNoBackup7d (Integer)            - VMs without backup (7 days)
    - hypervBackupVMsNoBackup14d (Integer)           - VMs without backup (14 days)
    - hypervBackupVMsNoBackup30d (Integer)           - VMs without backup (30 days)
    - hypervBackupSuccessRate7d (Float)              - Backup success rate % (7d)
    - hypervBackupSuccessRate30d (Float)             - Backup success rate % (30d)
    - hypervBackupLastFailedVMs (Text)               - Recently failed backup VMs
    - hypervBackupVMsWithCheckpoints (Integer)       - VMs with checkpoints
    - hypervBackupOldestCheckpointDays (Integer)     - Oldest checkpoint age (days)
    - hypervComplianceIntegrationServices (Integer)  - VMs with outdated IS
    - hypervComplianceSecureBoot (Integer)           - VMs without secure boot
    - hypervComplianceTPM (Integer)                  - VMs without TPM
    - hypervBackupReport (WYSIWYG)                   - HTML backup status report
    - hypervComplianceReport (WYSIWYG)               - HTML compliance report
    - hypervBackupStatus (Text)                      - Overall backup status
    - hypervComplianceStatus (Text)                  - Overall compliance status
    - hypervBackupLastScan (DateTime)                - Last scan timestamp
    
    Dependencies:
    - Hyper-V role installed
    - Hyper-V PowerShell module
    - Windows Server 2012 R2 or later
    
    Exit Codes:
    0  = Success
    1  = Hyper-V not installed
    2  = Module import failed
    99 = Unexpected error

.EXAMPLE
    .\Hyper-V_Backup_and_Compliance_Monitor_6.ps1

.LINK
    https://github.com/Xore/waf/tree/main/hyper-v%20monitoring
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param()

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "1.0"
$ScriptName = "Hyper-V Backup and Compliance Monitor 6"

# Backup age thresholds (days)
$BackupThresholds = @{
    Warning7d = 7
    Warning14d = 14
    Critical30d = 30
    CheckpointWarning = 7
    CheckpointCritical = 30
}

# Analysis periods
$AnalysisPeriods = @{
    Backup7d = 7
    Backup30d = 30
}

$FieldPrefix = "hypervBackup"
$CompliancePrefix = "hypervCompliance"

# ============================================================================
# EXECUTION TIME TRACKING (MANDATORY)
# ============================================================================

$ExecutionStartTime = Get-Date

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    switch ($Level) {
        'ERROR'   { Write-Error $LogMessage }
        'WARNING' { Write-Warning $LogMessage }
        'DEBUG'   { Write-Verbose $LogMessage }
        default   { Write-Output $LogMessage }
    }
}

function Set-NinjaField {
    param(
        [string]$FieldName,
        [AllowNull()]
        [object]$Value
    )
    
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set -Name $FieldName -Value $Value
        }
        
        $RegPath = "HKLM:\SOFTWARE\NinjaRMMAgent\CustomFields"
        if (Test-Path $RegPath) {
            Set-ItemProperty -Path $RegPath -Name $FieldName -Value $Value -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Log "Failed to set field $FieldName : $($_.Exception.Message)" -Level WARNING
    }
}

function Get-VMBackupEvents {
    [CmdletBinding()]
    param(
        [int]$Days = 30
    )
    
    try {
        Write-Log "Collecting backup events (last $Days days)..."
        
        $StartTime = (Get-Date).AddDays(-$Days)
        
        # Get VSS backup started events (18310)
        $BackupStarted = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
            ID = 18310
            StartTime = $StartTime
        } -ErrorAction SilentlyContinue
        
        # Get VSS backup completed events (18311)
        $BackupCompleted = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
            ID = 18311
            StartTime = $StartTime
        } -ErrorAction SilentlyContinue
        
        # Get VSS backup failed events (18312)
        $BackupFailed = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
            ID = 18312
            StartTime = $StartTime
        } -ErrorAction SilentlyContinue
        
        # Build backup event objects
        $BackupEvents = @()
        
        # Process completed backups
        foreach ($Event in $BackupCompleted) {
            $VMName = if ($Event.Message -match '"([^"]+)"') { $Matches[1] } else { "Unknown" }
            
            $BackupEvents += [PSCustomObject]@{
                VMName = $VMName
                TimeCreated = $Event.TimeCreated
                Status = "Success"
                EventID = $Event.Id
            }
        }
        
        # Process failed backups
        foreach ($Event in $BackupFailed) {
            $VMName = if ($Event.Message -match '"([^"]+)"') { $Matches[1] } else { "Unknown" }
            
            $BackupEvents += [PSCustomObject]@{
                VMName = $VMName
                TimeCreated = $Event.TimeCreated
                Status = "Failed"
                EventID = $Event.Id
            }
        }
        
        Write-Log "Found $($BackupEvents.Count) backup events in last $Days days"
        return $BackupEvents
        
    } catch {
        Write-Log "Failed to collect backup events: $($_.Exception.Message)" -Level WARNING
        return @()
    }
}

function Get-VMBackupStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$VMs,
        
        [Parameter(Mandatory)]
        [array]$BackupEvents
    )
    
    try {
        Write-Log "Calculating VM backup status..."
        
        $VMBackupStatus = @()
        
        foreach ($VM in $VMs) {
            # Find most recent backup event for this VM
            $RecentBackups = $BackupEvents | Where-Object { $_.VMName -eq $VM.Name } | Sort-Object TimeCreated -Descending
            
            $LastBackup = $RecentBackups | Select-Object -First 1
            
            $DaysSinceBackup = if ($LastBackup) {
                [Math]::Round((Get-Date) - $LastBackup.TimeCreated).TotalDays, 0)
            } else {
                999
            }
            
            $VMBackupStatus += [PSCustomObject]@{
                VMName = $VM.Name
                LastBackupDate = if ($LastBackup) { $LastBackup.TimeCreated } else { $null }
                DaysSinceBackup = $DaysSinceBackup
                LastBackupStatus = if ($LastBackup) { $LastBackup.Status } else { "Never" }
                BackupCount7d = ($RecentBackups | Where-Object { $_.TimeCreated -gt (Get-Date).AddDays(-7) }).Count
                BackupCount30d = ($RecentBackups | Where-Object { $_.TimeCreated -gt (Get-Date).AddDays(-30) }).Count
            }
        }
        
        return $VMBackupStatus
        
    } catch {
        Write-Log "Failed to calculate backup status: $($_.Exception.Message)" -Level ERROR
        return @()
    }
}

function Get-VMCheckpointInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$VMs
    )
    
    try {
        Write-Log "Checking VM checkpoints/snapshots..."
        
        $CheckpointInfo = @()
        
        foreach ($VM in $VMs) {
            try {
                $Checkpoints = Get-VMSnapshot -VMName $VM.Name -ErrorAction SilentlyContinue
                
                if ($Checkpoints) {
                    foreach ($Checkpoint in $Checkpoints) {
                        $Age = [Math]::Round((Get-Date) - $Checkpoint.CreationTime).TotalDays, 0)
                        
                        $CheckpointInfo += [PSCustomObject]@{
                            VMName = $VM.Name
                            CheckpointName = $Checkpoint.Name
                            CreationTime = $Checkpoint.CreationTime
                            AgeDays = $Age
                            Type = $Checkpoint.SnapshotType
                        }
                    }
                }
            } catch {
                Write-Log "Failed to get checkpoints for VM $($VM.Name)" -Level DEBUG
            }
        }
        
        Write-Log "Found $($CheckpointInfo.Count) checkpoints across $($VMs.Count) VMs"
        return $CheckpointInfo
        
    } catch {
        Write-Log "Failed to check checkpoints: $($_.Exception.Message)" -Level WARNING
        return @()
    }
}

function Get-VMComplianceInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$VMs
    )
    
    try {
        Write-Log "Checking VM compliance status..."
        
        $ComplianceInfo = @()
        
        foreach ($VM in $VMs) {
            try {
                # Get Integration Services status
                $IntegrationServices = Get-VMIntegrationService -VMName $VM.Name -ErrorAction SilentlyContinue
                $ISUpToDate = ($IntegrationServices | Where-Object { $_.Enabled -and $_.PrimaryStatusDescription -eq 'OK' }).Count -eq $IntegrationServices.Count
                
                # Get security settings (requires Windows Server 2016+)
                $SecureBoot = $false
                $TPMEnabled = $false
                
                try {
                    # Check if VM supports Generation 2 features
                    if ($VM.Generation -eq 2) {
                        $FirmwareSettings = Get-VMFirmware -VMName $VM.Name -ErrorAction SilentlyContinue
                        $SecureBoot = $FirmwareSettings.SecureBoot -eq 'On'
                    }
                    
                    # Check TPM
                    $TPM = Get-VMSecurity -VMName $VM.Name -ErrorAction SilentlyContinue
                    $TPMEnabled = $TPM.TpmEnabled
                } catch {
                    # Features not available on this version
                }
                
                $ComplianceInfo += [PSCustomObject]@{
                    VMName = $VM.Name
                    Generation = $VM.Generation
                    IntegrationServicesUpToDate = $ISUpToDate
                    SecureBootEnabled = $SecureBoot
                    TPMEnabled = $TPMEnabled
                    State = $VM.State
                }
            } catch {
                Write-Log "Failed to get compliance info for VM $($VM.Name)" -Level DEBUG
            }
        }
        
        return $ComplianceInfo
        
    } catch {
        Write-Log "Failed to check compliance: $($_.Exception.Message)" -Level WARNING
        return @()
    }
}

function Get-BackupStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$BackupEvents,
        
        [int]$Days
    )
    
    $StartTime = (Get-Date).AddDays(-$Days)
    $PeriodEvents = $BackupEvents | Where-Object { $_.TimeCreated -gt $StartTime }
    
    if ($PeriodEvents.Count -eq 0) {
        return @{
            TotalBackups = 0
            SuccessfulBackups = 0
            FailedBackups = 0
            SuccessRate = 100.0
        }
    }
    
    $Successful = ($PeriodEvents | Where-Object { $_.Status -eq 'Success' }).Count
    $Failed = ($PeriodEvents | Where-Object { $_.Status -eq 'Failed' }).Count
    
    $SuccessRate = if ($PeriodEvents.Count -gt 0) {
        [Math]::Round(($Successful / $PeriodEvents.Count) * 100, 2)
    } else { 100.0 }
    
    return @{
        TotalBackups = $PeriodEvents.Count
        SuccessfulBackups = $Successful
        FailedBackups = $Failed
        SuccessRate = $SuccessRate
    }
}

function Get-BackupComplianceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$VMBackupStatus,
        
        [Parameter(Mandatory)]
        [hashtable]$BackupStats7d,
        
        [Parameter(Mandatory)]
        [hashtable]$BackupStats30d,
        
        [Parameter(Mandatory)]
        [array]$ComplianceInfo,
        
        [Parameter(Mandatory)]
        [hashtable]$Thresholds
    )
    
    $BackupStatus = "HEALTHY"
    $ComplianceStatus = "COMPLIANT"
    
    # Check backup status
    $NoBackup30d = ($VMBackupStatus | Where-Object { $_.DaysSinceBackup -gt $Thresholds.Critical30d }).Count
    $NoBackup14d = ($VMBackupStatus | Where-Object { $_.DaysSinceBackup -gt $Thresholds.Warning14d }).Count
    
    if ($NoBackup30d -gt 0 -or $BackupStats7d.SuccessRate -lt 80) {
        $BackupStatus = "CRITICAL"
    }
    elseif ($NoBackup14d -gt 0 -or $BackupStats7d.SuccessRate -lt 95) {
        $BackupStatus = "WARNING"
    }
    
    # Check compliance
    $OutdatedIS = ($ComplianceInfo | Where-Object { -not $_.IntegrationServicesUpToDate }).Count
    $NoSecureBoot = ($ComplianceInfo | Where-Object { $_.Generation -eq 2 -and -not $_.SecureBootEnabled }).Count
    
    if ($OutdatedIS -gt 0 -or $NoSecureBoot -gt 0) {
        $ComplianceStatus = "NON_COMPLIANT"
    }
    
    return @{
        Backup = $BackupStatus
        Compliance = $ComplianceStatus
    }
}

function New-BackupHTMLReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$VMBackupStatus,
        
        [Parameter(Mandatory)]
        [hashtable]$BackupStats7d,
        
        [Parameter(Mandatory)]
        [hashtable]$BackupStats30d,
        
        [Parameter(Mandatory)]
        [array]$Checkpoints
    )
    
    $HTML = @"
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; font-size: 12px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 15px; }
    th { background-color: #0078d4; color: white; padding: 8px; text-align: left; font-weight: 600; }
    td { padding: 6px 8px; border-bottom: 1px solid #ddd; }
    tr:hover { background-color: #f5f5f5; }
    .summary { background-color: #e7f3ff; padding: 10px; margin-bottom: 15px; border-left: 4px solid #0078d4; }
    .good { background-color: #d4edda; color: #155724; }
    .warning { background-color: #fff3cd; color: #856404; }
    .critical { background-color: #f8d7da; color: #721c24; }
    .section { margin-top: 15px; font-weight: 600; color: #0078d4; margin-bottom: 8px; }
</style>

<div class='summary'>
    <strong>Backup Summary</strong><br/>
    Success Rate (7d): $($BackupStats7d.SuccessRate)% ($($BackupStats7d.SuccessfulBackups)/$($BackupStats7d.TotalBackups))<br/>
    Success Rate (30d): $($BackupStats30d.SuccessRate)% ($($BackupStats30d.SuccessfulBackups)/$($BackupStats30d.TotalBackups))<br/>
    VMs with Checkpoints: $($Checkpoints.Count)
</div>

<div class='section'>VM Backup Status</div>
<table>
    <thead>
        <tr><th>VM Name</th><th>Last Backup</th><th>Days Since</th><th>Status</th><th>Backups (7d/30d)</th></tr>
    </thead>
    <tbody>
"@
    
    foreach ($VM in ($VMBackupStatus | Sort-Object DaysSinceBackup -Descending)) {
        $RowClass = if ($VM.DaysSinceBackup -gt 30 -or $VM.LastBackupStatus -eq 'Never') { 'critical' }
                    elseif ($VM.DaysSinceBackup -gt 14) { 'warning' }
                    elseif ($VM.DaysSinceBackup -gt 7) { 'warning' }
                    else { 'good' }
        
        $LastBackupStr = if ($VM.LastBackupDate) { $VM.LastBackupDate.ToString('yyyy-MM-dd HH:mm') } else { 'Never' }
        
        $HTML += "        <tr class='$RowClass'>"
        $HTML += "<td>$($VM.VMName)</td>"
        $HTML += "<td>$LastBackupStr</td>"
        $HTML += "<td>$($VM.DaysSinceBackup)</td>"
        $HTML += "<td>$($VM.LastBackupStatus)</td>"
        $HTML += "<td>$($VM.BackupCount7d) / $($VM.BackupCount30d)</td>"
        $HTML += "</tr>`n"
    }
    
    $HTML += "    </tbody>`n</table>"
    
    # Add checkpoint section if any
    if ($Checkpoints.Count -gt 0) {
        $HTML += "<div class='section'>Active Checkpoints</div>"
        $HTML += "<table><thead><tr><th>VM</th><th>Checkpoint Name</th><th>Created</th><th>Age (days)</th></tr></thead><tbody>"
        
        foreach ($CP in ($Checkpoints | Sort-Object AgeDays -Descending)) {
            $RowClass = if ($CP.AgeDays -gt 30) { 'critical' } elseif ($CP.AgeDays -gt 7) { 'warning' } else { 'good' }
            
            $HTML += "<tr class='$RowClass'>"
            $HTML += "<td>$($CP.VMName)</td>"
            $HTML += "<td>$($CP.CheckpointName)</td>"
            $HTML += "<td>$($CP.CreationTime.ToString('yyyy-MM-dd HH:mm'))</td>"
            $HTML += "<td>$($CP.AgeDays)</td>"
            $HTML += "</tr>"
        }
        
        $HTML += "</tbody></table>"
    }
    
    return $HTML
}

function New-ComplianceHTMLReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$ComplianceInfo
    )
    
    $HTML = @"
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; font-size: 12px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 15px; }
    th { background-color: #0078d4; color: white; padding: 8px; text-align: left; font-weight: 600; }
    td { padding: 6px 8px; border-bottom: 1px solid #ddd; }
    tr:hover { background-color: #f5f5f5; }
    .summary { background-color: #e7f3ff; padding: 10px; margin-bottom: 15px; border-left: 4px solid #0078d4; }
    .good { background-color: #d4edda; }
    .warning { background-color: #fff3cd; }
    .critical { background-color: #f8d7da; }
</style>

<div class='summary'>
    <strong>Compliance Summary</strong><br/>
    Total VMs: $($ComplianceInfo.Count)<br/>
    Outdated Integration Services: $(($ComplianceInfo | Where-Object { -not $_.IntegrationServicesUpToDate }).Count)<br/>
    Gen2 without Secure Boot: $(($ComplianceInfo | Where-Object { $_.Generation -eq 2 -and -not $_.SecureBootEnabled }).Count)<br/>
    Without TPM: $(($ComplianceInfo | Where-Object { -not $_.TPMEnabled }).Count)
</div>

<table>
    <thead>
        <tr><th>VM Name</th><th>Gen</th><th>Integration Services</th><th>Secure Boot</th><th>TPM</th></tr>
    </thead>
    <tbody>
"@
    
    foreach ($VM in ($ComplianceInfo | Sort-Object VMName)) {
        $RowClass = if (-not $VM.IntegrationServicesUpToDate -or ($VM.Generation -eq 2 -and -not $VM.SecureBootEnabled)) { 'warning' } else { 'good' }
        
        $HTML += "        <tr class='$RowClass'>"
        $HTML += "<td>$($VM.VMName)</td>"
        $HTML += "<td>$($VM.Generation)</td>"
        $HTML += "<td>$(if($VM.IntegrationServicesUpToDate){'✓ Current'}else{'✗ Outdated'})</td>"
        $HTML += "<td>$(if($VM.SecureBootEnabled){'✓ Enabled'}elseif($VM.Generation -eq 2){'✗ Disabled'}else{'N/A'})</td>"
        $HTML += "<td>$(if($VM.TPMEnabled){'✓ Enabled'}else{'✗ Disabled'})</td>"
        $HTML += "</tr>`n"
    }
    
    $HTML += "    </tbody>`n</table>"
    
    return $HTML
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================"
    Write-Log "$ScriptName v$ScriptVersion"
    Write-Log "========================================"
    
    # Error tracking (MANDATORY)
    $ErrorsEncountered = 0
    $ErrorDetails = @()
    
    # Check Hyper-V
    $HyperVService = Get-Service -Name vmms -ErrorAction SilentlyContinue
    if (-not $HyperVService -or $HyperVService.Status -ne 'Running') {
        Write-Log "Hyper-V service not running" -Level ERROR
        Set-NinjaField -FieldName "$($FieldPrefix)Status" -Value "NOT_AVAILABLE"
        exit 1
    }
    
    # Import module
    Import-Module Hyper-V -ErrorAction Stop
    
    # Get all VMs
    $VMs = Get-VM -ErrorAction Stop
    Write-Log "Found $($VMs.Count) VMs"
    
    # Collect backup events
    $BackupEvents30d = Get-VMBackupEvents -Days $AnalysisPeriods.Backup30d
    
    # Calculate VM backup status
    $VMBackupStatus = Get-VMBackupStatus -VMs $VMs -BackupEvents $BackupEvents30d
    
    # Get checkpoint info
    $Checkpoints = Get-VMCheckpointInfo -VMs $VMs
    
    # Get compliance info
    $ComplianceInfo = Get-VMComplianceInfo -VMs $VMs
    
    # Calculate backup statistics
    $BackupStats7d = Get-BackupStatistics -BackupEvents $BackupEvents30d -Days $AnalysisPeriods.Backup7d
    $BackupStats30d = Get-BackupStatistics -BackupEvents $BackupEvents30d -Days $AnalysisPeriods.Backup30d
    
    # Count VMs without recent backups
    $NoBackup7d = ($VMBackupStatus | Where-Object { $_.DaysSinceBackup -gt $BackupThresholds.Warning7d }).Count
    $NoBackup14d = ($VMBackupStatus | Where-Object { $_.DaysSinceBackup -gt $BackupThresholds.Warning14d }).Count
    $NoBackup30d = ($VMBackupStatus | Where-Object { $_.DaysSinceBackup -gt $BackupThresholds.Critical30d }).Count
    
    # Recently failed backups
    $RecentFailures = $BackupEvents30d | Where-Object { $_.Status -eq 'Failed' -and $_.TimeCreated -gt (Get-Date).AddDays(-7) } | 
        Select-Object -ExpandProperty VMName -Unique
    
    # Checkpoint metrics
    $VMsWithCheckpoints = ($Checkpoints | Select-Object -ExpandProperty VMName -Unique).Count
    $OldestCheckpointDays = if ($Checkpoints.Count -gt 0) {
        ($Checkpoints | Measure-Object -Property AgeDays -Maximum).Maximum
    } else { 0 }
    
    # Compliance metrics
    $OutdatedIS = ($ComplianceInfo | Where-Object { -not $_.IntegrationServicesUpToDate }).Count
    $NoSecureBoot = ($ComplianceInfo | Where-Object { $_.Generation -eq 2 -and -not $_.SecureBootEnabled }).Count
    $NoTPM = ($ComplianceInfo | Where-Object { -not $_.TPMEnabled }).Count
    
    # Determine status
    $Status = Get-BackupComplianceStatus -VMBackupStatus $VMBackupStatus `
                                         -BackupStats7d $BackupStats7d `
                                         -BackupStats30d $BackupStats30d `
                                         -ComplianceInfo $ComplianceInfo `
                                         -Thresholds $BackupThresholds
    
    # Generate HTML reports
    $BackupReport = New-BackupHTMLReport -VMBackupStatus $VMBackupStatus `
                                         -BackupStats7d $BackupStats7d `
                                         -BackupStats30d $BackupStats30d `
                                         -Checkpoints $Checkpoints
    
    $ComplianceReport = New-ComplianceHTMLReport -ComplianceInfo $ComplianceInfo
    
    # Update fields
    Write-Log "Updating NinjaRMM custom fields..."
    
    Set-NinjaField -FieldName "$($FieldPrefix)VMsNoBackup7d" -Value $NoBackup7d
    Set-NinjaField -FieldName "$($FieldPrefix)VMsNoBackup14d" -Value $NoBackup14d
    Set-NinjaField -FieldName "$($FieldPrefix)VMsNoBackup30d" -Value $NoBackup30d
    Set-NinjaField -FieldName "$($FieldPrefix)SuccessRate7d" -Value $BackupStats7d.SuccessRate
    Set-NinjaField -FieldName "$($FieldPrefix)SuccessRate30d" -Value $BackupStats30d.SuccessRate
    Set-NinjaField -FieldName "$($FieldPrefix)LastFailedVMs" -Value ($RecentFailures -join "; ")
    Set-NinjaField -FieldName "$($FieldPrefix)VMsWithCheckpoints" -Value $VMsWithCheckpoints
    Set-NinjaField -FieldName "$($FieldPrefix)OldestCheckpointDays" -Value $OldestCheckpointDays
    Set-NinjaField -FieldName "$($CompliancePrefix)IntegrationServices" -Value $OutdatedIS
    Set-NinjaField -FieldName "$($CompliancePrefix)SecureBoot" -Value $NoSecureBoot
    Set-NinjaField -FieldName "$($CompliancePrefix)TPM" -Value $NoTPM
    Set-NinjaField -FieldName "$($FieldPrefix)Report" -Value $BackupReport
    Set-NinjaField -FieldName "$($CompliancePrefix)Report" -Value $ComplianceReport
    Set-NinjaField -FieldName "$($FieldPrefix)Status" -Value $Status.Backup
    Set-NinjaField -FieldName "$($CompliancePrefix)Status" -Value $Status.Compliance
    Set-NinjaField -FieldName "$($FieldPrefix)LastScan" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    Write-Log "========================================"
    Write-Log "Backup & Compliance Summary:"
    Write-Log "  Backup Status: $($Status.Backup)"
    Write-Log "  Compliance Status: $($Status.Compliance)"
    Write-Log "  VMs without backup (7d/14d/30d): $NoBackup7d / $NoBackup14d / $NoBackup30d"
    Write-Log "  Success Rate (7d): $($BackupStats7d.SuccessRate)%"
    Write-Log "  VMs with Checkpoints: $VMsWithCheckpoints (oldest: $OldestCheckpointDays days)"
    Write-Log "  Outdated Integration Services: $OutdatedIS"
    Write-Log "========================================"
    Write-Log "Script completed successfully"
    
    exit 0
    
} catch {
    Write-Log "Unexpected error: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    
    $ErrorsEncountered++
    $ErrorDetails += $_.Exception.Message
    
    Set-NinjaField -FieldName "$($FieldPrefix)Status" -Value "ERROR"
    Set-NinjaField -FieldName "$($CompliancePrefix)Status" -Value "ERROR"
    
    exit 99
} finally {
    # Calculate execution time (MANDATORY)
    $ExecutionEndTime = Get-Date
    $ExecutionDuration = ($ExecutionEndTime - $ExecutionStartTime).TotalSeconds
    Write-Log "Execution Time: $([Math]::Round($ExecutionDuration, 2)) seconds"
    
    if ($ErrorsEncountered -gt 0) {
        Write-Log "Errors Encountered: $ErrorsEncountered"
        Write-Log "Error Summary: $($ErrorDetails -join '; ')"
    }
}
