# ===================================================================
# PowerShell-Skript: Verknüpfungen erstellen und auf alle Desktops kopieren
# Einschließlich aller Benutzer, Public Desktop und Default User Profile
# ===================================================================

# ===== KONFIGURATION =====
$TempFolder = "C:\Temp"
$ForceOverwrite = $true

# ===== VERKNÜPFUNGEN ERSTELLEN =====
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "SCHRITT 1: Verknüpfungen erstellen" -ForegroundColor Cyan
Write-Host "=" * 70

# Sicherstellen, dass Temp-Ordner existiert
if (-not (Test-Path $TempFolder)) {
    New-Item -Path $TempFolder -ItemType Directory -Force | Out-Null
    Write-Host "Temp-Ordner erstellt: $TempFolder" -ForegroundColor Yellow
}

# COM-Objekt für Verknüpfungen erstellen
$WshShell = New-Object -COMObject WScript.Shell

# Verknüpfung 1: CEPROS Testsystem
Write-Host "[1/3] Erstelle: CEPROS Testsystem.lnk" -ForegroundColor Green
$Shortcut = $WshShell.CreateShortcut("$TempFolder\CEPROS Testsystem.lnk")
$Shortcut.TargetPath = "C:\Program Files\CONTACT CIM Database Desktop 11.7\cdbpc.exe"
$Shortcut.Arguments = '--url https://biecdb20.de.mgp.int/'
$Shortcut.Save()

# Verknüpfung 2: CEPROS 11.7
Write-Host "[2/3] Erstelle: CEPROS 11.7.lnk" -ForegroundColor Green
$Shortcut = $WshShell.CreateShortcut("$TempFolder\CEPROS 11.7.lnk")
$Shortcut.TargetPath = "C:\Program Files\CONTACT CIM Database Desktop 11.7\cdbpc.exe"
$Shortcut.Save()

# Verknüpfung 3: Workspaces Desktop
if($env:createWorkspacesDesktopShortcut -eq 'true') {
  Write-Host "[3/3] Erstelle: Workspaces Desktop.lnk" -ForegroundColor Green
  $Shortcut = $WshShell.CreateShortcut("$TempFolder\Workspaces Desktop.lnk")
  $Shortcut.TargetPath = "C:\Program Files\CONTACT Workspaces Desktop\bin\WorkspacesDesktop.exe"
  $Shortcut.Save()
}

Write-Host "`nAlle Verknüpfungen erfolgreich erstellt!`n" -ForegroundColor Green

# ===== DATEIEN ZUM KOPIEREN SAMMELN =====
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "SCHRITT 2: Dateien auf alle Desktops kopieren" -ForegroundColor Cyan
Write-Host "=" * 70

# Alle .lnk Dateien im Temp-Ordner finden
$FilesToCopy = Get-ChildItem -Path $TempFolder -Filter "*.lnk" -File

if ($FilesToCopy.Count -eq 0) {
    Write-Host "WARNUNG: Keine .lnk Dateien in $TempFolder gefunden!" -ForegroundColor Yellow
    exit
}

Write-Host "Gefundene Dateien zum Kopieren:" -ForegroundColor Cyan
foreach ($File in $FilesToCopy) {
    Write-Host "  - $($File.Name)" -ForegroundColor Gray
}
Write-Host ""

# ===== KOPIER-FUNKTION =====
$SuccessCount = 0
$FailCount = 0

function Copy-FilesToDesktop {
    param(
        [string]$DestinationPath,
        [string]$Description
    )
    
    try {
        if (Test-Path $DestinationPath) {
            foreach ($File in $FilesToCopy) {
                $DestFile = Join-Path $DestinationPath $File.Name
                Copy-Item -Path $File.FullName -Destination $DestFile -Force:$ForceOverwrite -ErrorAction Stop
            }
            Write-Host "[OK] $Description" -ForegroundColor Green
            Write-Host "     -> $DestinationPath ($($FilesToCopy.Count) Dateien)" -ForegroundColor Gray
            $script:SuccessCount++
        } else {
            Write-Host "[SKIP] $Description (Pfad existiert nicht)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[FEHLER] $Description" -ForegroundColor Red
        Write-Host "         $($_.Exception.Message)" -ForegroundColor Red
        $script:FailCount++
    }
}

# ===== KOPIEREN AUF ALLE DESKTOPS =====

# 1. PUBLIC DESKTOP
$PublicDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
Copy-FilesToDesktop -DestinationPath $PublicDesktop -Description "Public Desktop"

# 2. DEFAULT USER PROFILE DESKTOP
$DefaultUserDesktop = "C:\Users\Default\Desktop"
Copy-FilesToDesktop -DestinationPath $DefaultUserDesktop -Description "Default User Profile Desktop"

# 3. ALLE BENUTZER-DESKTOPS
$UsersPath = "C:\Users"
if (Test-Path $UsersPath) {
    $UserFolders = Get-ChildItem -Path $UsersPath -Directory -ErrorAction SilentlyContinue
    
    foreach ($UserFolder in $UserFolders) {
        # Überspringe System-Ordner
        if ($UserFolder.Name -in @("Public", "Default", "All Users", "Default User")) {
            continue
        }
        
        $UserDesktop = Join-Path $UserFolder.FullName "Desktop"
        Copy-FilesToDesktop -DestinationPath $UserDesktop -Description "Benutzer: $($UserFolder.Name)"
    }
}

# ===== ZUSAMMENFASSUNG =====
Write-Host "ZUSAMMENFASSUNG" -ForegroundColor Cyan
Write-Host "Erstellte Verknüpfungen: $($FilesToCopy.Count)" -ForegroundColor Cyan
Write-Host "Erfolgreich kopiert auf: $SuccessCount Desktop(s)" -ForegroundColor Green
Write-Host "Fehler: $FailCount" -ForegroundColor $(if ($FailCount -gt 0) { "Red" } else { "Gray" })
Write-Host "Kopierte Dateien pro Desktop: $($FilesToCopy.Count)" -ForegroundColor Cyan


Remove-Item "$TempFolder\*.lnk" -Force
Write-Host "Temp-Dateien gelöscht." -ForegroundColor Green
