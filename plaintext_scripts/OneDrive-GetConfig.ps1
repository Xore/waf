$executionpolicy = Get-ExecutionPolicy
If ($executionpolicy -eq 'Restricted') {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
}
function Get-NinjaOneCard($Title, $Body, [string]$Icon, [string]$TitleLink, [String]$Classes) {
    <#
    $Info = 'This is the body of a card it is wrapped in a paragraph'

    Get-NinjaOneCard -Title "Tenant Details" -Data $Info
    #>

    [System.Collections.Generic.List[String]]$OutputHTML = @()

    $OutputHTML.add('<div class="card flex-grow-1' + $(if ($classes) {
                ' ' + $classes 
            }) + '" >')

    if ($Title) {
        $OutputHTML.add('<div class="card-title-box"><div class="card-title" >' + $(if ($Icon) {
                    '<i class="' + $Icon + '"></i>&nbsp;&nbsp;' 
                }) + $Title + '</div>')

        if ($TitleLink) {
            $OutputHTML.add('<div class="card-link-box"><a href="' + $TitleLink + '" target="_blank" class="card-link" ><i class="fas fa-arrow-up-right-from-square" style="color: #337ab7;"></i></a></div>')
        }

        $OutputHTML.add('</div>')
    }

    $OutputHTML.add('<div class="card-body" >')
    $OutputHTML.add('<p class="card-text" >' + $Body + '</p>')
       
    $OutputHTML.add('</div></div>')

    return $OutputHTML -join ''
    
}
function Get-NinjaOneInfoCard($Title, $Data, [string]$Icon, [string]$TitleLink) {
    <#
    $TenantDetailsItems = [PSCustomObject]@{
        'Name' = $Customer.displayName
        'Default Domain' = $Customer.defaultDomainName
        'Tenant ID' = $Customer.customerId
        'Domains' = $customerDomains
        'Admin Users' = ($AdminUsers | ForEach-Object {"$($_.displayname) ($($_.userPrincipalName))"}) -join ', '
        'Creation Date' = $TenantDetails.createdDateTime
    }

    Get-NinjaOneInfoCard -Title "Tenant Details" -Data $TenantDetailsItems
    #>

    [System.Collections.Generic.List[String]]$ItemsHTML = @()

    foreach ($Item in $Data.PSObject.Properties) {
        $ItemsHTML.add('<p ><b >' + $Item.Name + '</b><br />' + $Item.Value + '</p>')
    }

    return Get-NinjaOneCard -Title $Title -Body ($ItemsHTML -join '') -Icon $Icon -TitleLink $TitleLink
       
}

Try {

    If (Get-Command invoke-ascurrentuser -ErrorAction SilentlyContinue) {
        Write-Host 'RunAsUser Module Present'
    } else {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module -Name RunAsUser -Confirm:$false -Force -ErrorAction Stop
    }
    $ScriptBlock = {
        Function Get-FolderRedirectionStatus {
            $User = whoami
            $SID = $user | ForEach-Object { ([System.Security.Principal.NTAccount]$_).Translate([System.Security.Principal.SecurityIdentifier]).Value }
            $UserProfile = (Get-CimInstance Win32_UserProfile -ErrorAction Stop | Where-Object SID -EQ $SID)
            $UserFolders = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders\' -ErrorAction Stop | Select-Object 'Personal', 'My Video', 'My Pictures', 'Desktop', 'Favorites', 'My Music'

            $typeOneDrive = 'Business1'
            $warningFileSyncedDelayHours = 72                       
            $statusOneDriveUpToDate = 16777216, 42, 0     # Up-to-date - Array
            $statusOneDrivePaused = 65536                 # Paused - May be syncing
            $statusOneDriveNotSyncing = 8194              # Not syncing
            $statusOneDriveSyncingProblems = 1854         # Having syncing problems

            Function Convert-ResultCodeToName {
                # Evaluates response codes and converts to human-readable
                param([Parameter(Mandatory = $true)]
                    [int] $status
                )
                switch ($status) {
                    { ($statusOneDriveUpToDate.Contains($_)) } {
                        $statusName = 'Up-to-Date'
                    }
                    $statusOneDrivePaused {
                        $statusName = 'Paused - Might be Syncing'
                    }
                    $statusOneDriveNotSyncing {
                        $statusName = 'Not syncing'
                    }
                    $statusOneDriveSyncingProblems {
                        $statusName = 'Having syncing problems'
                    }
                    default {
                        $statusName = "Unknown - ($status)" 
                    }
                }
                return $statusName
            }

            $folderMask = "$env:localAppData\Microsoft\OneDrive\logs\" + $typeOneDrive + '\*.log'  
            $files = Get-ChildItem -Path $folderMask -Filter SyncDiagnostics.log | Where-Object { $_.LastWriteTime -gt [datetime]::Now.AddMinutes(-1440) }
            $progressState = Get-Content $files | Where-Object { $_.Contains('SyncProgressState') } 
            $checkLogDate = Get-Content $files | Where-Object { $_.Contains('UtcNow:') }  

            # Parse SyncProgressState - Split off code
            $status = $progressState | ForEach-Object { -split $_ | Select-Object -Index 1 }

            # Create result text
            $resultText = Convert-ResultCodeToName $status

            # Checking if progressState indicates OneDrive is running
            $state = ($progressState -match 16777216) -or ($progressState -match 42) -or ($progressState -match 0) 

            # Grab first insance of UTC time from log and split off into ISO 8601
            $rawLogDate = $checkLogDate | ForEach-Object { -split $_ | Select-Object -Index 1 }

            # Convert text into [DateTime] to be safe and UTC
            $convertLogDate = $rawLogDate -as [DateTime]
            $utcLogDate = $convertLogDate.ToUniversalTime()
            $timezone = [System.TimeZoneInfo]::Local.DisplayName

            # Grab current DateTime and convert to UTC
            $dateNow = Get-Date
            $utcNow = $dateNow.ToUniversalTime()

            # Calculate timespan between times
            $timeSpan = New-TimeSpan -Start $utcLogDate -End $utcNow
            $difference = $timeSpan.hours
            $results = @{}
            $results.StatusCode = $status
            $results.LastSynced = $convertLogDate
            try {
                if ($state -eq $true -and $difference -le $warningFileSyncedDelayHours) {
                    $results.SyncHealth = "$resultText"
                } elseif ($state -eq $true -and $difference -gt $warningFileSyncedDelayHours) {
                    $results.SyncHealth = "$resultText (Onedrive appears active but no files synced in $difference hours)"
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

            return [pscustomobject] @{ 
                User                = $user 
                SID                 = $SID 
                Computer            = $env:COMPUTERNAME
                SyncHealth          = $results.SyncHealth
                LastSynced          = If ($convertLogDate) {"$($convertLogDate) $($timezone)"} else {'Never'}
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
        Get-FolderRedirectionStatus | ConvertTo-Json | Out-File 'c:\temp\folderredirectionstatus.json'

        $IniFiles = Get-ChildItem "$ENV:LOCALAPPDATA\Microsoft\OneDrive\settings\Business1" -Filter 'ClientPolicy*' -ErrorAction SilentlyContinue
        if (!$IniFiles) {
            'No Sharepoint Libraries synced.' | ConvertTo-Json | Out-File 'C:\temp\OneDriveLibraries.json'
            exit 1
        }
        $OneDriveProviders = Get-ChildItem -Path 'HKCU:\Software\SyncEngines\Providers\OneDrive' | ForEach-Object { Get-ItemProperty $_.PSpath }
        $LatestProviders = $OneDriveProviders | Group-Object -Property MountPoint | ForEach-Object {
            $_.Group | Sort-Object -Property LastModifiedTime -Descending | Select-Object -First 1
        }
        $AllMountPoints = $LatestProviders.MountPoint
        $SyncedLibraries = foreach ($inifile in $IniFiles) {
            $IniContent = Get-Content $inifile.fullname -Encoding Unicode
            $ItemCount = ($IniContent | Where-Object { $_ -like 'ItemCount*' }) -split '= ' | Select-Object -Last 1
            $URL = ($IniContent | Where-Object { $_ -like 'DavUrlNamespace*' }) -split '= ' | Select-Object -Last 1
            $Mountpoint = ($LatestProviders | Where-Object { $_.UrlNamespace -eq $URL }).MountPoint
            If (Test-Path $Mountpoint -ErrorAction SilentlyContinue) {
                $FilteredItems = Get-ChildItem $Mountpoint -Attributes !SparseFile -Recurse | Where-Object {
                    # Exclude if item is a subfolder of another mountpoint
                    $file = $_.FullName | Out-String
                    $isSubfolder = $AllMountPoints | Where-Object { $file.StartsWith($_) -and $file -ne $_ -and $_ -ne $Mountpoint }
                    $isSubfolder.Count -eq 0
                }
                $diskUsage = $([math]::Truncate((($FilteredItems | Measure-Object -Property Length -Sum).Sum / 1GB * 100)) / 100)
            }
            [PSCustomObject]@{
                'Site Name'       = ($IniContent | Where-Object { $_ -like 'SiteTitle*' }) -split '= ' | Select-Object -Last 1
                'Site URL'        = $URL
                #'Mount Point'     = $Mountpoint
                'Local Disk Used' = If ($diskUsage) {
                    "$diskUsage GB"
                } elseif ($diskUsage -eq 0) {
                    '< 10 MB'
                } else {
                    'Err'
                }
                'Item Count'      = $ItemCount
            }
        }
        $SyncedLibraries | ConvertTo-Json | Out-File 'C:\temp\OneDriveLibraries.json'
    }

    New-Item -ItemType Directory -Path 'C:\temp' -ErrorAction SilentlyContinue
    $null = Invoke-AsCurrentUser -ScriptBlock $ScriptBlock -ErrorAction Stop

    $frs = (Get-Content 'c:\temp\folderredirectionstatus.json' | ConvertFrom-Json)
    $SyncedLibraries = (Get-Content 'C:\temp\OneDriveLibraries.json' | ConvertFrom-Json)
    if (($SyncedLibraries.'Item count' | Measure-Object -Sum).sum -gt '280000') {
        Write-Host 'Unhealthy - Currently syncing more than 280k files. Please investigate.'
    } elseif ($SyncedLibraries -eq 'No Sharepoint Libraries synced.') {
        Write-Host 'No Sharepoint Libraries found.'
        $noSP = $true
    } else {
        Write-Host 'Healthy - Syncing less than 280k files, or none.'
    }

    # outputting for activity log
    $frs  
    $SyncedLibraries

    If ($frs) {
        $ODHTML = (Get-NinjaOneInfoCard -Title 'OneDrive Config Details' -Data $frs -Icon 'fas fa-cloud" style="color:#0364b8;') -replace 'True', '<i class="fas fa-check-circle" style="color:#26A644;"></i>&nbsp;&nbsp;True'
    }
    If ($SyncedLibraries -and -not $noSP) {
        $LibraryTableHTML = $SyncedLibraries | ConvertTo-Html -As Table -Fragment
        $LibraryHTML = Get-NinjaOneCard -Title 'Synced Libraries' -Body $LibraryTableHTML -Icon 'fas fa-cloud" style="color:#0364b8;'
    }
    $CombinedHTML = '<div class="row g-1 rows-cols-2">' + 
    '<div class="col-xl-4 col-lg-4 col-md-4 col-sm-4 d-flex">' + $ODHTML + 
    '</div><div class="col-xl-8 col-lg-8 col-md-8 col-sm-8 d-flex">' + $LibraryHTML +
    '</div></div>'
    $CombinedHTML | Ninja-Property-Set-Piped -Name onedriveSyncClient

} catch {
    Write-Host "Could not execute `n`n$($_.Exception.Message)"
}

If ($executionpolicy -eq 'Restricted') {
    Set-ExecutionPolicy -ExecutionPolicy $executionpolicy -Force
}
