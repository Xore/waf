#Requires -Version 5.1

<#
.SYNOPSIS
    Monitor OneDrive configuration and sync status for current user

.DESCRIPTION
    Comprehensive OneDrive monitoring solution that executes in the current user's
    context to gather folder redirection status, sync health, and SharePoint library
    information. Generates HTML dashboard output for NinjaRMM documentation.
    
    Technical Implementation:
    This script uses the RunAsUser module to execute OneDrive queries in the context
    of the currently logged-on user, which is required because OneDrive configuration
    is stored per-user in HKCU and user-specific directories.
    
    1. OneDrive Sync Status Detection:
       - Reads SyncDiagnostics.log from user's OneDrive logs directory
       - Parses SyncProgressState codes to determine sync health
       - Status codes:
         * 16777216, 42, 0 = Up-to-date
         * 65536 = Paused (may be syncing)
         * 8194 = Not syncing
         * 1854 = Having syncing problems
       
       - Monitors time since last sync (warns if > 72 hours)
       - Converts UTC timestamps to local timezone for reporting
    
    2. Folder Redirection Detection:
       The script checks both Windows Shell Folders registry keys and OneDrive
       mount points to determine if user folders are redirected to OneDrive:
       
       - Desktop (Special folder: Personal Desktop)
       - Documents (Special folder: Personal)
       - Pictures (Special folder: My Pictures)
       - Music (Special folder: My Music)
       - Videos (Special folder: My Video)
       - Favorites
       
       Detection methodology:
       - Queries HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders
       - Checks if folder paths contain 'OneDrive' string
       - Cross-references with Win32_UserProfile redirection flags
    
    3. SharePoint Library Enumeration:
       OneDrive for Business can sync multiple SharePoint document libraries.
       The script discovers these by:
       
       - Reading ClientPolicy*.ini files from Business1 settings folder
       - These INI files contain library metadata:
         * DavUrlNamespace (WebDAV URL)
         * SiteTitle (SharePoint site name)
         * ItemCount (number of items in library)
       
       - Matching INI files to registry mount points:
         HKCU:\Software\SyncEngines\Providers\OneDrive
       
       - Calculating local disk usage per library:
         * Recursively measures files in mount point
         * Excludes SparseFile attribute (placeholder files)
         * Excludes nested mount points to prevent double-counting
         * Reports in GB (rounded to 2 decimals)
    
    4. Item Count Threshold:
       OneDrive has performance issues when syncing > 300,000 items.
       The script warns if total item count across all libraries exceeds 280,000.
       This threshold provides buffer before hitting Microsoft's limits.
    
    5. RunAsUser Module:
       Required to execute code in user context from SYSTEM context.
       The module:
       - Creates scheduled task with user credentials
       - Executes script block as user
       - Returns results to SYSTEM context
       - Automatically installs from PowerShell Gallery if missing
    
    6. HTML Dashboard Generation:
       Uses custom NinjaOne card functions to create formatted HTML output:
       - Get-NinjaOneCard: Creates bootstrap-styled card containers
       - Get-NinjaOneInfoCard: Creates info cards with key-value pairs
       - Responsive grid layout (col-xl-4 + col-xl-8)
       - Font Awesome icons for visual indicators
       - Color-coded status (green checkmark for redirected folders)
    
    Output Structure:
    - Left panel: OneDrive Config Details (sync status, folder redirection)
    - Right panel: Synced Libraries table (site name, URL, disk usage, item count)
    
    Temporary Files:
    - C:\temp\folderredirectionstatus.json (user folder data)
    - C:\temp\OneDriveLibraries.json (SharePoint library data)
    
    Security Considerations:
    - Temporarily changes execution policy if Restricted
    - Restores original execution policy on exit
    - Requires NuGet package provider installation
    - Installs PowerShell modules from Gallery
    
    Performance Notes:
    - Disk usage calculation can be slow for large libraries
    - Recursive file enumeration may timeout for > 100k files
    - Typical execution time: 10-30 seconds
    
    Use Cases:
    - Monitoring OneDrive sync health for support tickets
    - Verifying folder redirection deployment
    - Tracking SharePoint library usage and growth
    - Identifying sync performance issues before users report
    - Capacity planning for OneDrive storage

.EXAMPLE
    .\OneDrive-GetConfig.ps1
    
    Collects OneDrive configuration and generates HTML dashboard.

.NOTES
    File Name      : OneDrive-GetConfig.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and garbage collection
    - 2.0: Added comprehensive OneDrive monitoring
    - 1.0: Initial release
    
    Execution Context: SYSTEM (uses RunAsUser for user-context queries)
    Execution Frequency: Daily or on-demand
    Typical Duration: 10-30 seconds (depends on library size)
    Timeout Setting: 300 seconds (5 minutes) recommended
    
    User Interaction: None (runs silently in background)
    Restart Behavior: N/A (no system restart)
    
    NinjaRMM Fields Updated:
        - onedriveSyncClient (WYSIWYG HTML field with dashboard)
    
    Dependencies:
        - RunAsUser PowerShell module (auto-installed from PSGallery)
        - NuGet package provider 2.8.5.201 or higher
        - OneDrive for Business installed and configured
        - Active user session required
    
    Temporary Files Created:
        - C:\temp\folderredirectionstatus.json
        - C:\temp\OneDriveLibraries.json

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param()

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "OneDrive-GetConfig"
    
    $StartTime = Get-Date
    $OriginalExecutionPolicy = Get-ExecutionPolicy
    $ErrorActionPreference = 'Continue'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0

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
        Write-Output "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'WARN'  { $script:WarningCount++ }
            'ERROR' { $script:ErrorCount++ }
        }
    }

    function Get-NinjaOneCard {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$false)]
            [string]$Title,
            [Parameter(Mandatory=$true)]
            [string]$Body,
            [Parameter(Mandatory=$false)]
            [string]$Icon,
            [Parameter(Mandatory=$false)]
            [string]$TitleLink,
            [Parameter(Mandatory=$false)]
            [string]$Classes
        )
        
        $HTML = [System.Collections.Generic.List[String]]@()
        
        $HTML.Add('<div class="card flex-grow-1' + $(if ($Classes) { ' ' + $Classes }) + '">')
        
        if ($Title) {
            $HTML.Add('<div class="card-title-box"><div class="card-title">' + $(if ($Icon) { '<i class="' + $Icon + '"></i>&nbsp;&nbsp;' }) + $Title + '</div>')
            
            if ($TitleLink) {
                $HTML.Add('<div class="card-link-box"><a href="' + $TitleLink + '" target="_blank" class="card-link"><i class="fas fa-arrow-up-right-from-square" style="color: #337ab7;"></i></a></div>')
            }
            
            $HTML.Add('</div>')
        }
        
        $HTML.Add('<div class="card-body"><p class="card-text">' + $Body + '</p></div></div>')
        
        return $HTML -join ''
    }

    function Get-NinjaOneInfoCard {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$false)]
            [string]$Title,
            [Parameter(Mandatory=$true)]
            [PSCustomObject]$Data,
            [Parameter(Mandatory=$false)]
            [string]$Icon,
            [Parameter(Mandatory=$false)]
            [string]$TitleLink
        )
        
        $ItemsHTML = [System.Collections.Generic.List[String]]@()
        
        foreach ($Item in $Data.PSObject.Properties) {
            $ItemsHTML.Add('<p><b>' + $Item.Name + '</b><br />' + $Item.Value + '</p>')
        }
        
        return Get-NinjaOneCard -Title $Title -Body ($ItemsHTML -join '') -Icon $Icon -TitleLink $TitleLink
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if ($OriginalExecutionPolicy -eq 'Restricted') {
            Write-Log "Adjusting execution policy from Restricted to RemoteSigned" -Level INFO
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
        }
        
        Write-Log "Checking for RunAsUser module..." -Level INFO
        
        if (Get-Command Invoke-AsCurrentUser -ErrorAction SilentlyContinue) {
            Write-Log "RunAsUser module already present" -Level SUCCESS
        } else {
            Write-Log "Installing RunAsUser module dependencies..." -Level INFO
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
            Install-Module -Name RunAsUser -Confirm:$false -Force -ErrorAction Stop
            Write-Log "RunAsUser module installed successfully" -Level SUCCESS
        }
        
        Write-Log "Preparing user-context script block..." -Level INFO
        
        $ScriptBlock = {
            Function Get-FolderRedirectionStatus {
                $User = whoami
                $SID = $User | ForEach-Object { ([System.Security.Principal.NTAccount]$_).Translate([System.Security.Principal.SecurityIdentifier]).Value }
                $UserProfile = Get-CimInstance Win32_UserProfile -ErrorAction Stop | Where-Object SID -EQ $SID
                $UserFolders = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders\' -ErrorAction Stop | Select-Object 'Personal', 'My Video', 'My Pictures', 'Desktop', 'Favorites', 'My Music'

                $typeOneDrive = 'Business1'
                $warningFileSyncedDelayHours = 72
                $statusOneDriveUpToDate = 16777216, 42, 0
                $statusOneDrivePaused = 65536
                $statusOneDriveNotSyncing = 8194
                $statusOneDriveSyncingProblems = 1854

                Function Convert-ResultCodeToName {
                    param([Parameter(Mandatory=$true)][int]$status)
                    
                    switch ($status) {
                        { ($statusOneDriveUpToDate.Contains($_)) } { return 'Up-to-Date' }
                        $statusOneDrivePaused { return 'Paused - Might be Syncing' }
                        $statusOneDriveNotSyncing { return 'Not syncing' }
                        $statusOneDriveSyncingProblems { return 'Having syncing problems' }
                        default { return "Unknown - ($status)" }
                    }
                }

                $folderMask = "$env:localAppData\Microsoft\OneDrive\logs\$typeOneDrive\*.log"
                $files = Get-ChildItem -Path $folderMask -Filter SyncDiagnostics.log | Where-Object { $_.LastWriteTime -gt [datetime]::Now.AddMinutes(-1440) }
                $progressState = Get-Content $files | Where-Object { $_.Contains('SyncProgressState') }
                $checkLogDate = Get-Content $files | Where-Object { $_.Contains('UtcNow:') }

                $status = $progressState | ForEach-Object { -split $_ | Select-Object -Index 1 }
                $resultText = Convert-ResultCodeToName $status
                $state = ($progressState -match 16777216) -or ($progressState -match 42) -or ($progressState -match 0)

                $rawLogDate = $checkLogDate | ForEach-Object { -split $_ | Select-Object -Index 1 }
                $convertLogDate = $rawLogDate -as [DateTime]
                $utcLogDate = $convertLogDate.ToUniversalTime()
                $timezone = [System.TimeZoneInfo]::Local.DisplayName

                $dateNow = Get-Date
                $utcNow = $dateNow.ToUniversalTime()
                $timeSpan = New-TimeSpan -Start $utcLogDate -End $utcNow
                $difference = $timeSpan.Hours

                $results = @{}
                $results.StatusCode = $status
                $results.LastSynced = $convertLogDate

                try {
                    if ($state -eq $true -and $difference -le $warningFileSyncedDelayHours) {
                        $results.SyncHealth = "$resultText"
                    } elseif ($state -eq $true -and $difference -gt $warningFileSyncedDelayHours) {
                        $results.SyncHealth = "$resultText (OneDrive appears active but no files synced in $difference hours)"
                    } elseif ($progressState -eq $statusOneDrivePaused -and $difference -le $warningFileSyncedDelayHours) {
                        $results.SyncHealth = "$resultText (User logged in | OneDrive paused | Synced $difference hours ago)"
                    } elseif ($progressState -eq $statusOneDrivePaused -and $difference -gt $warningFileSyncedDelayHours) {
                        $results.SyncHealth = "$resultText (User logged in | OneDrive paused | Synced $difference hours ago)"
                    } elseif ($state -eq $false) {
                        $results.SyncHealth = "OneDrive Not Syncing or Signed In"
                    } else {
                        $results.SyncHealth = "$resultText ($status | Synced $difference hours ago)"
                    }
                } catch {
                    $results.SyncHealth = "Error: $($_.Exception.Message)"
                }

                return [PSCustomObject]@{
                    User                = $User
                    SID                 = $SID
                    Computer            = $env:COMPUTERNAME
                    SyncHealth          = $results.SyncHealth
                    LastSynced          = If ($convertLogDate) { "$($convertLogDate) $($timezone)" } else { 'Never' }
                    DesktopRedirected   = $UserProfile.Desktop.Redirected -or $UserFolders.Desktop -match 'OneDrive'
                    DocumentsRedirected = $UserProfile.documents.redirected -or $UserFolders.Personal -match 'OneDrive'
                    PicturesRedirected  = $UserProfile.Pictures.redirected -or $UserFolders.'My Pictures' -match 'OneDrive'
                    DocumentsPath       = $UserFolders.Personal
                    VideosPath          = $UserFolders.'My Video'
                    PicturesPath        = $UserFolders.'My Pictures'
                    MusicPath           = $UserFolders.'My Music'
                    DesktopPath         = $UserFolders.Desktop
                    FavoritesPath       = $UserFolders.Favorites
                }
            }

            Get-FolderRedirectionStatus | ConvertTo-Json | Out-File 'C:\temp\folderredirectionstatus.json'

            $IniFiles = Get-ChildItem "$ENV:LOCALAPPDATA\Microsoft\OneDrive\settings\Business1" -Filter 'ClientPolicy*' -ErrorAction SilentlyContinue
            
            if (-not $IniFiles) {
                'No Sharepoint Libraries synced.' | ConvertTo-Json | Out-File 'C:\temp\OneDriveLibraries.json'
                return
            }

            $OneDriveProviders = Get-ChildItem -Path 'HKCU:\Software\SyncEngines\Providers\OneDrive' | ForEach-Object { Get-ItemProperty $_.PSpath }
            $LatestProviders = $OneDriveProviders | Group-Object -Property MountPoint | ForEach-Object {
                $_.Group | Sort-Object -Property LastModifiedTime -Descending | Select-Object -First 1
            }
            $AllMountPoints = $LatestProviders.MountPoint

            $SyncedLibraries = foreach ($inifile in $IniFiles) {
                $IniContent = Get-Content $inifile.FullName -Encoding Unicode
                $ItemCount = ($IniContent | Where-Object { $_ -like 'ItemCount*' }) -split '= ' | Select-Object -Last 1
                $URL = ($IniContent | Where-Object { $_ -like 'DavUrlNamespace*' }) -split '= ' | Select-Object -Last 1
                $Mountpoint = ($LatestProviders | Where-Object { $_.UrlNamespace -eq $URL }).MountPoint

                if (Test-Path $Mountpoint -ErrorAction SilentlyContinue) {
                    $FilteredItems = Get-ChildItem $Mountpoint -Attributes !SparseFile -Recurse | Where-Object {
                        $file = $_.FullName | Out-String
                        $isSubfolder = $AllMountPoints | Where-Object { $file.StartsWith($_) -and $file -ne $_ -and $_ -ne $Mountpoint }
                        $isSubfolder.Count -eq 0
                    }
                    $diskUsage = [math]::Truncate((($FilteredItems | Measure-Object -Property Length -Sum).Sum / 1GB * 100)) / 100
                }

                [PSCustomObject]@{
                    'Site Name'       = ($IniContent | Where-Object { $_ -like 'SiteTitle*' }) -split '= ' | Select-Object -Last 1
                    'Site URL'        = $URL
                    'Local Disk Used' = If ($diskUsage) { "$diskUsage GB" } elseif ($diskUsage -eq 0) { '< 10 MB' } else { 'Err' }
                    'Item Count'      = $ItemCount
                }
            }

            $SyncedLibraries | ConvertTo-Json | Out-File 'C:\temp\OneDriveLibraries.json'
        }

        Write-Log "Executing OneDrive queries in user context..." -Level INFO
        
        New-Item -ItemType Directory -Path 'C:\temp' -Force -ErrorAction SilentlyContinue | Out-Null
        $null = Invoke-AsCurrentUser -ScriptBlock $ScriptBlock -ErrorAction Stop
        
        Write-Log "User-context queries completed" -Level SUCCESS
        
        Write-Log "Processing results..." -Level INFO
        
        $frs = Get-Content 'C:\temp\folderredirectionstatus.json' -ErrorAction Stop | ConvertFrom-Json
        $SyncedLibraries = Get-Content 'C:\temp\OneDriveLibraries.json' -ErrorAction Stop | ConvertFrom-Json
        
        $noSharePoint = $false
        
        if ($SyncedLibraries -eq 'No Sharepoint Libraries synced.') {
            Write-Log "No SharePoint libraries found" -Level INFO
            $noSharePoint = $true
        } else {
            $totalItems = ($SyncedLibraries.'Item Count' | Measure-Object -Sum).Sum
            
            if ($totalItems -gt 280000) {
                Write-Log "WARNING: Syncing more than 280k files ($totalItems total)" -Level WARN
                Write-Output "Unhealthy - Currently syncing more than 280k files. Please investigate."
            } else {
                Write-Log "Item count within healthy range: $totalItems items" -Level SUCCESS
                Write-Output "Healthy - Syncing less than 280k files, or none."
            }
        }
        
        $frs
        $SyncedLibraries
        
        Write-Log "Generating HTML dashboard..." -Level INFO
        
        $ODHTML = ''
        $LibraryHTML = ''
        
        if ($frs) {
            $ODHTML = (Get-NinjaOneInfoCard -Title 'OneDrive Config Details' -Data $frs -Icon 'fas fa-cloud" style="color:#0364b8;') -replace 'True', '<i class="fas fa-check-circle" style="color:#26A644;"></i>&nbsp;&nbsp;True'
        }
        
        if ($SyncedLibraries -and -not $noSharePoint) {
            $LibraryTableHTML = $SyncedLibraries | ConvertTo-Html -As Table -Fragment
            $LibraryHTML = Get-NinjaOneCard -Title 'Synced Libraries' -Body $LibraryTableHTML -Icon 'fas fa-cloud" style="color:#0364b8;'
        }
        
        $CombinedHTML = '<div class="row g-1 rows-cols-2">' +
            '<div class="col-xl-4 col-lg-4 col-md-4 col-sm-4 d-flex">' + $ODHTML +
            '</div><div class="col-xl-8 col-lg-8 col-md-8 col-sm-8 d-flex">' + $LibraryHTML +
            '</div></div>'
        
        $CombinedHTML | Ninja-Property-Set-Piped -Name onedriveSyncClient
        
        Write-Log "HTML dashboard updated in NinjaRMM" -Level SUCCESS
        Write-Log "OneDrive monitoring completed successfully" -Level SUCCESS
        
    } catch {
        Write-Log "OneDrive monitoring failed: $($_.Exception.Message)" -Level ERROR
        Write-Output "Could not execute: $($_.Exception.Message)"
        $script:ExitCode = 1
    }
}

end {
    try {
        if ($OriginalExecutionPolicy -eq 'Restricted') {
            Set-ExecutionPolicy -ExecutionPolicy $OriginalExecutionPolicy -Force
            Write-Log "Restored execution policy to $OriginalExecutionPolicy" -Level INFO
        }
        
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "Warnings: $script:WarningCount, Errors: $script:ErrorCount" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
