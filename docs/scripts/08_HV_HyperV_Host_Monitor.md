# Script 08: HV Hyper-V Host Monitor

**File:** Script_08_HV_HyperV_Host_Monitor.md  
**Version:** v1.0  
**Script Number:** 08  
**Category:** Infrastructure Monitoring - Virtualization  
**Last Updated:** February 2, 2026

---

## Purpose

Monitor Hyper-V virtual machines and host resources.

---

## Execution Details

- **Frequency:** Every 4 hours
- **Runtime:** ~40 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Fields Updated

- HVHyperVInstalled (Checkbox)
- HVVMCount (Integer)
- HVVMRunningCount (Integer)
- HVVMStoppedCount (Integer)
- HVMemoryAssignedGB (Integer)
- HVStorageUsedGB (Integer)
- HVReplicationHealthIssues (Integer)
- HVVMSummary (Text/HTML)
- HVHealthStatus (Dropdown: Healthy, Warning, Critical, Unknown)

---

## PowerShell Implementation

```powershell
# Script 8: Hyper-V Host Monitor
# Monitors Hyper-V host and virtual machines

param()

try {
    Write-Output "Starting Hyper-V Host Monitor (v1.0)"

    # Check if Hyper-V role is installed
    $hvRole = Get-WindowsFeature -Name "Hyper-V" -ErrorAction SilentlyContinue

    if (-not $hvRole -or -not $hvRole.Installed) {
        Ninja-Property-Set hvHyperVInstalled $false
        Write-Output "Hyper-V role not installed"
        exit 0
    }

    Ninja-Property-Set hvHyperVInstalled $true

    # Import Hyper-V module
    Import-Module Hyper-V -ErrorAction Stop

    # Get all VMs
    $vms = Get-VM -ErrorAction SilentlyContinue
    $vmCount = $vms.Count
    Ninja-Property-Set hvVMCount $vmCount

    # Count VMs by state
    $runningVMs = ($vms | Where-Object {$_.State -eq "Running"}).Count
    $stoppedVMs = ($vms | Where-Object {$_.State -eq "Off"}).Count

    Ninja-Property-Set hvVMRunningCount $runningVMs
    Ninja-Property-Set hvVMStoppedCount $stoppedVMs

    # Calculate total memory assigned to VMs
    $totalMemoryMB = ($vms | Where-Object {$_.State -eq "Running"} | 
        Measure-Object -Property MemoryAssigned -Sum).Sum / 1MB
    $totalMemoryGB = [math]::Round($totalMemoryMB / 1024, 2)
    Ninja-Property-Set hvMemoryAssignedGB ([int]$totalMemoryGB)

    # Calculate total VM storage
    $totalStorageGB = 0
    foreach ($vm in $vms) {
        $vhds = Get-VMHardDiskDrive -VMName $vm.Name -ErrorAction SilentlyContinue
        foreach ($vhd in $vhds) {
            if (Test-Path $vhd.Path) {
                $size = (Get-Item $vhd.Path).Length / 1GB
                $totalStorageGB += $size
            }
        }
    }
    Ninja-Property-Set hvStorageUsedGB ([int]$totalStorageGB)

    # Check replication health
    $replicationIssues = 0
    $replicatedVMs = $vms | Where-Object {$_.ReplicationState -ne "Disabled"}
    foreach ($vm in $replicatedVMs) {
        $replHealth = Get-VMReplication -VMName $vm.Name -ErrorAction SilentlyContinue
        if ($replHealth.Health -ne "Normal") {
            $replicationIssues++
        }
    }
    Ninja-Property-Set hvReplicationHealthIssues $replicationIssues

    # Generate VM summary HTML
    $html = "<h4>Virtual Machines</h4><table>"
    $html += "<tr><th>VM Name</th><th>State</th><th>CPU</th><th>Memory (GB)</th><th>Uptime</th></tr>"

    foreach ($vm in $vms) {
        $memoryGB = [math]::Round($vm.MemoryAssigned / 1GB, 1)
        $uptime = if ($vm.State -eq "Running") {
            $vm.Uptime.ToString("dd\.hh\:mm")
        } else {
            "N/A"
        }

        $stateColor = switch ($vm.State) {
            "Running" { "green" }
            "Off" { "gray" }
            default { "orange" }
        }

        $html += "<tr>"
        $html += "<td>$($vm.Name)</td>"
        $html += "<td style='color:$stateColor'>$($vm.State)</td>"
        $html += "<td>$($vm.ProcessorCount)</td>"
        $html += "<td>$memoryGB</td>"
        $html += "<td>$uptime</td>"
        $html += "</tr>"
    }
    $html += "</table>"
    Ninja-Property-Set hvVMSummary $html

    # Determine health status
    if ($replicationIssues -eq 0 -and $stoppedVMs -eq 0) {
        $health = "Healthy"
    } elseif ($replicationIssues -le 2 -and $stoppedVMs -le 2) {
        $health = "Warning"
    } else {
        $health = "Critical"
    }
    Ninja-Property-Set hvHealthStatus $health

    Write-Output "SUCCESS: Hyper-V Health: $health"
    Write-Output "  VMs: $vmCount ($runningVMs running)"
    Write-Output "  Memory: $totalMemoryGB GB"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set hvHealthStatus "Unknown"
    exit 1
}
```

---

## Related Documentation

- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_08_HV_HyperV_Host_Monitor.md  
**Version:** v1.0  
**Status:** Production Ready
