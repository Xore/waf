#Requires -Version 5.1

<#
.SYNOPSIS
    Tests network connectivity to specified hosts using ping and port tests.

.DESCRIPTION
    Performs comprehensive network connectivity tests including ICMP ping and TCP 
    port connectivity checks. Tests multiple hosts and ports, providing detailed results 
    for each test. Useful for troubleshooting network issues, verifying firewall rules, 
    and monitoring service availability.
    
    The script supports:
    - ICMP ping tests with configurable count
    - TCP port connectivity tests
    - Multiple hosts and ports
    - Detailed response time reporting
    - Success/failure status for each test
    - Custom field output for reporting

.PARAMETER Hosts
    Comma-separated list of hostnames or IP addresses to test.
    Example: "google.com,8.8.8.8,192.168.1.1"

.PARAMETER Ports
    Comma-separated list of TCP ports to test. If specified, performs port tests in addition to ping.
    Example: "80,443,3389"

.PARAMETER PingCount
    Number of ping attempts per host. Default: 4

.PARAMETER Timeout
    Timeout in milliseconds for each connection attempt. Default: 1000 (1 second)

.PARAMETER SaveToCustomField
    Name of a custom field to save the connectivity test results.

.EXAMPLE
    .\Network-TestConnectivity.ps1 -Hosts "google.com,8.8.8.8"

    [2026-02-10 21:00:00] [INFO] Testing connectivity to 2 host(s)...
    [2026-02-10 21:00:01] [INFO] Host: google.com
    [2026-02-10 21:00:01] [SUCCESS] Ping: Success (4/4 replies, avg 15ms)
    [2026-02-10 21:00:02] [INFO] Host: 8.8.8.8
    [2026-02-10 21:00:02] [SUCCESS] Ping: Success (4/4 replies, avg 12ms)

.EXAMPLE
    .\Network-TestConnectivity.ps1 -Hosts "webserver.local" -Ports "80,443" -PingCount 2

    [2026-02-10 21:00:00] [INFO] Testing connectivity to 1 host(s) on 2 port(s)...
    [2026-02-10 21:00:00] [INFO] Host: webserver.local
    [2026-02-10 21:00:01] [SUCCESS] Ping: Success (2/2 replies, avg 5ms)
    [2026-02-10 21:00:01] [SUCCESS] Port 80: Open (response time 2ms)
    [2026-02-10 21:00:01] [SUCCESS] Port 443: Open (response time 3ms)

.NOTES
    File Name      : Network-TestConnectivity.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Complete V3 standards implementation with proper logging and error handling
    - 2.0: Added port testing capability
    - 1.0: Initial release
    
    Execution Context: User or SYSTEM
    Execution Frequency: On-demand (network testing)
    Typical Duration: 1-30 seconds (depends on host count and timeouts)
    Timeout Setting: User-configurable per connection
    
    User Interaction: None (automated testing)
    Restart Behavior: N/A
    
    Fields Updated:
        - Custom field specified by SaveToCustomField parameter (if provided)
    
    Dependencies:
        - Internet or network connectivity
        - Target hosts must be reachable
        - Firewall must allow ICMP (ping) and TCP connections
    
    Environment Variables (Optional):
        - hosts: Alternative to -Hosts parameter
        - ports: Alternative to -Ports parameter
        - pingCount: Alternative to -PingCount parameter
        - timeout: Alternative to -Timeout parameter
        - saveToCustomField: Alternative to -SaveToCustomField parameter

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Hosts,
    
    [Parameter(Mandatory = $false)]
    [string]$Ports,
    
    [Parameter(Mandatory = $false)]
    [int]$PingCount = 4,
    
    [Parameter(Mandatory = $false)]
    [int]$Timeout = 1000,
    
    [Parameter(Mandatory = $false)]
    [string]$SaveToCustomField
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Network-TestConnectivity"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Continue'
    $ProgressPreference = 'SilentlyContinue'
    $script:ExitCode = 0
    $script:ErrorCount = 0
    $script:WarningCount = 0

    function Write-Log {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            
            [Parameter(Mandatory=$false)]
            [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS')]
            [string]$Level = 'INFO'
        )
        
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        Write-Output $LogMessage
        
        switch ($Level) {
            'WARN'  { $script:WarningCount++ }
            'ERROR' { $script:ErrorCount++; $script:ExitCode = 1 }
        }
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        
        try {
            $CustomField = $Value | Ninja-Property-Set-Piped -Name $Name 2>&1
            if ($CustomField.Exception) {
                throw $CustomField
            }
            Write-Log "Custom field '$Name' set successfully" -Level DEBUG
        } catch {
            Write-Log "Failed to set custom field '$Name': $_" -Level ERROR
            throw
        }
    }

    function Test-TcpPort {
        param(
            [string]$Host,
            [int]$Port,
            [int]$Timeout
        )
        
        try {
            $TcpClient = New-Object System.Net.Sockets.TcpClient
            $StartTime = Get-Date
            $AsyncResult = $TcpClient.BeginConnect($Host, $Port, $null, $null)
            $Wait = $AsyncResult.AsyncWaitHandle.WaitOne($Timeout, $false)
            
            if ($Wait) {
                try {
                    $TcpClient.EndConnect($AsyncResult)
                    $ResponseTime = ((Get-Date) - $StartTime).TotalMilliseconds
                    $TcpClient.Close()
                    return @{ Success = $true; ResponseTime = [math]::Round($ResponseTime, 0) }
                } catch {
                    $TcpClient.Close()
                    return @{ Success = $false; Error = $_.Exception.Message }
                }
            } else {
                $TcpClient.Close()
                return @{ Success = $false; Error = "Connection timeout" }
            }
        } catch {
            return @{ Success = $false; Error = $_.Exception.Message }
        }
    }
    
    # Override with environment variables
    if ($env:hosts -and $env:hosts -notlike "null") {
        $Hosts = $env:hosts
        Write-Log "Using hosts from environment: $Hosts" -Level DEBUG
    }
    if ($env:ports -and $env:ports -notlike "null") {
        $Ports = $env:ports
        Write-Log "Using ports from environment: $Ports" -Level DEBUG
    }
    if ($env:pingCount -and $env:pingCount -notlike "null") {
        $PingCount = [int]$env:pingCount
        Write-Log "Using ping count from environment: $PingCount" -Level DEBUG
    }
    if ($env:timeout -and $env:timeout -notlike "null") {
        $Timeout = [int]$env:timeout
        Write-Log "Using timeout from environment: $Timeout" -Level DEBUG
    }
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
        Write-Log "Using SaveToCustomField from environment: $SaveToCustomField" -Level DEBUG
    }
    
    # Parse hosts and ports
    $HostArray = @()
    $PortArray = @()
    
    if ($Hosts) {
        $HostArray = $Hosts -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }
    
    if ($Ports) {
        $PortArray = $Ports -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if ($HostArray.Count -eq 0) {
            Write-Log "No hosts specified" -Level ERROR
            throw "No hosts to test"
        }

        if ($PortArray.Count -gt 0) {
            Write-Log "Testing connectivity to $($HostArray.Count) host(s) on $($PortArray.Count) port(s)..." -Level INFO
        } else {
            Write-Log "Testing connectivity to $($HostArray.Count) host(s)..." -Level INFO
        }

        $Report = @()
        $FailureCount = 0

        foreach ($Host in $HostArray) {
            Write-Log "" -Level INFO
            Write-Log "Host: $Host" -Level INFO
            $HostReport = "Host: $Host"
            
            try {
                $PingResult = Test-Connection -ComputerName $Host -Count $PingCount -ErrorAction SilentlyContinue
                
                if ($PingResult) {
                    $SuccessCount = ($PingResult | Measure-Object).Count
                    $AvgTime = [math]::Round(($PingResult | Measure-Object -Property ResponseTime -Average).Average, 0)
                    Write-Log "Ping: Success ($SuccessCount/$PingCount replies, avg ${AvgTime}ms)" -Level SUCCESS
                    $HostReport += " | Ping: $SuccessCount/$PingCount (${AvgTime}ms)"
                } else {
                    Write-Log "Ping: Failed (0/$PingCount replies)" -Level WARN
                    $HostReport += " | Ping: Failed"
                    $FailureCount++
                }
            } catch {
                Write-Log "Ping: Error - $_" -Level ERROR
                $HostReport += " | Ping: Error"
                $FailureCount++
            }
            
            foreach ($Port in $PortArray) {
                $PortTest = Test-TcpPort -Host $Host -Port $Port -Timeout $Timeout
                
                if ($PortTest.Success) {
                    Write-Log "Port $Port: Open (response time $($PortTest.ResponseTime)ms)" -Level SUCCESS
                    $HostReport += " | Port $Port: Open ($($PortTest.ResponseTime)ms)"
                } else {
                    Write-Log "Port $Port: Closed or unreachable" -Level WARN
                    $HostReport += " | Port $Port: Closed"
                    $FailureCount++
                }
            }
            
            $Report += $HostReport
        }

        Write-Log "" -Level INFO
        if ($FailureCount -gt 0) {
            Write-Log "$FailureCount test(s) failed" -Level WARN
            $script:ExitCode = 1
        } else {
            Write-Log "All connectivity tests passed" -Level SUCCESS
        }

        if ($SaveToCustomField) {
            try {
                $Report -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                Write-Log "Results saved to custom field '$SaveToCustomField'" -Level INFO
            } catch {
                Write-Log "Failed to save to custom field: $_" -Level ERROR
            }
        }
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Summary:" -Level INFO
        Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "  Errors: $script:ErrorCount" -Level INFO
        Write-Log "  Warnings: $script:WarningCount" -Level INFO
        Write-Log "  Exit Code: $script:ExitCode" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
