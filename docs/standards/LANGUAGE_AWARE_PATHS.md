# Language-Aware Path Handling - Windows Automation Framework

**Document Type:** Technical Guide  
**Audience:** Script Developers, Contributors  
**Version:** 1.0  
**Last Updated:** February 9, 2026

---

## Purpose

This guide establishes standards for handling file system paths that vary between different Windows language versions, particularly German and English. Following these standards ensures scripts work reliably across international deployments.

---
## Overview

Windows folder names vary by operating system language. Scripts must handle both German (Deutsch) and English Windows installations transparently. This is critical for:

- User profile folders
- System folders
- Common program locations
- Application data directories

---

## Critical Requirement

### MANDATORY: Multi-Language Path Support

**ALL scripts that reference language-specific folder paths MUST check for both German and English variants**

Never hardcode a single language path. Always implement fallback logic:

```powershell
# REQUIRED - Multi-language path check
$DesktopPath = if (Test-Path "$env:USERPROFILE\Desktop") {
    "$env:USERPROFILE\Desktop"
} elseif (Test-Path "$env:USERPROFILE\Schreibtisch") {
    "$env:USERPROFILE\Schreibtisch"
} else {
    Write-Log "Desktop folder not found in expected locations" -Level ERROR
    $null
}

# FORBIDDEN - Single language hardcoded
$DesktopPath = "$env:USERPROFILE\Desktop"  # Will fail on German Windows
```

**Why:**
- Scripts must work on both German and English Windows
- Folder names change based on OS language
- Hardcoded paths cause failures in mixed environments
- Users may have either language version

---

## Common Language-Specific Folders

### User Profile Folders

**Desktop:**
- English: `Desktop`
- German: `Schreibtisch`

**Documents:**
- English: `Documents`
- German: `Dokumente`

**Downloads:**
- English: `Downloads`
- German: `Downloads` (same)

**Pictures:**
- English: `Pictures`
- German: `Bilder`

**Music:**
- English: `Music`
- German: `Musik`

**Videos:**
- English: `Videos`
- German: `Videos` (same)

**Public:**
- English: `Public`
- German: `Öffentlich`

### System Folders

**Program Files:**
- English: `C:\Program Files`
- German: `C:\Programme` (older) or `C:\Program Files` (newer)

**Program Files (x86):**
- English: `C:\Program Files (x86)`
- German: `C:\Programme (x86)` (older) or `C:\Program Files (x86)` (newer)

**Users:**
- English: `C:\Users`
- German: `C:\Benutzer` (older) or `C:\Users` (newer)

**Windows:**
- Both: `C:\Windows` (same)

---

## Standard Path Resolution Function

### REQUIRED: Use Get-LocalizedPath Function

**Include this function in scripts that need language-aware paths:**

```powershell
function Get-LocalizedPath {
    <#
    .SYNOPSIS
        Resolves a user folder path supporting both German and English Windows
    
    .DESCRIPTION
        Checks for the existence of common user folders in both German and English
        naming conventions. Returns the first valid path found or $null if neither exists.
        
        This ensures scripts work on both language versions of Windows without modification.
    
    .PARAMETER FolderType
        The type of folder to locate. Valid options:
        - Desktop
        - Documents
        - Downloads
        - Pictures
        - Music
        - Videos
        - Public
    
    .PARAMETER UserProfile
        Optional user profile path. Defaults to current user ($env:USERPROFILE)
    
    .EXAMPLE
        $DesktopPath = Get-LocalizedPath -FolderType 'Desktop'
        # Returns: C:\Users\username\Desktop (English)
        # OR:      C:\Users\username\Schreibtisch (German)
    
    .EXAMPLE
        $DocsPath = Get-LocalizedPath -FolderType 'Documents' -UserProfile 'C:\Users\admin'
        # Checks specific user profile for Documents folder
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Desktop', 'Documents', 'Downloads', 'Pictures', 'Music', 'Videos', 'Public')]
        [string]$FolderType,
        
        [Parameter(Mandatory=$false)]
        [string]$UserProfile = $env:USERPROFILE
    )
    
    # Define language variants for each folder type
    $FolderMappings = @{
        'Desktop'   = @('Desktop', 'Schreibtisch')
        'Documents' = @('Documents', 'Dokumente')
        'Downloads' = @('Downloads')
        'Pictures'  = @('Pictures', 'Bilder')
        'Music'     = @('Music', 'Musik')
        'Videos'    = @('Videos')
        'Public'    = @('Public', 'Öffentlich')
    }
    
    # Get possible folder names for this type
    $PossibleNames = $FolderMappings[$FolderType]
    
    # Check each variant
    foreach ($FolderName in $PossibleNames) {
        $TestPath = Join-Path $UserProfile $FolderName
        
        if (Test-Path $TestPath) {
            Write-Log "Found $FolderType folder: $TestPath" -Level DEBUG
            return $TestPath
        }
    }
    
    # No valid path found
    Write-Log "$FolderType folder not found in user profile: $UserProfile" -Level WARN
    Write-Log "Checked variants: $($PossibleNames -join ', ')" -Level DEBUG
    return $null
}
```

---

## Usage Examples

### Example 1: Desktop Path

```powershell
# Get desktop path (works on both German and English)
$DesktopPath = Get-LocalizedPath -FolderType 'Desktop'

if ($DesktopPath) {
    # Use the path
    $ShortcutPath = Join-Path $DesktopPath "Application.lnk"
    Write-Log "Desktop shortcut path: $ShortcutPath" -Level INFO
} else {
    Write-Log "Desktop folder not accessible" -Level ERROR
}
```

### Example 2: Documents Folder

```powershell
# Get documents folder
$DocumentsPath = Get-LocalizedPath -FolderType 'Documents'

if ($DocumentsPath) {
    # Check for specific file
    $ConfigFile = Join-Path $DocumentsPath "config.xml"
    
    if (Test-Path $ConfigFile) {
        Write-Log "Config file found: $ConfigFile" -Level INFO
        $Config = Import-Clixml $ConfigFile
    }
}
```

### Example 3: Multiple Folders

```powershell
# Get multiple user folders
$Folders = @{
    Desktop   = Get-LocalizedPath -FolderType 'Desktop'
    Documents = Get-LocalizedPath -FolderType 'Documents'
    Downloads = Get-LocalizedPath -FolderType 'Downloads'
    Pictures  = Get-LocalizedPath -FolderType 'Pictures'
}

# Report findings
foreach ($FolderType in $Folders.Keys) {
    $Path = $Folders[$FolderType]
    
    if ($Path) {
        $Size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1GB
        Write-Log "$FolderType : $Path ($([math]::Round($Size, 2)) GB)" -Level INFO
    } else {
        Write-Log "$FolderType : Not found" -Level WARN
    }
}
```

### Example 4: Specific User Profile

```powershell
# Check folders for a specific user
$TargetUser = "C:\Users\administrator"

$AdminDesktop = Get-LocalizedPath -FolderType 'Desktop' -UserProfile $TargetUser

if ($AdminDesktop) {
    Write-Log "Admin desktop: $AdminDesktop" -Level INFO
    
    # List desktop items
    $DesktopItems = Get-ChildItem $AdminDesktop -ErrorAction SilentlyContinue
    Write-Log "Admin has $($DesktopItems.Count) desktop items" -Level INFO
}
```

---

## Alternative: Environment Variables

### Preferred Method for Shell Folders

Where possible, use Windows environment variables which are language-independent:

```powershell
# These work on ALL languages
$UserProfile = $env:USERPROFILE          # C:\Users\username
$AppData = $env:APPDATA                  # C:\Users\username\AppData\Roaming
$LocalAppData = $env:LOCALAPPDATA        # C:\Users\username\AppData\Local
$Temp = $env:TEMP                        # C:\Users\username\AppData\Local\Temp
$ProgramFiles = $env:ProgramFiles        # C:\Program Files
$ProgramFilesX86 = ${env:ProgramFiles(x86)}  # C:\Program Files (x86)
$SystemRoot = $env:SystemRoot            # C:\Windows
$Public = $env:PUBLIC                    # C:\Users\Public
```

### Best Practice Hierarchy

1. **First choice:** Use environment variables (language-independent)
2. **Second choice:** Use Get-LocalizedPath function (handles variants)
3. **Last choice:** Hardcode path with fallback check

```powershell
# BEST - Environment variable (if available)
$AppDataPath = $env:APPDATA

# GOOD - Get-LocalizedPath function
$DesktopPath = Get-LocalizedPath -FolderType 'Desktop'

# ACCEPTABLE - Hardcoded with fallback
$DesktopPath = if (Test-Path "$env:USERPROFILE\Desktop") {
    "$env:USERPROFILE\Desktop"
} elseif (Test-Path "$env:USERPROFILE\Schreibtisch") {
    "$env:USERPROFILE\Schreibtisch"
} else {
    $null
}

# BAD - Single hardcoded path
$DesktopPath = "$env:USERPROFILE\Desktop"  # FORBIDDEN
```

---

## Registry-Based Path Resolution

### Using Shell Folders Registry Keys

Windows stores shell folder paths in the registry (language-independent):

```powershell
function Get-ShellFolderPath {
    <#
    .SYNOPSIS
        Gets shell folder path from registry (language-independent)
    
    .PARAMETER FolderName
        Shell folder name (e.g., 'Desktop', 'Personal', 'My Pictures')
    #>
    param(
        [string]$FolderName
    )
    
    try {
        $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        $Value = Get-ItemProperty -Path $RegPath -Name $FolderName -ErrorAction Stop
        
        # Expand environment variables in path
        $Path = [Environment]::ExpandEnvironmentVariables($Value.$FolderName)
        
        if (Test-Path $Path) {
            return $Path
        }
        
    } catch {
        Write-Log "Failed to get shell folder from registry: $FolderName" -Level DEBUG
    }
    
    return $null
}

# Usage examples
$Desktop = Get-ShellFolderPath -FolderName 'Desktop'
$Documents = Get-ShellFolderPath -FolderName 'Personal'
$Pictures = Get-ShellFolderPath -FolderName 'My Pictures'
$Downloads = Get-ShellFolderPath -FolderName '{374DE290-123F-4565-9164-39C4925E467B}'
```

### Common Shell Folder Registry Names

```powershell
# User Shell Folders registry names
$ShellFolders = @{
    'Desktop'       = 'Desktop'
    'Documents'     = 'Personal'
    'Downloads'     = '{374DE290-123F-4565-9164-39C4925E467B}'
    'Pictures'      = 'My Pictures'
    'Music'         = 'My Music'
    'Videos'        = 'My Video'
    'AppData'       = 'AppData'
    'LocalAppData'  = 'Local AppData'
    'ProgramData'   = 'Common AppData'
}
```

---

## System Folder Path Resolution

### Program Files Folders

```powershell
function Get-ProgramFilesPath {
    <#
    .SYNOPSIS
        Gets Program Files path (handles German "Programme" variant)
    
    .PARAMETER Architecture
        'x64' for 64-bit Program Files, 'x86' for 32-bit
    #>
    param(
        [ValidateSet('x64', 'x86')]
        [string]$Architecture = 'x64'
    )
    
    if ($Architecture -eq 'x64') {
        # Use environment variable (most reliable)
        if ($env:ProgramFiles) {
            return $env:ProgramFiles
        }
        
        # Fallback checks
        $Paths = @(
            'C:\Program Files',
            'C:\Programme'
        )
    } else {
        # x86 Program Files
        if (${env:ProgramFiles(x86)}) {
            return ${env:ProgramFiles(x86)}
        }
        
        # Fallback checks
        $Paths = @(
            'C:\Program Files (x86)',
            'C:\Programme (x86)'
        )
    }
    
    # Check each variant
    foreach ($Path in $Paths) {
        if (Test-Path $Path) {
            Write-Log "Found Program Files ($Architecture): $Path" -Level DEBUG
            return $Path
        }
    }
    
    Write-Log "Program Files ($Architecture) not found" -Level WARN
    return $null
}

# Usage
$ProgramFiles64 = Get-ProgramFilesPath -Architecture 'x64'
$ProgramFiles32 = Get-ProgramFilesPath -Architecture 'x86'
```

### Users Folder

```powershell
function Get-UsersFolder {
    <#
    .SYNOPSIS
        Gets the Users folder path (handles German "Benutzer" variant)
    #>
    
    # Check environment variable first
    $UserProfile = $env:USERPROFILE
    if ($UserProfile) {
        $UsersFolder = Split-Path $UserProfile -Parent
        if (Test-Path $UsersFolder) {
            return $UsersFolder
        }
    }
    
    # Fallback to common paths
    $Paths = @(
        'C:\Users',
        'C:\Benutzer'
    )
    
    foreach ($Path in $Paths) {
        if (Test-Path $Path) {
            Write-Log "Found Users folder: $Path" -Level DEBUG
            return $Path
        }
    }
    
    Write-Log "Users folder not found" -Level ERROR
    return $null
}
```

---

## Complete Example Script

### Language-Aware File Operations

```powershell
<#
.SYNOPSIS
    Example script demonstrating language-aware path handling
#>

# Include Get-LocalizedPath function (shown earlier)
function Get-LocalizedPath { ... }

# Get user folders (works on German and English Windows)
$DesktopPath = Get-LocalizedPath -FolderType 'Desktop'
$DocumentsPath = Get-LocalizedPath -FolderType 'Documents'
$DownloadsPath = Get-LocalizedPath -FolderType 'Downloads'

if (-not $DesktopPath) {
    Write-Log "Cannot locate Desktop folder" -Level ERROR
    exit 1
}

# Create a report file on desktop
$ReportFile = Join-Path $DesktopPath "SystemReport_$(Get-Date -Format 'yyyyMMdd').txt"

try {
    # Gather system information
    $SystemInfo = @{
        ComputerName = $env:COMPUTERNAME
        UserProfile = $env:USERPROFILE
        OSLanguage = (Get-Culture).DisplayName
        DesktopPath = $DesktopPath
        DocumentsPath = $DocumentsPath
        DownloadsPath = $DownloadsPath
    }
    
    # Write report
    $Report = @"
System Report
=============
Generated: $(Get-Date)

Computer: $($SystemInfo.ComputerName)
User Profile: $($SystemInfo.UserProfile)
OS Language: $($SystemInfo.OSLanguage)

Located Folders:
  Desktop: $($SystemInfo.DesktopPath)
  Documents: $($SystemInfo.DocumentsPath)
  Downloads: $($SystemInfo.DownloadsPath)
"@
    
    $Report | Out-File -FilePath $ReportFile -Encoding UTF8
    Write-Log "Report saved: $ReportFile" -Level INFO
    
} catch {
    Write-Log "Failed to create report: $_" -Level ERROR
    exit 1
}
```

---

## Testing Language Variants

### Test Script for Path Resolution

```powershell
function Test-LanguageAwarePaths {
    <#
    .SYNOPSIS
        Tests path resolution for both German and English folder names
    #>
    
    Write-Host "\n=== Language-Aware Path Testing ===\n" -ForegroundColor Cyan
    
    # Test user profile folders
    $FoldersToTest = @('Desktop', 'Documents', 'Downloads', 'Pictures', 'Music', 'Videos')
    
    foreach ($FolderType in $FoldersToTest) {
        Write-Host "Testing: $FolderType" -ForegroundColor Yellow
        
        $Path = Get-LocalizedPath -FolderType $FolderType
        
        if ($Path) {
            $FolderName = Split-Path $Path -Leaf
            $Exists = Test-Path $Path
            $Color = if ($Exists) { 'Green' } else { 'Red' }
            
            Write-Host "  Path: $Path" -ForegroundColor $Color
            Write-Host "  Folder Name: $FolderName" -ForegroundColor $Color
            Write-Host "  Exists: $Exists" -ForegroundColor $Color
        } else {
            Write-Host "  NOT FOUND" -ForegroundColor Red
        }
        
        Write-Host ""
    }
    
    # Test environment variables
    Write-Host "\n=== Environment Variables ==="  -ForegroundColor Cyan
    Write-Host "USERPROFILE: $env:USERPROFILE"
    Write-Host "APPDATA: $env:APPDATA"
    Write-Host "LOCALAPPDATA: $env:LOCALAPPDATA"
    Write-Host "PUBLIC: $env:PUBLIC"
    Write-Host "ProgramFiles: $env:ProgramFiles"
    Write-Host "ProgramFiles(x86): ${env:ProgramFiles(x86)}"
    
    # Detect OS language
    $Culture = Get-Culture
    Write-Host "\n=== System Language ===" -ForegroundColor Cyan
    Write-Host "Culture: $($Culture.Name)"
    Write-Host "Display Name: $($Culture.DisplayName)"
    Write-Host "Is German: $($Culture.Name -like 'de-*')" -ForegroundColor $(if ($Culture.Name -like 'de-*') { 'Green' } else { 'Yellow' })
}

# Run test
Test-LanguageAwarePaths
```

---

## Best Practices Summary

### DO:

1. **Use environment variables** when available (language-independent)
2. **Implement Get-LocalizedPath function** in scripts needing user folders
3. **Check multiple path variants** for German and English
4. **Log which path variant** was found (for debugging)
5. **Handle missing paths gracefully** (don't assume paths exist)
6. **Use registry shell folders** as fallback method
7. **Test on both German and English** Windows installations
8. **Document language support** in script headers

### DON'T:

1. **Never hardcode single-language paths** (will fail on other language)
2. **Never assume folder names** without checking
3. **Never fail silently** when paths don't exist
4. **Never use aliases** for path components
5. **Never skip error handling** for path operations
6. **Never assume C:\Users** always exists (might be C:\Benutzer)
7. **Never use literal German characters** without UTF-8 encoding
8. **Never skip testing** on both languages

---

## Common Mistakes to Avoid

### Mistake 1: Hardcoded English Path

```powershell
# BAD - Only works on English Windows
$DesktopPath = "$env:USERPROFILE\Desktop"
$File = "$DesktopPath\report.txt"

# GOOD - Works on both languages
$DesktopPath = Get-LocalizedPath -FolderType 'Desktop'
if ($DesktopPath) {
    $File = Join-Path $DesktopPath "report.txt"
}
```

### Mistake 2: No Fallback Logic

```powershell
# BAD - No fallback
if (Test-Path "$env:USERPROFILE\Desktop") {
    $Desktop = "$env:USERPROFILE\Desktop"
}
# $Desktop is undefined on German Windows

# GOOD - With fallback
$Desktop = Get-LocalizedPath -FolderType 'Desktop'
if (-not $Desktop) {
    Write-Log "Desktop folder not accessible" -Level ERROR
    exit 1
}
```

### Mistake 3: Silent Failures

```powershell
# BAD - Silent failure
$DocsPath = "$env:USERPROFILE\Documents"
Copy-Item $SourceFile $DocsPath -ErrorAction SilentlyContinue
# Fails silently on German Windows

# GOOD - Explicit checking and logging
$DocsPath = Get-LocalizedPath -FolderType 'Documents'
if ($DocsPath) {
    try {
        Copy-Item $SourceFile $DocsPath -ErrorAction Stop
        Write-Log "File copied to: $DocsPath" -Level INFO
    } catch {
        Write-Log "Failed to copy file: $_" -Level ERROR
    }
} else {
    Write-Log "Documents folder not found" -Level ERROR
}
```

### Mistake 4: Not Using Join-Path

```powershell
# BAD - Manual path concatenation
$FilePath = $DesktopPath + "\" + $FileName

# GOOD - Join-Path handles separators correctly
$FilePath = Join-Path $DesktopPath $FileName
```

---

## Integration with Coding Standards

When implementing language-aware paths:

1. **Include Get-LocalizedPath in Functions section** (lines 151-400)
2. **Document language support in comment-based help**
3. **Log path resolution** at DEBUG level
4. **Handle missing paths gracefully** (don't exit unless critical)
5. **Test on both German and English** Windows before committing
6. **Use NinjaRMM fields** to track language detection

```powershell
# Example: Track detected OS language
$OSLanguage = (Get-Culture).Name
Set-NinjaField -FieldName "sysOSLanguage" -Value $OSLanguage

# Track which folder variants were found
$DesktopPath = Get-LocalizedPath -FolderType 'Desktop'
if ($DesktopPath) {
    $DesktopFolderName = Split-Path $DesktopPath -Leaf
    Set-NinjaField -FieldName "sysDesktopFolderName" -Value $DesktopFolderName
}
```

---

## Quick Reference

### Common Folder Name Translations

| English | German | Notes |
|---------|--------|-------|
| Desktop | Schreibtisch | Always different |
| Documents | Dokumente | Always different |
| Downloads | Downloads | Usually same |
| Pictures | Bilder | Always different |
| Music | Musik | Always different |
| Videos | Videos | Usually same |
| Public | Öffentlich | Always different |
| Program Files | Programme | Older versions only |
| Users | Benutzer | Older versions only |

### Path Resolution Priority

1. Environment variables (`$env:APPDATA`, `$env:USERPROFILE`, etc.)
2. Registry shell folders (`HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders`)
3. Get-LocalizedPath function (checks multiple variants)
4. Hardcoded check with fallback (last resort)

---

**Document Version:** 1.0  
**Last Updated:** February 9, 2026  
**Related Documents:** [CODING_STANDARDS.md](CODING_STANDARDS.md)  
**Next Review:** Quarterly or when language support expanded
