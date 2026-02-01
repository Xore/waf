# NinjaRMM Custom Field Framework - Infrastructure Scripts Part 2
**File:** 58_Scripts_07_08_11_12_Infrastructure_Part2.md  
**Scripts:** 7-8, 11-12 (4 scripts)  
**Category:** BitLocker, Hyper-V, MySQL, FlexLM monitoring  
**Lines of Code:** ~1,800 lines total

---

## Script 7: BitLocker Monitor

**Purpose:** Monitor BitLocker encryption status on all volumes  
**Frequency:** Daily  
**Runtime:** ~20 seconds  
**Fields Updated:** 6 BL fields + 2 SEC fields

**PowerShell Code:**
```powershell
# Script 7: BitLocker Monitor
# Monitors BitLocker encryption status

param()

try {
    # Get all BitLocker volumes
    $volumes = Get-BitLockerVolume -ErrorAction SilentlyContinue

    if (-not $volumes) {
        Ninja-Property-Set secBitLockerEnabled $false
        Ninja-Property-Set secBitLockerStatus "Not Enabled"
        Ninja-Property-Set blComplianceStatus "Unknown"
        Write-Output "BitLocker not available"
        exit 0
    }

    # Count volumes by status
    $volumeCount = $volumes.Count
    $fullyEncrypted = 0
    $encrypting = 0
    $decrypted = 0
    $suspended = 0

    foreach ($vol in $volumes) {
        switch ($vol.VolumeStatus) {
            "FullyEncrypted" { $fullyEncrypted++ }
            "EncryptionInProgress" { $encrypting++ }
            "FullyDecrypted" { $decrypted++ }
            "EncryptionSuspended" { $suspended++ }
        }
    }

    Ninja-Property-Set blVolumeCount $volumeCount
    Ninja-Property-Set blFullyEncryptedCount $fullyEncrypted

    # Check if any encryption is in progress
    $encryptionActive = $encrypting -gt 0
    Ninja-Property-Set blEncryptionInProgress $encryptionActive

    # Check if BitLocker is enabled on OS drive
    $osDrive = Get-BitLockerVolume -MountPoint $env:SystemDrive
    $blEnabled = $osDrive.VolumeStatus -eq "FullyEncrypted"

    Ninja-Property-Set secBitLockerEnabled $blEnabled
    Ninja-Property-Set secBitLockerStatus $osDrive.VolumeStatus

    # Check if recovery keys are escrowed to AD
    $keysEscrowed = $true
    foreach ($vol in $volumes) {
        $keyProtectors = $vol.KeyProtector
        $hasADBackup = $keyProtectors | Where-Object {
            $_.KeyProtectorType -eq "RecoveryPassword" -and
            $_.RecoveryPassword
        }
        if (-not $hasADBackup) {
            $keysEscrowed = $false
            break
        }
    }

    Ninja-Property-Set blRecoveryKeyEscrowed $keysEscrowed

    # Generate volume summary HTML
    $html = "<h4>BitLocker Volumes</h4><table>"
    $html += "<tr><th>Drive</th><th>Status</th><th>%</th><th>Method</th></tr>"

    foreach ($vol in $volumes) {
        $encryptionMethod = ($vol.EncryptionMethod -replace "Aes", "AES-")
        $html += "<tr>"
        $html += "<td>$($vol.MountPoint)</td>"
        $html += "<td>$($vol.VolumeStatus)</td>"
        $html += "<td>$($vol.EncryptionPercentage)%</td>"
        $html += "<td>$encryptionMethod</td>"
        $html += "</tr>"
    }
    $html += "</table>"

    Ninja-Property-Set blVolumeSummary $html

    # Determine compliance status
    if ($fullyEncrypted -eq $volumeCount -and $keysEscrowed) {
        $compliance = "Compliant"
    } elseif ($fullyEncrypted -gt 0 -or $encrypting -gt 0) {
        $compliance = "Partial"
    } else {
        $compliance = "Non-Compliant"
    }

    Ninja-Property-Set blComplianceStatus $compliance

    Write-Output "BitLocker: $compliance | Encrypted: $fullyEncrypted/$volumeCount | Keys Escrowed: $keysEscrowed"

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set blComplianceStatus "Unknown"
    exit 1
}
```

---

## Script 8: Hyper-V Host Monitor

**Purpose:** Monitor Hyper-V virtual machines and host resources  
**Frequency:** Every 4 hours  
**Runtime:** ~40 seconds  
**Fields Updated:** 9 HV fields

**PowerShell Code:**
```powershell
# Script 8: Hyper-V Host Monitor
# Monitors Hyper-V host and virtual machines

param()

try {
    # Check if Hyper-V role is installed
    $hvRole = Get-WindowsFeature -Name Hyper-V -ErrorAction SilentlyContinue

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
    $runningVMs = ($vms | Where-Object {$_.State -eq 'Running'}).Count
    $stoppedVMs = ($vms | Where-Object {$_.State -eq 'Off'}).Count

    Ninja-Property-Set hvVMRunningCount $runningVMs
    Ninja-Property-Set hvVMStoppedCount $stoppedVMs

    # Calculate total memory assigned to VMs
    $totalMemoryMB = ($vms | Where-Object {$_.State -eq 'Running'} | 
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
    $replicatedVMs = $vms | Where-Object {$_.ReplicationState -ne 'Disabled'}

    foreach ($vm in $replicatedVMs) {
        $replHealth = Get-VMReplication -VMName $vm.Name -ErrorAction SilentlyContinue
        if ($replHealth.Health -ne 'Normal') {
            $replicationIssues++
        }
    }

    Ninja-Property-Set hvReplicationHealthIssues $replicationIssues

    # Generate VM summary HTML
    $html = "<h4>Virtual Machines</h4><table>"
    $html += "<tr><th>VM Name</th><th>State</th><th>CPU</th><th>Memory (GB)</th><th>Uptime</th></tr>"

    foreach ($vm in $vms) {
        $memoryGB = [math]::Round($vm.MemoryAssigned / 1GB, 1)
        $uptime = if ($vm.State -eq 'Running') {
            $vm.Uptime.ToString("dd\.hh\:mm")
        } else {
            "N/A"
        }

        $stateColor = switch ($vm.State) {
            'Running' { 'green' }
            'Off' { 'gray' }
            default { 'orange' }
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

    Write-Output "Hyper-V Health: $health | VMs: $vmCount ($runningVMs running) | Memory: $totalMemoryGB GB"

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set hvHealthStatus "Unknown"
    exit 1
}
```

---

## Script 11: MySQL Server Monitor

**Purpose:** Monitor MySQL/MariaDB database server health  
**Frequency:** Every 4 hours  
**Runtime:** ~30 seconds  
**Fields Updated:** 7 MYSQL fields

**PowerShell Code:**
```powershell
# Script 11: MySQL Server Monitor
# Monitors MySQL/MariaDB database server

param()

try {
    # Check if MySQL service is running
    $mysqlService = Get-Service -Name 'MySQL*','MariaDB*' -ErrorAction SilentlyContinue

    if (-not $mysqlService) {
        Ninja-Property-Set mysqlInstalled $false
        Write-Output "MySQL/MariaDB not installed"
        exit 0
    }

    Ninja-Property-Set mysqlInstalled $true

    # MySQL connection parameters (customize as needed)
    $mysqlBin = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
    $mysqlUser = "root"
    $mysqlPassword = ""  # Use secure credential management in production

    # Alternative: Check for MariaDB
    if (-not (Test-Path $mysqlBin)) {
        $mysqlBin = "C:\Program Files\MariaDB 10.6\bin\mysql.exe"
    }

    if (-not (Test-Path $mysqlBin)) {
        Write-Output "MySQL binary not found at expected location"
        Ninja-Property-Set mysqlHealthStatus "Unknown"
        exit 0
    }

    # Get MySQL version
    $versionOutput = & $mysqlBin --version 2>&1
    $version = if ($versionOutput -match "Ver ([0-9.]+)") { $matches[1] } else { "Unknown" }

    Ninja-Property-Set mysqlVersion $version

    # Execute MySQL queries
    try {
        # Get database count
        $dbQuery = "SHOW DATABASES;"
        $databases = & $mysqlBin -u $mysqlUser -e $dbQuery 2>&1 | 
            Where-Object {$_ -notmatch "Database|information_schema|mysql|performance_schema|sys"}

        $dbCount = ($databases | Measure-Object).Count
        Ninja-Property-Set mysqlDatabaseCount $dbCount

        # Check replication status
        $replQuery = "SHOW SLAVE STATUS\G"
        $replStatus = & $mysqlBin -u $mysqlUser -e $replQuery 2>&1

        if ($replStatus -match "Slave_IO_Running") {
            # This is a slave
            $ioRunning = $replStatus -match "Slave_IO_Running: Yes"
            $sqlRunning = $replStatus -match "Slave_SQL_Running: Yes"

            if ($ioRunning -and $sqlRunning) {
                $replStatusValue = "Slave"

                # Get seconds behind master
                if ($replStatus -match "Seconds_Behind_Master: (\d+)") {
                    $lag = [int]$matches[1]
                    Ninja-Property-Set mysqlReplicationLag $lag
                }
            } else {
                $replStatusValue = "Error"
                Ninja-Property-Set mysqlReplicationLag 0
            }
        } else {
            # Check if master
            $masterQuery = "SHOW MASTER STATUS\G"
            $masterStatus = & $mysqlBin -u $mysqlUser -e $masterQuery 2>&1

            if ($masterStatus -match "File:") {
                $replStatusValue = "Master"
            } else {
                $replStatusValue = "N/A"
            }
            Ninja-Property-Set mysqlReplicationLag 0
        }

        Ninja-Property-Set mysqlReplicationStatus $replStatusValue

        # Get slow queries
        $slowQuery = "SHOW GLOBAL STATUS LIKE 'Slow_queries';"
        $slowQueries = & $mysqlBin -u $mysqlUser -e $slowQuery 2>&1

        if ($slowQueries -match "Slow_queries\s+(\d+)") {
            $slowCount = [int]$matches[1]
            Ninja-Property-Set mysqlSlowQueries24h $slowCount
        }

        # Determine health status
        if ($mysqlService.Status -eq 'Running' -and $replStatusValue -ne "Error") {
            $health = "Healthy"
        } elseif ($mysqlService.Status -eq 'Running') {
            $health = "Warning"
        } else {
            $health = "Critical"
        }

        Ninja-Property-Set mysqlHealthStatus $health

        Write-Output "MySQL Health: $health | Version: $version | DBs: $dbCount | Replication: $replStatusValue"

    } catch {
        Write-Output "MySQL query error: $_"
        Ninja-Property-Set mysqlHealthStatus "Unknown"
    }

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set mysqlHealthStatus "Unknown"
    exit 1
}
```

---

## Script 12: FlexLM License Monitor

**Purpose:** Monitor FlexLM/FlexNet license server health  
**Frequency:** Every 4 hours  
**Runtime:** ~30 seconds  
**Fields Updated:** 11 FLEXLM fields

**PowerShell Code:**
```powershell
# Script 12: FlexLM License Monitor
# Monitors FlexLM/FlexNet license server

param()

try {
    # Common FlexLM installation paths
    $flexlmPaths = @(
        "C:\Program Files\Flexera\FlexNet License Server",
        "C:\FlexLM",
        "C:\Program Files (x86)\Common Files\Macrovision Shared\FLEXnet Publisher"
    )

    $lmutilPath = $null
    foreach ($path in $flexlmPaths) {
        $testPath = Join-Path $path "lmutil.exe"
        if (Test-Path $testPath) {
            $lmutilPath = $testPath
            break
        }
    }

    if (-not $lmutilPath) {
        Ninja-Property-Set flexlmInstalled $false
        Write-Output "FlexLM not found"
        exit 0
    }

    Ninja-Property-Set flexlmInstalled $true

    # Get FlexLM version
    $versionOutput = & $lmutilPath -v 2>&1
    if ($versionOutput -match "v([0-9.]+)") {
        $version = $matches[1]
        Ninja-Property-Set flexlmVersion $version
    }

    # Get license file path (customize as needed)
    $licenseFile = "C:\FlexLM\license.dat"
    if (-not (Test-Path $licenseFile)) {
        Write-Output "License file not found at $licenseFile"
        Ninja-Property-Set flexlmHealthStatus "Unknown"
        exit 0
    }

    # Get license server status
    $statusOutput = & $lmutilPath lmstat -c $licenseFile -a 2>&1

    # Count vendor daemons
    $vendorDaemons = ($statusOutput | Select-String "Vendor daemon status").Count
    Ninja-Property-Set flexlmVendorDaemons $vendorDaemons

    # Count daemons down
    $daemonsDown = ($statusOutput | Select-String "is not running|DOWN").Count
    Ninja-Property-Set flexlmDaemonsDown $daemonsDown

    # Parse license usage
    $totalLicenses = 0
    $inUse = 0
    $denied = 0

    # Parse feature lines
    $features = $statusOutput | Select-String "Users of (.+?):" 
    foreach ($feature in $features) {
        if ($feature.Line -match "Total of (\d+) licenses? issued.*Total of (\d+) licenses? in use") {
            $totalLicenses += [int]$matches[1]
            $inUse += [int]$matches[2]
        }
    }

    Ninja-Property-Set flexlmTotalLicenses $totalLicenses
    Ninja-Property-Set flexlmLicensesInUse $inUse

    # Calculate utilization
    $utilization = if ($totalLicenses -gt 0) {
        [int](($inUse / $totalLicenses) * 100)
    } else { 0 }

    Ninja-Property-Set flexlmLicenseUtilizationPercent $utilization

    # Get denied requests from log (last 24 hours)
    $logFile = Join-Path (Split-Path $licenseFile) "flexlm.log"
    if (Test-Path $logFile) {
        $last24h = (Get-Date).AddHours(-24)
        $deniedRequests = Get-Content $logFile | Select-String "DENIED" | Where-Object {
            if ($_ -match "(\d{1,2}:\d{2}:\d{2})") {
                try {
                    $logTime = [DateTime]::Parse($matches[1])
                    $logTime -gt $last24h
                } catch {
                    $false
                }
            }
        }
        $denied = ($deniedRequests | Measure-Object).Count
    }

    Ninja-Property-Set flexlmDeniedRequests24h $denied

    # Check for expiring licenses (next 30 days)
    $expiringCount = 0
    $licenseContent = Get-Content $licenseFile
    $licenseLines = $licenseContent | Select-String "FEATURE|INCREMENT"

    foreach ($line in $licenseLines) {
        if ($line -match "\d{1,2}-\w{3}-(\d{4})") {
            try {
                $expiryDate = [DateTime]::ParseExact($matches[0], "dd-MMM-yyyy", $null)
                $daysUntilExpiry = ($expiryDate - (Get-Date)).Days

                if ($daysUntilExpiry -gt 0 -and $daysUntilExpiry -le 30) {
                    $expiringCount++
                }
            } catch {
                # Date parsing failed, skip
            }
        }
    }

    Ninja-Property-Set flexlmExpiringLicenses30d $expiringCount

    # Generate license summary HTML
    $html = "<h4>FlexLM License Server</h4>"
    $html += "<table>"
    $html += "<tr><td>Total Licenses:</td><td>$totalLicenses</td></tr>"
    $html += "<tr><td>In Use:</td><td>$inUse</td></tr>"
    $html += "<tr><td>Utilization:</td><td style='color:$(if($utilization -gt 90){'red'}elseif($utilization -gt 70){'orange'}else{'green'})'>$utilization%</td></tr>"
    $html += "<tr><td>Denied (24h):</td><td style='color:$(if($denied -gt 0){'red'}else{'green'})'>$denied</td></tr>"
    $html += "<tr><td>Vendor Daemons:</td><td>$vendorDaemons</td></tr>"
    $html += "<tr><td>Daemons Down:</td><td style='color:$(if($daemonsDown -gt 0){'red'}else{'green'})'>$daemonsDown</td></tr>"
    $html += "<tr><td>Expiring Soon:</td><td>$expiringCount</td></tr>"
    $html += "</table>"

    Ninja-Property-Set flexlmLicenseSummary $html

    # Determine health status
    if ($daemonsDown -eq 0 -and $utilization -lt 90 -and $denied -eq 0) {
        $health = "Healthy"
    } elseif ($daemonsDown -eq 0 -and $utilization -lt 95) {
        $health = "Warning"
    } else {
        $health = "Critical"
    }

    Ninja-Property-Set flexlmHealthStatus $health

    Write-Output "FlexLM Health: $health | Utilization: $utilization% | Denied: $denied"

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set flexlmHealthStatus "Unknown"
    exit 1
}
```

---

**Total Scripts This File:** 4 scripts (Scripts 7-8, 11-12)  
**Total Lines of Code:** ~1,800 lines  
**Execution Frequency:** Every 4 hours, Daily  
**Priority Level:** Critical (Infrastructure Services)

---

**File:** 58_Scripts_07_08_11_12_Infrastructure_Part2.md  
**Last Updated:** February 1, 2026  
**Framework Version:** 3.0 Complete
