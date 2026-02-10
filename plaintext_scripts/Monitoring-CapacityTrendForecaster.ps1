#Requires -Version 5.1

<#
.SYNOPSIS
    Forecasts resource exhaustion and tracks long-term capacity utilization trends.

.DESCRIPTION
    Advanced capacity planning tool that tracks historical disk, memory, and CPU utilization patterns.
    Uses linear regression to predict when disk space will be exhausted and identifies utilization trends.
    
    Key Features:
    - Historical tracking of disk usage with growth prediction
    - Memory utilization trend analysis (Stable/Increasing/Decreasing/Volatile)
    - CPU utilization trend analysis with coefficient of variation
    - Health score calculation based on multiple capacity factors
    - Base64-encoded JSON storage in NinjaRMM custom fields
    - Test mode for validation using stored historical data
    - Multi-language performance counter support (English/German)
    
    Metrics Tracked:
    - Disk: Growth rate (GB/day), days until full, free space percentage
    - Memory: Average utilization, trend direction, weekly growth rate
    - CPU: Average utilization, trend direction, volatility (CV)
    - Health: Composite score (0-100) based on all capacity metrics

.PARAMETER Testrun
    Enable test mode to validate calculations using only historical Base64 data.
    Set to 'True' to run in test mode without updating current values.
    Default: $false (normal operation)

.EXAMPLE
    Monitoring-CapacityTrendForecaster.ps1
    Runs capacity analysis with current system metrics and updates forecasts.

.EXAMPLE
    Monitoring-CapacityTrendForecaster.ps1 -Testrun "True"
    Runs in test mode using only historical data from Base64 fields.

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Version: 3.0
    Release Notes:
        - V4.3: Adjusted thresholds to reduce false positives
        - V3.0: Added Write-Log function, execution tracking, enhanced error handling, structured helper functions
        - V1.0: Initial Release
    
    Exit Codes:
        0 = Success
        1 = Failure
    
    Custom Fields Required (NinjaRMM):
        - capHistoricalDiskUsage (Text/WYSIWYG) - Base64-encoded disk usage history
        - capHistoricalMemUsage (Text/WYSIWYG) - Base64-encoded memory usage history
        - capHistoricalCPUUsage (Text/WYSIWYG) - Base64-encoded CPU usage history
        - capDaysUntilDiskFull (Number) - Predicted days until C: drive is full
        - capMemoryUtilizationTrend (Dropdown) - Memory trend classification
        - capCPUUtilizationTrend (Dropdown) - CPU trend classification
        - capCapacityHealthScore (Number) - Composite health score (0-100)
        - capCapacityAlert (Checkbox) - Alert when health < 50 or disk < 30 days
    
    Trend Classification:
        - Stable: Normal fluctuations within acceptable ranges
        - Increasing: Sustained growth trend detected
        - Decreasing: Sustained decline trend detected
        - Volatile: High variability, unpredictable patterns
    
    Algorithm Details:
        - Uses linear regression for disk growth forecasting
        - Coefficient of Variation (CV) for volatility detection
        - Weekly growth rate percentage for trend classification
        - Maintains rolling 30-day history for each metric
        - Requires minimum 7 days for trend analysis
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('True', 'False')]
    [String]$Testrun = $env:testrun
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    Set-StrictMode -Version Latest
    
    $ScriptStartTime = Get-Date
    $isTestMode = ($Testrun -eq 'True')

    function Write-Log {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,
            
            [Parameter(Mandatory = $false)]
            [ValidateSet('INFO', 'WARNING', 'ERROR')]
            [string]$Level = 'INFO'
        )
        
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR'   { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default   { Write-Host $logMessage }
        }
    }

    function Write-Base64Field {
        <#
        .SYNOPSIS
            Encodes data as Base64 JSON and saves to NinjaRMM custom field.
        #>
        param(
            [Parameter(Mandatory = $true)]
            [string]$FieldName,
            
            [Parameter(Mandatory = $true)]
            [object]$Data
        )
        
        if ($isTestMode) {
            Write-Log "[TESTRUN] Skipped saving $FieldName"
            return
        }
        
        try {
            $json = $Data | ConvertTo-Json -Compress -Depth 10
            $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))
            Ninja-Property-Set $FieldName $base64
            Write-Log "Saved $FieldName ($($json.Length) bytes)"
        }
        catch {
            Write-Log "Failed to save $FieldName: $($_.Exception.Message)" -Level ERROR
            throw
        }
    }

    function Read-Base64Field {
        <#
        .SYNOPSIS
            Reads and decodes Base64 JSON from NinjaRMM custom field.
        #>
        param(
            [Parameter(Mandatory = $true)]
            [string]$FieldName
        )
        
        try {
            $value = Ninja-Property-Get $FieldName
            
            if ([string]::IsNullOrEmpty($value)) { 
                return $null 
            }
            
            $json = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($value))
            return ($json | ConvertFrom-Json)
        }
        catch {
            Write-Log "Failed to read $FieldName: $($_.Exception.Message)" -Level WARNING
            return $null
        }
    }

    function Get-LinearRegression {
        <#
        .SYNOPSIS
            Calculates linear regression slope from data points.
        #>
        param(
            [Parameter(Mandatory = $true)]
            [array]$Points
        )
        
        if ($Points.Count -lt 2) {
            return @{ Slope = 0; Valid = $false }
        }
        
        $n = $Points.Count
        $sumX = 0
        $sumY = 0
        $sumXY = 0
        $sumX2 = 0
        
        foreach ($p in $Points) {
            $sumX += $p.X
            $sumY += $p.Y
            $sumXY += ($p.X * $p.Y)
            $sumX2 += ($p.X * $p.X)
        }
        
        $denom = ($n * $sumX2) - ($sumX * $sumX)
        
        if ($denom -eq 0) { 
            return @{ Slope = 0; Valid = $false } 
        }
        
        $slope = (($n * $sumXY) - ($sumX * $sumY)) / $denom
        
        return @{ Slope = $slope; Valid = $true }
    }

    function Get-CPUUtilization {
        <#
        .SYNOPSIS
            Gets current CPU utilization with multi-language counter support.
        #>
        try {
            $cpuUtil = [math]::Round((
                    Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3 -ErrorAction Stop | 
                    Select-Object -ExpandProperty CounterSamples | 
                    Measure-Object -Property CookedValue -Average
                ).Average, 2)
            
            return $cpuUtil
        }
        catch {
            try {
                $cpuUtil = [math]::Round((
                        Get-Counter '\Prozessor(_Total)\Prozessorzeit (%)' -SampleInterval 2 -MaxSamples 3 -ErrorAction Stop | 
                        Select-Object -ExpandProperty CounterSamples | 
                        Measure-Object -Property CookedValue -Average
                    ).Average, 2)
                
                return $cpuUtil
            }
            catch {
                Write-Log 'Could not read CPU performance counter. Using 0% as fallback.' -Level WARNING
                return 0
            }
        }
    }

    $memTrendGuid = @{
        'Stable'     = '2b702e1e-5f4b-4e88-800c-865cbcd9f9a6'
        'Increasing' = 'b9533a91-54be-446e-bd72-c6bfea5c9a20'
        'Decreasing' = 'ff3f265c-c876-4159-aad0-3b112c5ef657'
        'Volatile'   = 'f1d2956a-4210-43a6-b61c-e809e658e1c1'
    }
    
    $cpuTrendGuid = @{
        'Stable'     = '88a57615-3d6d-4c51-a8e8-69fabe0ad5a7'
        'Increasing' = '059d6033-aeba-4ae4-90a3-77c2d2d7dfd4'
        'Decreasing' = '1badb13a-e32c-4a30-8f5a-915c7918d212'
        'Volatile'   = '257619b0-8955-478c-b9d5-b8aaea0fa15c'
    }
    
    Write-Log '=== Capacity Trend Forecaster (v3.0) ==='
    
    if ($isTestMode) {
        Write-Log '=========================================' -Level WARNING
        Write-Log 'TESTRUN MODE ENABLED' -Level WARNING
        Write-Log 'Using only Base64 test data' -Level WARNING
        Write-Log "Today's real values will be ignored" -Level WARNING
        Write-Log '=========================================' -Level WARNING
    }
}

process {
    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $diskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $diskSizeGB = [math]::Round($disk.Size / 1GB, 2)
        $diskUsedGB = $diskSizeGB - $diskFreeGB
        $diskFreePercent = [math]::Round(($diskFreeGB / $diskSizeGB) * 100, 2)
        
        Write-Log "Current Disk: $diskUsedGB GB used / $diskSizeGB GB total ($diskFreePercent% free)"
        
        $diskHistory = Read-Base64Field 'capHistoricalDiskUsage'
        
        if ($null -eq $diskHistory) {
            $diskHistory = @(@{ Date = (Get-Date -Format 'yyyy-MM-dd'); UsedGB = $diskUsedGB })
            Write-Log 'Initialized disk history with first entry'
        }
        else {
            if ($diskHistory -isnot [array]) { 
                $diskHistory = @($diskHistory) 
            }
            
            if (-not $isTestMode) {
                $today = Get-Date -Format 'yyyy-MM-dd'
                $found = $false
                
                for ($i = 0; $i -lt $diskHistory.Count; $i++) {
                    if ($diskHistory[$i].Date -eq $today) {
                        $diskHistory[$i].UsedGB = $diskUsedGB
                        $found = $true
                        Write-Log "Updated disk entry for $today"
                        break
                    }
                }
                
                if (-not $found) {
                    $diskHistory += @{ Date = $today; UsedGB = $diskUsedGB }
                    Write-Log "Added new disk entry for $today"
                }
                
                if ($diskHistory.Count -gt 30) {
                    $diskHistory = $diskHistory | Select-Object -Last 30
                    Write-Log 'Trimmed disk history to last 30 days'
                }
            }
            else {
                Write-Log "[TESTRUN] Using Base64 disk data as-is ($($diskHistory.Count) records)"
            }
        }
        
        $daysUntilFull = 999
        $diskGrowth = 0
        
        if ($diskHistory.Count -ge 2) {
            $baseDate = [DateTime]::ParseExact($diskHistory[0].Date, 'yyyy-MM-dd', $null)
            $points = @()
            
            foreach ($entry in $diskHistory) {
                try {
                    $date = [DateTime]::ParseExact($entry.Date, 'yyyy-MM-dd', $null)
                    $points += @{ X = ($date - $baseDate).Days; Y = $entry.UsedGB }
                }
                catch { }
            }
            
            $reg = Get-LinearRegression -Points $points
            
            if ($reg.Valid -and $reg.Slope -gt 0.01) {
                $diskGrowth = $reg.Slope
                
                if ($isTestMode -and $diskHistory.Count -gt 0) {
                    $lastEntry = $diskHistory[-1]
                    $lastUsedGB = $lastEntry.UsedGB
                    $diskFreeFromTest = $diskSizeGB - $lastUsedGB
                    $daysUntilFull = [math]::Round($diskFreeFromTest / $diskGrowth)
                }
                else {
                    $daysUntilFull = [math]::Round($diskFreeGB / $diskGrowth)
                }
                
                if ($daysUntilFull -gt 999 -or $daysUntilFull -lt 0) { 
                    $daysUntilFull = 999 
                }
                
                Write-Log "Disk growth rate: $([math]::Round($diskGrowth, 3)) GB/day, predicted full in $daysUntilFull days"
            }
            else {
                Write-Log 'Disk growth rate too low or invalid for prediction'
            }
        }
        else {
            Write-Log 'Insufficient disk history for growth prediction'
        }
        
        Write-Base64Field 'capHistoricalDiskUsage' $diskHistory
        
        $os = Get-CimInstance Win32_OperatingSystem
        $memUtil = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
        
        Write-Log "Current Memory Utilization: $memUtil%"
        
        $memHistory = Read-Base64Field 'capHistoricalMemUsage'
        
        if ($null -eq $memHistory) {
            $memHistory = @(@{ Date = (Get-Date -Format 'yyyy-MM-dd'); Utilization = $memUtil })
            $memTrend = 'Stable'
            $memAvg = $memUtil
            Write-Log 'Initialized memory history with first entry'
        }
        else {
            if ($memHistory -isnot [array]) { 
                $memHistory = @($memHistory) 
            }
            
            if (-not $isTestMode) {
                $today = Get-Date -Format 'yyyy-MM-dd'
                $found = $false
                
                for ($i = 0; $i -lt $memHistory.Count; $i++) {
                    if ($memHistory[$i].Date -eq $today) {
                        $memHistory[$i].Utilization = $memUtil
                        $found = $true
                        break
                    }
                }
                
                if (-not $found) {
                    $memHistory += @{ Date = $today; Utilization = $memUtil }
                }
                
                if ($memHistory.Count -gt 30) {
                    $memHistory = $memHistory | Select-Object -Last 30
                }
            }
            
            if ($memHistory.Count -ge 7) {
                $values = $memHistory | ForEach-Object { $_.Utilization }
                $memAvg = ($values | Measure-Object -Average).Average
                $variance = ($values | ForEach-Object { [math]::Pow($_ - $memAvg, 2) } | Measure-Object -Average).Average
                $stdDev = [math]::Sqrt($variance)
                $cv = if ($memAvg -gt 0) { ($stdDev / $memAvg) * 100 } else { 0 }
                
                $baseDate = [DateTime]::ParseExact($memHistory[0].Date, 'yyyy-MM-dd', $null)
                $points = @()
                
                foreach ($entry in $memHistory) {
                    try {
                        $date = [DateTime]::ParseExact($entry.Date, 'yyyy-MM-dd', $null)
                        $points += @{ X = ($date - $baseDate).Days; Y = $entry.Utilization }
                    }
                    catch { }
                }
                
                $reg = Get-LinearRegression -Points $points
                $weeklyGrowth = if ($reg.Valid -and $memAvg -gt 0) { ($reg.Slope * 7 / $memAvg) * 100 } else { 0 }
                
                if ($cv -gt 30) { 
                    $memTrend = 'Volatile'
                    Write-Log "Memory: Volatile detected (CV=$([math]::Round($cv, 2))%)"
                }
                elseif ($weeklyGrowth -gt 5) { 
                    $memTrend = 'Increasing'
                    Write-Log "Memory: Increasing detected (Weekly growth=$([math]::Round($weeklyGrowth, 2))%)"
                }
                elseif ($weeklyGrowth -lt -5) { 
                    $memTrend = 'Decreasing'
                    Write-Log "Memory: Decreasing detected (Weekly decline=$([math]::Round($weeklyGrowth, 2))%)"
                }
                else { 
                    $memTrend = 'Stable'
                    Write-Log "Memory: Stable (CV=$([math]::Round($cv, 2))%, Weekly=$([math]::Round($weeklyGrowth, 2))%)"
                }
            }
            else {
                $memTrend = 'Stable'
                $memAvg = $memUtil
                Write-Log "Memory: Insufficient data ($($memHistory.Count) days, need 7+)"
            }
        }
        
        Write-Base64Field 'capHistoricalMemUsage' $memHistory
        
        $cpuUtil = Get-CPUUtilization
        Write-Log "Current CPU Utilization: $cpuUtil%"
        
        $cpuHistory = Read-Base64Field 'capHistoricalCPUUsage'
        
        if ($null -eq $cpuHistory) {
            $cpuHistory = @(@{ Date = (Get-Date -Format 'yyyy-MM-dd'); Utilization = $cpuUtil })
            $cpuTrend = 'Stable'
            $cpuAvg = $cpuUtil
            Write-Log 'Initialized CPU history with first entry'
        }
        else {
            if ($cpuHistory -isnot [array]) { 
                $cpuHistory = @($cpuHistory) 
            }
            
            if (-not $isTestMode) {
                $today = Get-Date -Format 'yyyy-MM-dd'
                $found = $false
                
                for ($i = 0; $i -lt $cpuHistory.Count; $i++) {
                    if ($cpuHistory[$i].Date -eq $today) {
                        $cpuHistory[$i].Utilization = $cpuUtil
                        $found = $true
                        break
                    }
                }
                
                if (-not $found) {
                    $cpuHistory += @{ Date = $today; Utilization = $cpuUtil }
                }
                
                if ($cpuHistory.Count -gt 30) {
                    $cpuHistory = $cpuHistory | Select-Object -Last 30
                }
            }
            
            if ($cpuHistory.Count -ge 7) {
                $values = $cpuHistory | ForEach-Object { $_.Utilization }
                $cpuAvg = ($values | Measure-Object -Average).Average
                $variance = ($values | ForEach-Object { [math]::Pow($_ - $cpuAvg, 2) } | Measure-Object -Average).Average
                $stdDev = [math]::Sqrt($variance)
                $cv = if ($cpuAvg -gt 0) { ($stdDev / $cpuAvg) * 100 } else { 0 }
                
                $baseDate = [DateTime]::ParseExact($cpuHistory[0].Date, 'yyyy-MM-dd', $null)
                $points = @()
                
                foreach ($entry in $cpuHistory) {
                    try {
                        $date = [DateTime]::ParseExact($entry.Date, 'yyyy-MM-dd', $null)
                        $points += @{ X = ($date - $baseDate).Days; Y = $entry.Utilization }
                    }
                    catch { }
                }
                
                $reg = Get-LinearRegression -Points $points
                $weeklyGrowth = if ($reg.Valid -and $cpuAvg -gt 0) { ($reg.Slope * 7 / $cpuAvg) * 100 } else { 0 }
                
                if ($cv -gt 40) { 
                    $cpuTrend = 'Volatile'
                    Write-Log "CPU: Volatile detected (CV=$([math]::Round($cv, 2))%)"
                }
                elseif ($weeklyGrowth -gt 8) { 
                    $cpuTrend = 'Increasing'
                    Write-Log "CPU: Increasing detected (Weekly growth=$([math]::Round($weeklyGrowth, 2))%)"
                }
                elseif ($weeklyGrowth -lt -8) { 
                    $cpuTrend = 'Decreasing'
                    Write-Log "CPU: Decreasing detected (Weekly decline=$([math]::Round($weeklyGrowth, 2))%)"
                }
                else { 
                    $cpuTrend = 'Stable'
                    Write-Log "CPU: Stable (CV=$([math]::Round($cv, 2))%, Weekly=$([math]::Round($weeklyGrowth, 2))%)"
                }
            }
            else {
                $cpuTrend = 'Stable'
                $cpuAvg = $cpuUtil
                Write-Log "CPU: Insufficient data ($($cpuHistory.Count) days, need 7+)"
            }
        }
        
        Write-Base64Field 'capHistoricalCPUUsage' $cpuHistory
        
        $health = 100
        
        if ($isTestMode -and $diskHistory.Count -gt 0) {
            $lastEntry = $diskHistory[-1]
            $lastUsedGB = $lastEntry.UsedGB
            $testDiskFreeGB = $diskSizeGB - $lastUsedGB
            $testDiskFreePercent = [math]::Round(($testDiskFreeGB / $diskSizeGB) * 100, 2)
            
            if ($testDiskFreePercent -lt 10) { $health -= 40 }
            elseif ($testDiskFreePercent -lt 20) { $health -= 20 }
        }
        else {
            if ($diskFreePercent -lt 10) { $health -= 40 }
            elseif ($diskFreePercent -lt 20) { $health -= 20 }
        }
        
        if ($daysUntilFull -lt 30) { $health -= 30 }
        elseif ($daysUntilFull -lt 90) { $health -= 15 }
        
        if ($memAvg -gt 90) { $health -= 15 }
        if ($cpuAvg -gt 85) { $health -= 15 }
        
        if ($memTrend -eq 'Increasing') { $health -= 10 }
        if ($cpuTrend -eq 'Increasing') { $health -= 10 }
        
        if ($health -lt 0) { $health = 0 }
        
        $alert = ($daysUntilFull -lt 30 -or $health -lt 50)
        
        Write-Log "Capacity Health Score: $health/100 (Alert: $alert)"
        
        if (-not $isTestMode) {
            Ninja-Property-Set capDaysUntilDiskFull $daysUntilFull
            Ninja-Property-Set -Type Dropdown capMemoryUtilizationTrend $memTrendGuid[$memTrend]
            Ninja-Property-Set -Type Dropdown capCPUUtilizationTrend $cpuTrendGuid[$cpuTrend]
            Ninja-Property-Set capCapacityHealthScore $health
            Ninja-Property-Set capCapacityAlert $alert
            
            Write-Log 'Successfully updated all NinjaRMM custom fields'
        }
        else {
            Write-Log '[TESTRUN] Would update custom fields:'
            Write-Log "  capDaysUntilDiskFull = $daysUntilFull"
            Write-Log "  capMemoryUtilizationTrend = $memTrend ($($memTrendGuid[$memTrend]))"
            Write-Log "  capCPUUtilizationTrend = $cpuTrend ($($cpuTrendGuid[$cpuTrend]))"
            Write-Log "  capCapacityHealthScore = $health"
            Write-Log "  capCapacityAlert = $alert"
        }
        
        Write-Log ''
        Write-Log '=== SUMMARY ==='
        Write-Log "Disk: $diskFreeGB GB free ($diskFreePercent%), Growth: $([math]::Round($diskGrowth, 3)) GB/day, Days until full: $daysUntilFull"
        Write-Log "Memory: $memTrend trend, Avg: $([math]::Round($memAvg, 2))%, Records: $($memHistory.Count)"
        Write-Log "CPU: $cpuTrend trend, Avg: $([math]::Round($cpuAvg, 2))%, Records: $($cpuHistory.Count)"
        Write-Log "Health: $health/100, Alert: $alert"
        
        exit 0
    }
    catch {
        Write-Log "Unexpected error: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
        exit 1
    }
}

end {
    $executionTime = (Get-Date) - $ScriptStartTime
    Write-Log "Script execution completed in $($executionTime.TotalSeconds) seconds."
    
    [System.GC]::Collect()
}
