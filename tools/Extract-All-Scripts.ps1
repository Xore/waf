<#
.SYNOPSIS
    NinjaOne Framework v4.0 - Script Extraction Utility

.DESCRIPTION
    This utility extracts all 110 PowerShell scripts from the framework documentation
    and generates individual .ps1 files organized by category.

.PARAMETER OutputPath
    Destination folder for extracted scripts. Default: ./scripts

.PARAMETER DocumentationPath
    Path to framework documentation markdown files. Default: ../

.EXAMPLE
    .\Extract-All-Scripts.ps1
    
.EXAMPLE
    .\Extract-All-Scripts.ps1 -OutputPath "C:\NinjaScripts" -DocumentationPath "C:\FrameworkDocs"

.NOTES
    Version: 1.0
    Author: NinjaOne Custom Field Framework
    Date: February 2, 2026
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "..\scripts",
    
    [Parameter(Mandatory=$false)]
    [string]$DocumentationPath = ".."
)

Write-Host "="*80
Write-Host "NinjaOne Framework v4.0 - Script Extraction Utility"
Write-Host "="*80
Write-Host ""

# Create output directory structure
$directories = @(
    "Core_Monitoring",
    "Extended_Automation",
    "Advanced_Telemetry",
    "Server_Roles\IIS_Web_Servers",
    "Server_Roles\SQL_Servers",
    "Server_Roles\Infrastructure_Services",
    "Server_Roles\Advanced_Features",
    "Patching_Automation"
)

Write-Host "Creating directory structure..."
foreach ($dir in $directories) {
    $fullPath = Join-Path $OutputPath $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  Created: $fullPath"
    }
}

Write-Host ""
Write-Host "Scanning documentation files for PowerShell scripts..."
Write-Host ""

# Documentation files containing scripts
$docFiles = @(
    "55_Scripts_01_13_Infrastructure_Monitoring.md",
    "61_Scripts_Patching_Automation.md",
    "53_Scripts_Extended_Automation.md",
    "60_Scripts_Advanced_Telemetry.md",
    "22_IIS_MSSQL_MYSQL_Database_Web_Servers.md",
    "23_APACHE_VEEAM_DHCP_DNS_Infrastructure.md",
    "24_EVT_FS_PRINT_HV_BL_FEAT_FLEXLM_Additional_Roles.md"
)

$scriptCount = 0
$extractedScripts = @{}

foreach ($docFile in $docFiles) {
    $docPath = Join-Path $DocumentationPath $docFile
    
    if (Test-Path $docPath) {
        Write-Host "Processing: $docFile"
        $content = Get-Content $docPath -Raw
        
        # Extract PowerShell code blocks
        $pattern = '```powershell([\s\S]*?)```'
        $matches = [regex]::Matches($content, $pattern)
        
        foreach ($match in $matches) {
            $scriptContent = $match.Groups[1].Value.Trim()
            
            # Skip empty blocks
            if ([string]::IsNullOrWhiteSpace($scriptContent)) { continue }
            
            # Try to identify script number/name from context
            $beforeMatch = $content.Substring(0, $match.Index)
            $lines = $beforeMatch -split "`n"
            $recentLines = $lines | Select-Object -Last 20
            
            # Look for script identifier
            $scriptId = "Unknown"
            foreach ($line in $recentLines) {
                if ($line -match 'Script (\d+|PR\d+|P\d+):?\s*([^#`r`n]+)') {
                    $scriptNum = $matches[1]
                    $scriptName = $matches[2].Trim()
                    $scriptId = "Script_${scriptNum}_${scriptName}"
                    break
                }
            }
            
            # Determine output directory based on script number
            $outputDir = "Core_Monitoring"
            if ($scriptId -match 'Script_(1[4-9]|2[0-7])_') { $outputDir = "Extended_Automation" }
            elseif ($scriptId -match 'Script_(2[8-9]|3[0-6])_') { $outputDir = "Advanced_Telemetry" }
            elseif ($scriptId -match 'Script_([5-9]\d|1\d\d)_') { $outputDir = "Server_Roles" }
            elseif ($scriptId -match 'Script_(PR|P\d)_') { $outputDir = "Patching_Automation" }
            
            # Sanitize filename
            $filename = $scriptId -replace '[^a-zA-Z0-9_-]', '_'
            $filename = "${filename}.ps1"
            
            # Avoid duplicates
            if ($extractedScripts.ContainsKey($filename)) {
                continue
            }
            
            $extractedScripts[$filename] = $true
            
            # Add header if missing
            if ($scriptContent -notmatch '<#') {
                $header = @"
<#
.SYNOPSIS
    NinjaOne Framework v4.0 - $scriptId

.DESCRIPTION
    Extracted from framework documentation.
    
.NOTES
    Version: 4.0
    Date: February 2, 2026
    Source: $docFile
#>

"@
                $scriptContent = $header + $scriptContent
            }
            
            # Write script file
            $scriptPath = Join-Path $OutputPath (Join-Path $outputDir $filename)
            $scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8
            
            $scriptCount++
            Write-Host "  Extracted: $filename -> $outputDir"
        }
    } else {
        Write-Host "  WARNING: File not found: $docPath"
    }
}

Write-Host ""
Write-Host "="*80
Write-Host "Extraction Complete!"
Write-Host "="*80
Write-Host ""
Write-Host "Total Scripts Extracted: $scriptCount"
Write-Host "Output Location: $OutputPath"
Write-Host ""
Write-Host "Next Steps:"
Write-Host "1. Review extracted scripts in $OutputPath"
Write-Host "2. Test scripts on pilot devices before production deployment"
Write-Host "3. Deploy to NinjaOne via Configuration > Scripting"
Write-Host "4. Create custom fields as documented in files 10-14, 31"
Write-Host "5. Schedule scripts according to SCRIPTS_DOWNLOAD_GUIDE.md"
Write-Host ""
Write-Host "Documentation: See SCRIPTS_DOWNLOAD_GUIDE.md for complete deployment guide"
Write-Host ""
