#Requires -Version 5.1

<#
.SYNOPSIS
    STAT Field Validator - Validates all STAT custom fields
    
.DESCRIPTION
    This script validates that all 6 STAT custom fields are properly populated
    and alerts if any fields are missing or outdated.
    
.NOTES
    Version: 1.0
    Author: NinjaRMM Framework
    Created: February 1, 2026
#>

[CmdletBinding()]
param(
    [Parameter()]
    [int]$MaxAgeHours = 8  # Alert if last update is older than 8 hours
)

try {
    Write-Host "=== STAT Field Validator ===" -ForegroundColor Cyan
    
    $ValidationErrors = @()
    $ValidationWarnings = @()
    
    # Check STATAppCrashes24h
    if ($null -eq $env:STATAppCrashes24h) {
        $ValidationErrors += "STATAppCrashes24h is not set"
    } elseif ($env:STATAppCrashes24h -notmatch '^\d+$') {
        $ValidationErrors += "STATAppCrashes24h has invalid format: $env:STATAppCrashes24h"
    } else {
        Write-Host "✓ STATAppCrashes24h: $env:STATAppCrashes24h" -ForegroundColor Green
    }
    
    # Check STATAppHangs24h
    if ($null -eq $env:STATAppHangs24h) {
        $ValidationErrors += "STATAppHangs24h is not set"
    } elseif ($env:STATAppHangs24h -notmatch '^\d+$') {
        $ValidationErrors += "STATAppHangs24h has invalid format: $env:STATAppHangs24h"
    } else {
        Write-Host "✓ STATAppHangs24h: $env:STATAppHangs24h" -ForegroundColor Green
    }
    
    # Check STATServiceFailures24h
    if ($null -eq $env:STATServiceFailures24h) {
        $ValidationErrors += "STATServiceFailures24h is not set"
    } elseif ($env:STATServiceFailures24h -notmatch '^\d+$') {
        $ValidationErrors += "STATServiceFailures24h has invalid format: $env:STATServiceFailures24h"
    } else {
        Write-Host "✓ STATServiceFailures24h: $env:STATServiceFailures24h" -ForegroundColor Green
    }
    
    # Check STATBSODCount30d
    if ($null -eq $env:STATBSODCount30d) {
        $ValidationErrors += "STATBSODCount30d is not set"
    } elseif ($env:STATBSODCount30d -notmatch '^\d+$') {
        $ValidationErrors += "STATBSODCount30d has invalid format: $env:STATBSODCount30d"
    } else {
        Write-Host "✓ STATBSODCount30d: $env:STATBSODCount30d" -ForegroundColor Green
    }
    
    # Check STATUptimeDays
    if ($null -eq $env:STATUptimeDays) {
        $ValidationErrors += "STATUptimeDays is not set"
    } elseif ($env:STATUptimeDays -notmatch '^\d+$') {
        $ValidationErrors += "STATUptimeDays has invalid format: $env:STATUptimeDays"
    } else {
        Write-Host "✓ STATUptimeDays: $env:STATUptimeDays" -ForegroundColor Green
    }
    
    # Check STATLastTelemetryUpdate
    if ($null -eq $env:STATLastTelemetryUpdate) {
        $ValidationErrors += "STATLastTelemetryUpdate is not set"
    } else {
        try {
            $LastUpdate = [DateTime]::ParseExact($env:STATLastTelemetryUpdate, "yyyy-MM-dd HH:mm:ss", $null)
            $HoursSinceUpdate = ((Get-Date) - $LastUpdate).TotalHours
            
            if ($HoursSinceUpdate -gt $MaxAgeHours) {
                $ValidationWarnings += "Last telemetry update is $([Math]::Round($HoursSinceUpdate, 1)) hours old (threshold: $MaxAgeHours hours)"
            } else {
                Write-Host "✓ STATLastTelemetryUpdate: $env:STATLastTelemetryUpdate ($([Math]::Round($HoursSinceUpdate, 1))h ago)" -ForegroundColor Green
            }
        } catch {
            $ValidationErrors += "STATLastTelemetryUpdate has invalid format: $env:STATLastTelemetryUpdate"
        }
    }
    
    # Report Results
    Write-Host "`n=== Validation Results ===" -ForegroundColor Cyan
    
    if ($ValidationErrors.Count -eq 0 -and $ValidationWarnings.Count -eq 0) {
        Write-Host "✓ All STAT fields are valid and up-to-date!" -ForegroundColor Green
        exit 0
    } else {
        if ($ValidationErrors.Count -gt 0) {
            Write-Host "`n✗ ERRORS ($($ValidationErrors.Count)):" -ForegroundColor Red
            $ValidationErrors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        }
        
        if ($ValidationWarnings.Count -gt 0) {
            Write-Host "`n⚠ WARNINGS ($($ValidationWarnings.Count)):" -ForegroundColor Yellow
            $ValidationWarnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        }
        
        if ($ValidationErrors.Count -gt 0) {
            exit 1
        } else {
            exit 0
        }
    }
    
} catch {
    Write-Host "`n✗ Validation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
