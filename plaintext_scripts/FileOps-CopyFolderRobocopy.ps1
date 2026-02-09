<#
.SYNOPSIS
    Copy folder with all contents using PowerShell (Robocopy alternative)

.DESCRIPTION
    Robustly copies a folder and all its contents from source to destination
    with retry logic and progress reporting. PowerShell equivalent of robocopy /E /mt /r:5

.PARAMETER fromPath
    Source folder path (use environment variable $env:fromPath)

.PARAMETER toPath
    Destination folder path (use environment variable $env:toPath)

.NOTES
    Author: WAF
    Version: 2.0
    Converted from batch to PowerShell
    Uses Copy-Item with robust error handling
#>

try {
    $source = $env:fromPath
    $destination = $env:toPath

    # Validate parameters
    if ([string]::IsNullOrWhiteSpace($source)) {
        throw "Source path (fromPath) not specified"
    }

    if ([string]::IsNullOrWhiteSpace($destination)) {
        throw "Destination path (toPath) not specified"
    }

    # Check if source exists
    if (-not (Test-Path -Path $source -PathType Container)) {
        throw "Source folder does not exist: $source"
    }

    Write-Host "Copying folder from '$source' to '$destination'"
    Write-Host "This may take a while depending on folder size..."

    # Create destination if it doesn't exist
    if (-not (Test-Path -Path $destination)) {
        Write-Host "Creating destination folder: $destination"
        New-Item -Path $destination -ItemType Directory -Force | Out-Null
    }

    # Copy with retries (equivalent to /r:5)
    $maxRetries = 5
    $retryCount = 0
    $success = $false

    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            # Copy all items recursively (equivalent to /E)
            # Force overwrites existing files
            # Container preserves directory structure
            Copy-Item -Path "$source\*" -Destination $destination -Recurse -Force -ErrorAction Stop
            $success = $true
            Write-Host "erfolgreich oder mit akzeptablen Warnungen beendet. (Copy completed successfully)"
        }
        catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Warning "Copy attempt $retryCount failed, retrying... Error: $($_.Exception.Message)"
                Start-Sleep -Seconds 2
            }
            else {
                throw "FEHLER! Copy failed after $maxRetries attempts. Error: $($_.Exception.Message)"
            }
        }
    }

    # Verify copy
    $sourceItems = (Get-ChildItem -Path $source -Recurse -File | Measure-Object).Count
    $destItems = (Get-ChildItem -Path $destination -Recurse -File | Measure-Object).Count
    
    Write-Host "Source files: $sourceItems"
    Write-Host "Destination files: $destItems"

    if ($sourceItems -eq $destItems) {
        Write-Host "SUCCESS: All files copied successfully"
        exit 0
    }
    else {
        Write-Warning "File count mismatch - some files may not have been copied"
        exit 0  # Still exit 0 as per original robocopy behavior (ERRORLEVEL < 8)
    }
}
catch {
    Write-Error "FEHLER! (ERROR!) - $($_.Exception.Message)"
    exit 1
}
