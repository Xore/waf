<#
.SYNOPSIS
    Vollständige Deinstallation von PuTTY
.DESCRIPTION
    Dieses Script entfernt PuTTY vollständig vom System:
    - Löscht Programmdateien aus Program Files
    - Entfernt Benutzereinstellungen aus AppData
    - Bereinigt Registry-Einträge
.NOTES
    Erfordert Administratorrechte für vollständige Ausführung
#>

# Funktion zur Überprüfung von Administratorrechten
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Warnung wenn keine Adminrechte
if (-not (Test-Administrator)) {
    Write-Warning "Dieses Script sollte mit Administratorrechten ausgeführt werden für vollständige Deinstallation."
    Write-Host "Fahre trotzdem fort..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

Write-Host "=== PuTTY Deinstallation ===" -ForegroundColor Cyan
Write-Host ""

# 1. Programmdateien löschen
Write-Host "[1/3] Lösche Programmdateien..." -ForegroundColor Yellow

$programPaths = @(
    "$env:ProgramFiles\PuTTY",
    "${env:ProgramFiles(x86)}\PuTTY"
)

foreach ($path in $programPaths) {
    if (Test-Path $path) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            Write-Host "  ✓ Gelöscht: $path" -ForegroundColor Green
        }
        catch {
            Write-Host "  ✗ Fehler beim Löschen von $path : $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "  - Nicht gefunden: $path" -ForegroundColor Gray
    }
}

# 2. Benutzereinstellungen entfernen
Write-Host "`n[2/3] Entferne Benutzereinstellungen..." -ForegroundColor Yellow

$appDataPath = "$env:APPDATA\PuTTY"

if (Test-Path $appDataPath) {
    try {
        Remove-Item -Path $appDataPath -Recurse -Force -ErrorAction Stop
        Write-Host "  ✓ Gelöscht: $appDataPath" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Fehler beim Löschen von $appDataPath : $_" -ForegroundColor Red
    }
}
else {
    Write-Host "  - Nicht gefunden: $appDataPath" -ForegroundColor Gray
}

# 3. Registry bereinigen
Write-Host "`n[3/3] Bereinige Registry..." -ForegroundColor Yellow

$registryPaths = @(
    "HKCU:\Software\SimonTatham",
    "HKLM:\Software\SimonTatham",
    "HKLM:\Software\WOW6432Node\SimonTatham"
)

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        try {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop
            Write-Host "  ✓ Gelöscht: $regPath" -ForegroundColor Green
        }
        catch {
            Write-Host "  ✗ Fehler beim Löschen von $regPath : $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "  - Nicht gefunden: $regPath" -ForegroundColor Gray
    }
}

# Zusätzliche Bereinigung: Startmenü-Verknüpfungen
Write-Host "`n[Zusätzlich] Entferne Startmenü-Verknüpfungen..." -ForegroundColor Yellow

$startMenuPaths = @(
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\PuTTY",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\PuTTY"
)

foreach ($path in $startMenuPaths) {
    if (Test-Path $path) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            Write-Host "  ✓ Gelöscht: $path" -ForegroundColor Green
        }
        catch {
            Write-Host "  ✗ Fehler beim Löschen von $path : $_" -ForegroundColor Red
        }
    }
}

# Abschluss
Write-Host "`n=== Deinstallation abgeschlossen ===" -ForegroundColor Cyan
Write-Host "PuTTY wurde vom System entfernt." -ForegroundColor Green
Write-Host ""
