#Requires -Version 5.1

<#
.SYNOPSIS
    Script 6: Telemetry Collector - Collects system telemetry data for STAT Custom Fields
    
.DESCRIPTION
    This script collects Windows Event Log data and system metrics to populate 6 STAT custom fields:
    - STATAppCrashes24h: Application crashes in last 24 hours (Event ID 1000, 1001)
    - STATAppHangs24h: Application hangs in last 24 hours (Event ID 1002)
    - STATServiceFailures24h: Service failures in last 24 hours (Event ID 7031, 7034)
    - STATBSODCount30d: Blue screens in last 30 days (Event ID 1001, 41)
    - STATUptimeDays: Days since last reboot
    - STATLastTelemetryUpdate: Timestamp of collection (ISO 8601 format)
    
.NOTES
    Version: 1.1
    Author: NinjaRMM Framework
    Created: February 1, 2026
    Updated: February 2, 2026 - Fixed DateTime format to ISO 8601
    Update Frequency: Every 4 hours (recommended)
    
.EXAMPLE
    .\Script6_TelemetryCollector.ps1
    Collects all telemetry data and updates custom fields
#>

[CmdletBinding()]
param()

# Error handling
$ErrorActionPreference = 'Stop'

try {
    Write-Host "=== STAT Telemetry Collector v1.1 ===" -ForegroundColor Cyan
    Write-Host "Starting telemetry collection at $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')" -ForegroundColor Green
    
    # ============================================
    # 1. STATAppCrashes24h - Application Crashes
    # ============================================
    Write-Host "`n[1/6] Collecting Application Crashes (last 24h)..." -ForegroundColor Yellow
    
    $24HoursAgo = (Get-Date).AddHours(-24)
    
    $AppCrashes = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1000, 1001
        StartTime = $24HoursAgo
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($null -eq $AppCrashes) { $AppCrashes = 0 }
    
    Write-Host "  Found: $AppCrashes application crashes" -ForegroundColor White
    Ninja-Property-Set -Name "STATAppCrashes24h" -Value $AppCrashes
    
    # ============================================
    # 2. STATAppHangs24h - Application Hangs
    # ============================================
    Write-Host "`n[2/6] Collecting Application Hangs (last 24h)..." -ForegroundColor Yellow
    
    $AppHangs = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1002
        StartTime = $24HoursAgo
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($null -eq $AppHangs) { $AppHangs = 0 }
    
    Write-Host "  Found: $AppHangs application hangs" -ForegroundColor White
    Ninja-Property-Set -Name "STATAppHangs24h" -Value $AppHangs
    
    # ============================================
    # 3. STATServiceFailures24h - Service Failures
    # ============================================
    Write-Host "`n[3/6] Collecting Service Failures (last 24h)..." -ForegroundColor Yellow
    
    $ServiceFailures = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ID = 7031, 7034
        StartTime = $24HoursAgo
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($null -eq $ServiceFailures) { $ServiceFailures = 0 }
    
    Write-Host "  Found: $ServiceFailures service failures" -ForegroundColor White
    Ninja-Property-Set -Name "STATServiceFailures24h" -Value $ServiceFailures
    
    # ============================================
    # 4. STATBSODCount30d - Blue Screens
    # ============================================
    Write-Host "`n[4/6] Collecting Blue Screens (last 30 days)..." -ForegroundColor Yellow
    
    $30DaysAgo = (Get-Date).AddDays(-30)
    
    # Event ID 1001 (BugCheck) and 41 (Kernel-Power unexpected shutdown)
    $BSODCount = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ID = 1001, 41
        StartTime = $30DaysAgo
    } -ErrorAction SilentlyContinue | 
    Where-Object { 
        $_.Id -eq 1001 -or 
        ($_.Id -eq 41 -and $_.Properties[0].Value -eq 0) 
    } | 
    Measure-Object | 
    Select-Object -ExpandProperty Count
    
    if ($null -eq $BSODCount) { $BSODCount = 0 }
    
    Write-Host "  Found: $BSODCount blue screens" -ForegroundColor White
    Ninja-Property-Set -Name "STATBSODCount30d" -Value $BSODCount
    
    # ============================================
    # 5. STATUptimeDays - System Uptime
    # ============================================
    Write-Host "`n[5/6] Calculating System Uptime..." -ForegroundColor Yellow
    
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem
    $LastBootTime = $OS.LastBootUpTime
    $Uptime = (Get-Date) - $LastBootTime
    $UptimeDays = [Math]::Floor($Uptime.TotalDays)
    
    Write-Host "  Last Boot: $($LastBootTime.ToString('yyyy-MM-ddTHH:mm:ss'))" -ForegroundColor White
    Write-Host "  Uptime: $UptimeDays days" -ForegroundColor White
    
    Ninja-Property-Set -Name "STATUptimeDays" -Value $UptimeDays
    
    # ============================================
    # 6. STATLastTelemetryUpdate - Timestamp
    # ============================================
    Write-Host "`n[6/6] Setting Telemetry Timestamp..." -ForegroundColor Yellow
    
    # CRITICAL: NinjaRMM requires ISO 8601 format with "T" separator
    $Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    Write-Host "  Timestamp: $Timestamp" -ForegroundColor White
    
    Ninja-Property-Set -Name "STATLastTelemetryUpdate" -Value $Timestamp
    
    # ============================================
    # Summary
    # ============================================
    Write-Host "`n=== Telemetry Collection Summary ===" -ForegroundColor Cyan
    Write-Host "App Crashes (24h):      $AppCrashes" -ForegroundColor White
    Write-Host "App Hangs (24h):        $AppHangs" -ForegroundColor White
    Write-Host "Service Failures (24h): $ServiceFailures" -ForegroundColor White
    Write-Host "BSODs (30d):            $BSODCount" -ForegroundColor White
    Write-Host "Uptime (days):          $UptimeDays" -ForegroundColor White
    Write-Host "Last Update:            $Timestamp" -ForegroundColor White
    
    Write-Host "`n✓ All STAT fields updated successfully!" -ForegroundColor Green
    exit 0
    
} catch {
    Write-Host "`n✗ ERROR: Telemetry collection failed!" -ForegroundColor Red
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    exit 1
}
