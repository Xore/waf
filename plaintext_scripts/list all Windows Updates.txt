<# 
.SYNOPSIS
  Zeigt die Historie von Windows Updates an (Datum, Titel, KB, Ergebnis).
  Bevorzugt PSWindowsUpdate:Get-WUHistory. Fallback: WindowsUpdate-Eventlog. Zweiter Fallback: Get-HotFix.
  
<# 
function Ensure-PSWindowsUpdate {
    try {
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host "PSWindowsUpdate nicht gefunden. Versuche Installation im CurrentUser-Scope..."
            $prev = [Net.ServicePointManager]::SecurityProtocol
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -Confirm:$false | Out-Null
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
            Install-Module PSWindowsUpdate -Scope CurrentUser -Force -AllowClobber -Confirm:$false
            [Net.ServicePointManager]::SecurityProtocol = $prev
        }
        Import-Module PSWindowsUpdate -ErrorAction Stop
        return $true
    } catch {
        Write-Host "PSWindowsUpdate konnte nicht geladen/ installiert werden: $($_.Exception.Message)"
        exit $true
    }
}#>
#>

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Get-History-From-PSWindowsUpdate {
    try {
        $items = Get-WUHistory -Last 2000 -ErrorAction Stop | ForEach-Object {
            [PSCustomObject]@{
                Date        = $_.Date
                Title       = $_.Title
                KB          = ($_.KB -join ',')
                Result      = $_.Result
                Operation   = $_.Operation
                Source      = 'PSWindowsUpdate'
            }
        }
        return $items
    } catch {
        Write-Host "Get-WUHistory fehlgeschlagen: $($_.Exception.Message)"
        exit $true
    }
}

# Hauptlogik
$all = @()
Write-Host "Checking if PSWindowsUpdate is installed"
if ( -not (Get-Module -ListAvailable -Name NuGet)) {
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
}
if ( -not (Get-Module -ListAvailable -Name PSDiscoveryProtocol)) {
    Install-Module -Name PSWindowsUpdate -Repository PSGallery -Confirm:$false -Force | Out-Null
}
Set-ExecutionPolicy Bypass -Scope Process
Import-Module PSWindowsUpdate -ErrorAction Stop
$fromPSWU = Get-History-From-PSWindowsUpdate
if ($fromPSWU.Count -gt 0) { $all += $fromPSWU }
if ($all.Count -eq 0) {
    Write-Host "Es konnten keine Update-Historie-Daten ermittelt werden. Führen Sie die PowerShell als Administrator aus und prüfen Sie die Eventlogs/Modulinstallation."
    exit $true
} else {
    $all = $all | Sort-Object Date -Descending
    # Construct report
    $Report = New-Object System.Collections.Generic.List[string]
    $Report.Add("
<div class='card flex-grow-1'>
  <div class='card-title-box'>
    <div class='card-title'><i class='fas fa-building'></i>&nbsp;&nbsp;All installed Windows Updates</div>
  </div>
  <div class='card-body'>
    <p class='card-text'></p>
    <table>
      <thead>
        <tr>
           <th>Date</th>
           <th>Title</th>
           <th>KB</th>
           <th>Result</th>
        </tr>
      </thead>
        <tbody>
  ")
    foreach($update in $all)
     {
        $Report.Add("<tr>")
        $Report.Add("<td>$($update.Date)</td>")
        $Report.Add("<td>$($update.Title)</td>")
        $Report.Add("<td>$($update.KB)</td>")
        $Report.Add("<td>$($update.Result)</td>")
        $Report.Add("</tr>")
     }

     $Report.Add("
    </tbody>
  </table>
  </div>
</div>
")
    # Output Report
    # $Report | Ninja-Property-Set-Piped -Name grouppolicy
    #$Report | c:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe set $env:customFieldName --stdin
    $Report | Ninja-Property-Set-Piped -Name installedUpdates
    Write-Host "updated custom field"
    exit $false
}