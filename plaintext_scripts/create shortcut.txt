# Source - https://stackoverflow.com/a
# Posted by CB., modified by community. See post 'Timeline' for change history
# Retrieved 2026-01-23, License - CC BY-SA 4.0

$WshShell = New-Object -COMObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($env:destination)
$Shortcut.TargetPath = $env:sourcefile
$Shortcut.Save()