#Requires -Version 5.1

<#
.SYNOPSIS
    Security Surface Telemetry - Attack Surface Analysis and Monitoring

.DESCRIPTION
    Analyzes exposed network ports, services, and certificate health to identify potential
    security vulnerabilities and attack surface exposure. Monitors listening TCP ports with
    special attention to high-risk services commonly targeted by attackers.
    
    Tracks certificate expiration to prevent service disruptions from expired certificates.
    Provides HTML-formatted summary of security posture with color-coded risk indicators
    for quick visual assessment of exposure levels.
    
    High-risk ports monitored:
    - 21 (FTP) - Unencrypted file transfer
    - 23 (Telnet) - Unencrypted remote access
    - 135 (RPC) - Windows RPC endpoint mapper
    - 139 (NetBIOS) - Legacy NetBIOS session service
    - 445 (SMB) - Direct SMB file sharing
    - 1433 (SQL Server) - Database exposure
    - 3389 (RDP) - Remote Desktop
    - 5900 (VNC) - VNC remote access

.PARAMETER ExposedPortsField
    NinjaRMM custom field name to store total listening TCP ports count.
    Default: secInternetExposedPortsCount

.PARAMETER HighRiskServicesField
    NinjaRMM custom field name to store high-risk services exposed count.
    Default: secHighRiskServicesExposed

.PARAMETER ExpiringCertsField
    NinjaRMM custom field name to store count of certificates expiring within threshold days.
    Default: secSoonExpiringCertsCount

.PARAMETER SummaryHtmlField
    NinjaRMM custom field name to store HTML formatted security summary.
    Default: secSecuritySurfaceSummaryHtml

.PARAMETER CertExpirationDays
    Number of days threshold for certificate expiration warning.
    Default: 30

.EXAMPLE
    .\SecuritySurfaceTelemetry.ps1

    Runs security surface analysis with default settings (30-day certificate threshold).

.EXAMPLE
    .\SecuritySurfaceTelemetry.ps1 -CertExpirationDays 60

    Runs with 60-day certificate expiration warning threshold.

.OUTPUTS
    None. Results are written to console and NinjaRMM custom fields.

.NOTES
    File Name      : SecuritySurfaceTelemetry.ps1
    Prerequisite   : PowerShell 5.1 or higher, Admin privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Framework      : V3
    Frequency      : Daily
    Runtime        : Approximately 40 seconds
    Timeout        : 90 seconds
    Context        : SYSTEM
    
    Change Log:
    - 3.0.0: V3 migration with standardized logging, error handling, and parameterized configuration
    - 4.0: Previous version with attack surface analysis
    
    Fields Updated:
    - secInternetExposedPortsCount: Integer total listening TCP ports
    - secHighRiskServicesExposed: Integer count of high-risk ports listening
    - secSoonExpiringCertsCount: Integer certificates expiring within threshold
    - secSecuritySurfaceSummaryHtml: WYSIWYG HTML formatted security summary
    
    Dependencies:
    - Get-NetTCPConnection cmdlet (Windows PowerShell 5.1+)
    - Access to LocalMachine certificate store
    
    Security Considerations:
    - High-risk port detection helps identify unnecessary service exposure
    - Certificate monitoring prevents service disruptions
    - Regular scanning enables trend analysis of attack surface changes
    - HTML summary provides quick visual assessment for dashboards
    
    Exit Codes:
    - 0: Script completed successfully
    - 1: Script encountered errors
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$ExposedPortsField = "secInternetExposedPortsCount",
    
    [Parameter()]
    [String]$HighRiskServicesField = "secHighRiskServicesExposed",
    
    [Parameter()]
    [String]$ExpiringCertsField = "secSoonExpiringCertsCount",
    
    [Parameter()]
    [String]$SummaryHtmlField = "secSecuritySurfaceSummaryHtml",
    
    [Parameter()]
    [ValidateRange(1, 365)]
    [Int]$CertExpirationDays = 30
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    $script:ExitCode = 0
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param(
            [string]$Message,
            [string]$Level = 'INFO'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Output $LogMessage; $script:ExitCode = 1 }
            'WARNING' { Write-Output $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:exposedPortsField -and $env:exposedPortsField -notlike "null") {
        $ExposedPortsField = $env:exposedPortsField
    }
    if ($env:highRiskServicesField -and $env:highRiskServicesField -notlike "null") {
        $HighRiskServicesField = $env:highRiskServicesField
    }
    if ($env:expiringCertsField -and $env:expiringCertsField -notlike "null") {
        $ExpiringCertsField = $env:expiringCertsField
    }
    if ($env:summaryHtmlField -and $env:summaryHtmlField -notlike "null") {
        $SummaryHtmlField = $env:summaryHtmlField
    }
    if ($env:certExpirationDays -and $env:certExpirationDays -notlike "null") {
        $CertExpirationDays = [int]$env:certExpirationDays
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            $Value
        )
        try {
            $NinjaValue = $Value
            $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
            if ($CustomField.Exception) {
                throw $CustomField
            }
        }
        catch {
            throw "Failed to set NinjaRMM property '$Name': $_"
        }
    }

    $HighRiskPorts = @{
        21   = 'FTP - Unencrypted file transfer'
        23   = 'Telnet - Unencrypted remote access'
        135  = 'RPC - Windows RPC endpoint mapper'
        139  = 'NetBIOS - Legacy session service'
        445  = 'SMB - Direct file sharing'
        1433 = 'SQL Server - Database exposure'
        3389 = 'RDP - Remote Desktop'
        5900 = 'VNC - Remote access'
    }
}

process {
    try {
        Write-Log "Starting Security Surface Telemetry (v3.0.0)"
        
        $metrics = @{
            'ListeningPorts' = 0
            'HighRiskServices' = 0
            'ExpiringCertificates' = 0
        }
        $highRiskDetails = @()
        $certDetails = @()

        Write-Log "Scanning listening TCP ports..."
        try {
            $listeningConnections = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
            
            if (-not $listeningConnections) {
                Write-Log "No listening ports detected (unusual - possible query issue)" -Level WARNING
                $listeningConnections = @()
            } 
            else {
                $listeningCount = ($listeningConnections | Measure-Object).Count
                $metrics['ListeningPorts'] = $listeningCount
                Write-Log "Found $listeningCount listening TCP port(s)"
            }
        }
        catch {
            Write-Log "Failed to query listening ports: $_" -Level ERROR
            $listeningConnections = @()
        }

        Write-Log "Analyzing high-risk port exposure..."
        foreach ($port in $HighRiskPorts.Keys | Sort-Object) {
            $isListening = $listeningConnections | Where-Object { $_.LocalPort -eq $port }
            
            if ($isListening) {
                $metrics['HighRiskServices']++
                $serviceName = $HighRiskPorts[$port]
                $highRiskDetails += "Port $port ($serviceName)"
                Write-Log "High-risk port exposed: $port - $serviceName" -Level WARNING
            }
        }
        
        if ($metrics['HighRiskServices'] -eq 0) {
            Write-Log "No high-risk ports are listening (good security posture)"
        } 
        else {
            Write-Log "$($metrics['HighRiskServices']) high-risk port(s) exposed" -Level WARNING
        }

        Write-Log "Checking certificate expiration (threshold: $CertExpirationDays days)..."
        try {
            $thresholdDate = (Get-Date).AddDays($CertExpirationDays)
            $certificates = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction Stop
            
            $expiringCerts = $certificates | Where-Object {
                $_.NotAfter -lt $thresholdDate -and $_.NotAfter -gt (Get-Date)
            }
            
            $metrics['ExpiringCertificates'] = ($expiringCerts | Measure-Object).Count
            
            if ($metrics['ExpiringCertificates'] -gt 0) {
                Write-Log "$($metrics['ExpiringCertificates']) certificate(s) expiring within $CertExpirationDays days" -Level WARNING
                
                foreach ($cert in $expiringCerts) {
                    $daysUntilExpiry = ($cert.NotAfter - (Get-Date)).Days
                    $certDetail = "$($cert.Subject) - expires in $daysUntilExpiry days ($($cert.NotAfter.ToString('yyyy-MM-dd')))"
                    $certDetails += $certDetail
                    Write-Log "  $certDetail" -Level WARNING
                }
            } 
            else {
                Write-Log "No certificates expiring within $CertExpirationDays days"
            }
        }
        catch {
            Write-Log "Failed to check certificate expiration: $_" -Level WARNING
            $metrics['ExpiringCertificates'] = 0
        }

        Write-Log "Generating HTML security surface summary..."
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
        $highRiskColor = if ($metrics['HighRiskServices'] -gt 0) { 'red' } else { 'green' }
        $certColor = if ($metrics['ExpiringCertificates'] -gt 0) { 'orange' } else { 'green' }
        
        $htmlSummary = @"
<div style='font-family: Arial, sans-serif;'>
    <h4 style='margin-bottom: 10px;'>Security Surface Analysis</h4>
    <table style='border-collapse: collapse; width: 100%;'>
        <tr style='border-bottom: 1px solid #ddd;'>
            <td style='padding: 8px;'>Total Listening Ports:</td>
            <td style='padding: 8px; font-weight: bold;'>$($metrics['ListeningPorts'])</td>
        </tr>
        <tr style='border-bottom: 1px solid #ddd;'>
            <td style='padding: 8px;'>High-Risk Services Exposed:</td>
            <td style='padding: 8px; font-weight: bold; color: $highRiskColor;'>$($metrics['HighRiskServices'])</td>
        </tr>
        <tr style='border-bottom: 1px solid #ddd;'>
            <td style='padding: 8px;'>Certificates Expiring Soon:</td>
            <td style='padding: 8px; font-weight: bold; color: $certColor;'>$($metrics['ExpiringCertificates'])</td>
        </tr>
    </table>
    <p style='font-size: 0.85em; color: #666; margin-top: 10px;'>Last Updated: $timestamp</p>
</div>
"@

        Write-Log "Updating NinjaRMM custom fields..."
        try {
            Set-NinjaProperty -Name $ExposedPortsField -Value $metrics['ListeningPorts'] -ErrorAction Stop
            Write-Log "Exposed ports count saved to field: $ExposedPortsField"
        }
        catch {
            Write-Log "Failed to update exposed ports field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $HighRiskServicesField -Value $metrics['HighRiskServices'] -ErrorAction Stop
            Write-Log "High-risk services count saved to field: $HighRiskServicesField"
        }
        catch {
            Write-Log "Failed to update high-risk services field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $ExpiringCertsField -Value $metrics['ExpiringCertificates'] -ErrorAction Stop
            Write-Log "Expiring certificates count saved to field: $ExpiringCertsField"
        }
        catch {
            Write-Log "Failed to update expiring certificates field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $SummaryHtmlField -Value $htmlSummary -ErrorAction Stop
            Write-Log "HTML summary saved to field: $SummaryHtmlField"
        }
        catch {
            Write-Log "Failed to update HTML summary field: $_" -Level ERROR
        }

        Write-Log "SECURITY SURFACE METRICS:"
        Write-Log "  Total Listening Ports: $($metrics['ListeningPorts'])"
        Write-Log "  High-Risk Services: $($metrics['HighRiskServices'])"
        Write-Log "  Expiring Certificates: $($metrics['ExpiringCertificates'])"

        if ($highRiskDetails.Count -gt 0) {
            Write-Log "HIGH-RISK SERVICES EXPOSED:"
            $highRiskDetails | ForEach-Object { Write-Log "  - $_" -Level WARNING }
        }

        if ($certDetails.Count -gt 0) {
            Write-Log "EXPIRING CERTIFICATES:"
            $certDetails | ForEach-Object { Write-Log "  - $_" -Level WARNING }
        }

        Write-Log "Security surface telemetry completed successfully"
    }
    catch {
        Write-Log "Security surface telemetry failed with unexpected error: $_" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        Write-Log "Script execution completed in $([Math]::Round($Duration, 2)) seconds"
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
