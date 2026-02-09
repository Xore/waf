# Function to get per-user installed apps from the registry
function Get-UserRegistryApps {
    param([string]$UserHivePath, [string]$Username)

    $apps = @()
    try {
        # Load the user hive
        reg load "HKU\$Username" "$UserHivePath" 2>$null
        $keyPath = "HKU\$Username\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        if (Test-Path $keyPath) {
            $apps = Get-ItemProperty "$keyPath\*" | Select-Object DisplayName, DisplayVersion, Publisher, InstallLocation
        }
    } catch {
        Write-Warning "Could not load registry hive for $Username"
    } finally {
        # Unload hive
        reg unload "HKU\$Username" 2>$null
    }
    return $apps
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

# Function to get per-user executables from AppData
function Get-UserAppDataExecutables {
    param([string]$UserProfile)

    $paths = @("$UserProfile\AppData\Local", "$UserProfile\AppData\Roaming")
    $executables = @()

    foreach ($path in $paths) {
        if (Test-Path $path) {
            $executables += Get-ChildItem -Path $path -Recurse -Include *.exe -ErrorAction SilentlyContinue |
                Select-Object FullName, LastWriteTime
        }
    }

    return $executables
}

# Get all user profiles under C:\Users
$users = Get-ChildItem -Path "C:\Users" -Directory | Where-Object { $_.Name -notin @("Public", "Default", "Default User", "All Users") }

# Iterate through each user profile
$allUsersApps = @()

foreach ($user in $users) {
    $username = $user.Name
    $userProfile = $user.FullName
    $ntuserDat = Join-Path $userProfile "NTUSER.DAT"

    Write-Host "Scanning $username..."

    # Get registry apps
    $regApps = @()
    if (Test-Path $ntuserDat) {
        $regApps = Get-UserRegistryApps -UserHivePath $ntuserDat -Username $username
    }

    # Get AppData executables
    $appDataApps = Get-UserAppDataExecutables -UserProfile $userProfile

    # Save results
    $allUsersApps += [PSCustomObject]@{
        Username = $username 
        RegistryApps = $regApps
        AppDataExecutables = $appDataApps
    }
}

# output that stuff
$allUsersHTML = $allUsersApps  | ConvertTo-Json
$appsCard = Get-NinjaOneCard -Title 'Installed for local user' -Body $allUsersHTML -Icon 'fas style="color:#0364b8;'
$CombinedHTML = '<div class="row g-1 rows-cols-2">' + 
'<div class="col-xl-4 col-lg-4 col-md-4 col-sm-4 d-flex"> </div>' + $appsCard +
'</div>'

# put it in a custom field
$CombinedHTML | Ninja-Property-Set-Piped -Name localinstalled


