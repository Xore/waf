<#
.SYNOPSIS
    GUI configuration editor for Window Layout Manager

.DESCRIPTION
    Provides a graphical interface to create, edit, and manage window layout profiles.
    Allows users to visually configure window placement rules without editing code.
    
    Features:
    - Create/edit/delete layout profiles
    - Add/remove window placement rules
    - Test configurations with dry run
    - Apply configurations immediately
    - Save/load from file
    - Visual monitor preview
    - Application process name browser
    - Title pattern tester

.PARAMETER ConfigPath
    Optional path to load existing configuration file

.EXAMPLE
    PS> .\Window Layout Manager GUI.ps1
    Launches the GUI editor with default configuration
    
.EXAMPLE
    PS> .\Window Layout Manager GUI.ps1 -ConfigPath "C:\Configs\MyLayout.xml"
    Launches GUI and loads specified configuration

.NOTES
    Script Name:    Window Layout Manager GUI.ps1
    Author:         Windows Automation Framework
    Version:        1.0.1
    Creation Date:  2026-02-14
    Last Modified:  2026-02-14
    
    Execution Context: User (requires UI)
    Execution Frequency: On-demand
    Typical Duration: User session
    Timeout Setting: None (user interactive)
    
    User Interaction: Full GUI interaction required
    Restart Behavior: Never restarts
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Windows 10/11 or Windows Server 2016+ with Desktop Experience
        - .NET Framework (included with Windows)
        - Window Layout Manager 1.ps1 (for applying configurations)
    
    Exit Codes:
        0 - Success (user closed application)
        1 - General error
        2 - Missing dependencies
    
.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = ""
)

#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "1.0.1"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LayoutManagerScript = Join-Path $ScriptDir "Window Layout Manager 1.ps1"

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================

$script:CurrentProfile = $null
$script:CurrentRules = @{}
$script:SelectedRuleName = $null
$script:UnsavedChanges = $false

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Get-RunningProcesses {
    <#
    .SYNOPSIS
        Gets list of running GUI applications
    #>
    Get-Process | 
        Where-Object { $_.MainWindowTitle -ne '' } |
        Select-Object -ExpandProperty ProcessName -Unique |
        Sort-Object
}

function Test-TitlePattern {
    <#
    .SYNOPSIS
        Tests if title pattern matches any running windows
    #>
    param(
        [string]$ProcessName,
        [string]$Pattern
    )
    
    if ([string]::IsNullOrWhiteSpace($Pattern)) {
        return @()
    }
    
    $RegexPattern = $Pattern
    if ($Pattern -match '[*?]') {
        $Escaped = [regex]::Escape($Pattern)
        $RegexPattern = $Escaped -replace '\\\*', '.*' -replace '\\\?', '.'
    }
    
    Get-Process -Name $ProcessName -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -match $RegexPattern } |
        Select-Object -ExpandProperty MainWindowTitle
}

function Set-UnsavedChanges {
    param([bool]$Value)
    
    $script:UnsavedChanges = $Value
    $titleSuffix = if ($Value) { " *" } else { "" }
    $form.Text = "Window Layout Manager - Configuration Editor v$ScriptVersion$titleSuffix"
}

function Update-RulesList {
    <#
    .SYNOPSIS
        Updates the rules listbox with current rules
    #>
    $listRules.Items.Clear()
    
    foreach ($ruleName in ($script:CurrentRules.Keys | Sort-Object)) {
        $rule = $script:CurrentRules[$ruleName]
        $display = "$ruleName - $($rule.ApplicationName) [$($rule.Position)] Mon:$($rule.MonitorNumber)"
        $listRules.Items.Add($display) | Out-Null
    }
    
    $lblRuleCount.Text = "Rules: $($script:CurrentRules.Count)"
}

function Clear-RuleEditor {
    <#
    .SYNOPSIS
        Clears all rule editor fields
    #>
    $txtRuleName.Text = ""
    $txtRuleName.ReadOnly = $false
    $txtDisplayName.Text = ""
    $cmbProcessName.Text = ""
    $txtTitlePattern.Text = ""
    $numMonitor.Value = 1
    $cmbPosition.SelectedIndex = 0
    $txtMatchingWindows.Text = ""
    $script:SelectedRuleName = $null
}

function Load-RuleToEditor {
    <#
    .SYNOPSIS
        Loads selected rule into editor fields
    #>
    param([string]$RuleName)
    
    if (-not $script:CurrentRules.ContainsKey($RuleName)) {
        return
    }
    
    $rule = $script:CurrentRules[$RuleName]
    $script:SelectedRuleName = $RuleName
    
    $txtRuleName.Text = $RuleName
    $txtRuleName.ReadOnly = $true
    $txtDisplayName.Text = $rule.DisplayName
    $cmbProcessName.Text = $rule.ApplicationName
    $txtTitlePattern.Text = if ($rule.TitlePattern) { $rule.TitlePattern } else { "" }
    $numMonitor.Value = $rule.MonitorNumber
    $cmbPosition.SelectedItem = $rule.Position
    
    Update-MatchingWindows
}

function Update-MatchingWindows {
    <#
    .SYNOPSIS
        Shows windows matching current process and title pattern
    #>
    $processName = $cmbProcessName.Text
    $pattern = $txtTitlePattern.Text
    
    if ([string]::IsNullOrWhiteSpace($processName)) {
        $txtMatchingWindows.Text = "Enter process name to see matches"
        return
    }
    
    try {
        if ([string]::IsNullOrWhiteSpace($pattern)) {
            $windows = Get-Process -Name $processName -ErrorAction Stop |
                Where-Object { $_.MainWindowTitle -ne '' } |
                Select-Object -ExpandProperty MainWindowTitle
        } else {
            $windows = Test-TitlePattern -ProcessName $processName -Pattern $pattern
        }
        
        if ($windows) {
            $txtMatchingWindows.Text = ($windows | ForEach-Object { "- $_" }) -join "`r`n"
        } else {
            $txtMatchingWindows.Text = "No matching windows found"
        }
    } catch {
        $txtMatchingWindows.Text = "Process not running"
    }
}

function Save-CurrentRule {
    <#
    .SYNOPSIS
        Saves current editor state as a rule
    #>
    $ruleName = $txtRuleName.Text.Trim()
    $displayName = $txtDisplayName.Text.Trim()
    $processName = $cmbProcessName.Text.Trim()
    $titlePattern = $txtTitlePattern.Text.Trim()
    $monitor = [int]$numMonitor.Value
    $position = $cmbPosition.SelectedItem
    
    if ([string]::IsNullOrWhiteSpace($ruleName)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Rule name is required",
            "Validation Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return $false
    }
    
    if ([string]::IsNullOrWhiteSpace($processName)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Process name is required",
            "Validation Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return $false
    }
    
    if ([string]::IsNullOrWhiteSpace($displayName)) {
        $displayName = $ruleName
    }
    
    $rule = @{
        ApplicationName = $processName
        DisplayName     = $displayName
        TitlePattern    = if ([string]::IsNullOrWhiteSpace($titlePattern)) { $null } else { $titlePattern }
        MonitorNumber   = $monitor
        Position        = $position.ToString().ToLower()
    }
    
    $script:CurrentRules[$ruleName] = $rule
    Set-UnsavedChanges $true
    Update-RulesList
    
    return $true
}

function Remove-CurrentRule {
    <#
    .SYNOPSIS
        Removes selected rule
    #>
    if ($null -eq $script:SelectedRuleName) {
        [System.Windows.Forms.MessageBox]::Show(
            "No rule selected",
            "Delete Rule",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return
    }
    
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Delete rule '$($script:SelectedRuleName)'?",
        "Confirm Delete",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $script:CurrentRules.Remove($script:SelectedRuleName)
        Set-UnsavedChanges $true
        Update-RulesList
        Clear-RuleEditor
    }
}

function Save-Configuration {
    <#
    .SYNOPSIS
        Saves configuration to file
    #>
    param([string]$Path)
    
    if ($script:CurrentRules.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "No rules to save",
            "Save Configuration",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return $false
    }
    
    try {
        $script:CurrentRules | Export-Clixml -Path $Path -Force
        Set-UnsavedChanges $false
        [System.Windows.Forms.MessageBox]::Show(
            "Configuration saved to:`n$Path",
            "Save Successful",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to save configuration:`n$_",
            "Save Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }
}

function Load-Configuration {
    <#
    .SYNOPSIS
        Loads configuration from file
    #>
    param([string]$Path)
    
    try {
        $config = Import-Clixml -Path $Path
        $script:CurrentRules = $config
        Set-UnsavedChanges $false
        Update-RulesList
        Clear-RuleEditor
        [System.Windows.Forms.MessageBox]::Show(
            "Configuration loaded from:`n$Path`n`nRules: $($config.Count)",
            "Load Successful",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to load configuration:`n$_",
            "Load Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }
}

function Apply-Configuration {
    <#
    .SYNOPSIS
        Applies current configuration using Window Layout Manager
    #>
    param([bool]$DryRun = $false)
    
    if ($script:CurrentRules.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "No rules to apply",
            "Apply Configuration",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }
    
    if (-not (Test-Path $LayoutManagerScript)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Window Layout Manager script not found:`n$LayoutManagerScript",
            "Apply Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }
    
    $tempConfig = [System.IO.Path]::GetTempFileName() + ".xml"
    try {
        $script:CurrentRules | Export-Clixml -Path $tempConfig -Force
        
        $args = @("-File", $LayoutManagerScript, "-ConfigPath", $tempConfig)
        if ($DryRun) {
            $args += "-DryRun"
        }
        
        $output = & powershell.exe $args 2>&1 | Out-String
        
        $title = if ($DryRun) { "Dry Run Results" } else { "Apply Results" }
        $form2 = New-Object System.Windows.Forms.Form
        $form2.Text = $title
        $form2.Size = New-Object System.Drawing.Size(700, 500)
        $form2.StartPosition = "CenterParent"
        $form2.FormBorderStyle = "Sizable"
        
        $txtOutput = New-Object System.Windows.Forms.TextBox
        $txtOutput.Multiline = $true
        $txtOutput.ScrollBars = "Vertical"
        $txtOutput.Dock = "Fill"
        $txtOutput.Font = New-Object System.Drawing.Font("Consolas", 9)
        $txtOutput.Text = $output
        $txtOutput.ReadOnly = $true
        
        $form2.Controls.Add($txtOutput)
        $form2.ShowDialog() | Out-Null
        
    } finally {
        if (Test-Path $tempConfig) {
            Remove-Item $tempConfig -Force
        }
    }
}

# ============================================================================
# GUI CONSTRUCTION
# ============================================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "Window Layout Manager - Configuration Editor v$ScriptVersion"
$form.Size = New-Object System.Drawing.Size(1000, 700)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "Sizable"
$form.MinimumSize = New-Object System.Drawing.Size(900, 600)

# ============================================================================
# MENU BAR
# ============================================================================

$menuStrip = New-Object System.Windows.Forms.MenuStrip

$menuFile = New-Object System.Windows.Forms.ToolStripMenuItem
$menuFile.Text = "File"

$menuNew = New-Object System.Windows.Forms.ToolStripMenuItem
$menuNew.Text = "New Configuration"
$menuNew.ShortcutKeys = "Control, N"
$menuNew.Add_Click({
    if ($script:UnsavedChanges) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Discard unsaved changes?",
            "New Configuration",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
            return
        }
    }
    $script:CurrentRules = @{}
    Set-UnsavedChanges $false
    Update-RulesList
    Clear-RuleEditor
})

$menuOpen = New-Object System.Windows.Forms.ToolStripMenuItem
$menuOpen.Text = "Open Configuration..."
$menuOpen.ShortcutKeys = "Control, O"
$menuOpen.Add_Click({
    $openDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openDialog.Filter = "XML Configuration Files (*.xml)|*.xml|All Files (*.*)|*.*"
    $openDialog.Title = "Open Configuration"
    
    if ($openDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Load-Configuration -Path $openDialog.FileName
    }
})

$menuSave = New-Object System.Windows.Forms.ToolStripMenuItem
$menuSave.Text = "Save Configuration..."
$menuSave.ShortcutKeys = "Control, S"
$menuSave.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "XML Configuration Files (*.xml)|*.xml|All Files (*.*)|*.*"
    $saveDialog.Title = "Save Configuration"
    $saveDialog.DefaultExt = "xml"
    
    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Save-Configuration -Path $saveDialog.FileName
    }
})

$menuExit = New-Object System.Windows.Forms.ToolStripMenuItem
$menuExit.Text = "Exit"
$menuExit.Add_Click({
    $form.Close()
})

$menuFile.DropDownItems.AddRange(@($menuNew, $menuOpen, $menuSave, 
    (New-Object System.Windows.Forms.ToolStripSeparator), $menuExit))

$menuApply = New-Object System.Windows.Forms.ToolStripMenuItem
$menuApply.Text = "Apply"

$menuDryRun = New-Object System.Windows.Forms.ToolStripMenuItem
$menuDryRun.Text = "Dry Run (Test)"
$menuDryRun.ShortcutKeys = "F5"
$menuDryRun.Add_Click({
    Apply-Configuration -DryRun $true
})

$menuApplyNow = New-Object System.Windows.Forms.ToolStripMenuItem
$menuApplyNow.Text = "Apply Now"
$menuApplyNow.ShortcutKeys = "Control, F5"
$menuApplyNow.Add_Click({
    Apply-Configuration -DryRun $false
})

$menuApply.DropDownItems.AddRange(@($menuDryRun, $menuApplyNow))

$menuHelp = New-Object System.Windows.Forms.ToolStripMenuItem
$menuHelp.Text = "Help"

$menuAbout = New-Object System.Windows.Forms.ToolStripMenuItem
$menuAbout.Text = "About"
$menuAbout.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        "Window Layout Manager - Configuration Editor`nVersion $ScriptVersion`n`nCreate and manage window layout configurations visually.`n`nFeatures:`n- Create/edit/delete layout rules`n- Test with dry run mode`n- Apply configurations immediately`n- Save/load configuration files`n`nPart of Windows Automation Framework",
        "About",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
})

$menuHelp.DropDownItems.Add($menuAbout)

$menuStrip.Items.AddRange(@($menuFile, $menuApply, $menuHelp))
$form.Controls.Add($menuStrip)
$form.MainMenuStrip = $menuStrip

# ============================================================================
# MAIN LAYOUT PANELS
# ============================================================================

$splitContainer = New-Object System.Windows.Forms.SplitContainer
$splitContainer.Dock = "Fill"
$splitContainer.Orientation = "Vertical"
$splitContainer.SplitterDistance = 300

# Calculate size explicitly to avoid array issues
$containerWidth = $form.ClientSize.Width
$containerHeight = ([int]$form.ClientSize.Height) - ([int]$menuStrip.Height)

$splitContainer.Location = New-Object System.Drawing.Point(0, $menuStrip.Height)
$splitContainer.Size = New-Object System.Drawing.Size($containerWidth, $containerHeight)

# ============================================================================
# LEFT PANEL - RULES LIST
# ============================================================================

$panelLeft = $splitContainer.Panel1

$lblRules = New-Object System.Windows.Forms.Label
$lblRules.Text = "Layout Rules"
$lblRules.Location = New-Object System.Drawing.Point(10, 10)
$lblRules.Size = New-Object System.Drawing.Size(280, 20)
$lblRules.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelLeft.Controls.Add($lblRules)

$lblRuleCount = New-Object System.Windows.Forms.Label
$lblRuleCount.Text = "Rules: 0"
$lblRuleCount.Location = New-Object System.Drawing.Point(10, 35)
$lblRuleCount.Size = New-Object System.Drawing.Size(280, 20)
$panelLeft.Controls.Add($lblRuleCount)

$listRules = New-Object System.Windows.Forms.ListBox
$listRules.Location = New-Object System.Drawing.Point(10, 60)
$listRules.Size = New-Object System.Drawing.Size(280, 400)
$listRules.Anchor = "Top,Bottom,Left,Right"
$listRules.Font = New-Object System.Drawing.Font("Consolas", 9)
$listRules.Add_SelectedIndexChanged({
    if ($listRules.SelectedIndex -ge 0) {
        $selected = $listRules.SelectedItem.ToString()
        $ruleName = $selected.Split('-')[0].Trim()
        Load-RuleToEditor -RuleName $ruleName
    }
})
$panelLeft.Controls.Add($listRules)

$btnNewRule = New-Object System.Windows.Forms.Button
$btnNewRule.Text = "New Rule"
$btnNewRule.Location = New-Object System.Drawing.Point(10, 470)
$btnNewRule.Size = New-Object System.Drawing.Size(135, 30)
$btnNewRule.Anchor = "Bottom,Left"
$btnNewRule.Add_Click({
    Clear-RuleEditor
})
$panelLeft.Controls.Add($btnNewRule)

$btnDeleteRule = New-Object System.Windows.Forms.Button
$btnDeleteRule.Text = "Delete Rule"
$btnDeleteRule.Location = New-Object System.Drawing.Point(155, 470)
$btnDeleteRule.Size = New-Object System.Drawing.Size(135, 30)
$btnDeleteRule.Anchor = "Bottom,Left"
$btnDeleteRule.Add_Click({
    Remove-CurrentRule
})
$panelLeft.Controls.Add($btnDeleteRule)

# ============================================================================
# RIGHT PANEL - RULE EDITOR
# ============================================================================

$panelRight = $splitContainer.Panel2

$lblEditor = New-Object System.Windows.Forms.Label
$lblEditor.Text = "Rule Editor"
$lblEditor.Location = New-Object System.Drawing.Point(10, 10)
$lblEditor.Size = New-Object System.Drawing.Size(650, 20)
$lblEditor.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelRight.Controls.Add($lblEditor)

$y = 40

$lblRuleName = New-Object System.Windows.Forms.Label
$lblRuleName.Text = "Rule Name:"
$lblRuleName.Location = New-Object System.Drawing.Point(10, $y)
$lblRuleName.Size = New-Object System.Drawing.Size(150, 20)
$panelRight.Controls.Add($lblRuleName)

$txtRuleName = New-Object System.Windows.Forms.TextBox
$txtRuleName.Location = New-Object System.Drawing.Point(170, $y)
$txtRuleName.Size = New-Object System.Drawing.Size(300, 20)
$txtRuleName.Anchor = "Top,Left,Right"
$panelRight.Controls.Add($txtRuleName)

$y += 30

$lblDisplayName = New-Object System.Windows.Forms.Label
$lblDisplayName.Text = "Display Name:"
$lblDisplayName.Location = New-Object System.Drawing.Point(10, $y)
$lblDisplayName.Size = New-Object System.Drawing.Size(150, 20)
$panelRight.Controls.Add($lblDisplayName)

$txtDisplayName = New-Object System.Windows.Forms.TextBox
$txtDisplayName.Location = New-Object System.Drawing.Point(170, $y)
$txtDisplayName.Size = New-Object System.Drawing.Size(300, 20)
$txtDisplayName.Anchor = "Top,Left,Right"
$panelRight.Controls.Add($txtDisplayName)

$y += 30

$lblProcessName = New-Object System.Windows.Forms.Label
$lblProcessName.Text = "Process Name:"
$lblProcessName.Location = New-Object System.Drawing.Point(10, $y)
$lblProcessName.Size = New-Object System.Drawing.Size(150, 20)
$panelRight.Controls.Add($lblProcessName)

$cmbProcessName = New-Object System.Windows.Forms.ComboBox
$cmbProcessName.Location = New-Object System.Drawing.Point(170, $y)
$cmbProcessName.Size = New-Object System.Drawing.Size(200, 20)
$cmbProcessName.DropDownStyle = "DropDown"
$cmbProcessName.AutoCompleteMode = "SuggestAppend"
$cmbProcessName.AutoCompleteSource = "ListItems"
$cmbProcessName.Add_TextChanged({
    Update-MatchingWindows
})
$panelRight.Controls.Add($cmbProcessName)

$btnRefreshProcesses = New-Object System.Windows.Forms.Button
$btnRefreshProcesses.Text = "Refresh"
# Fix arithmetic: explicitly calculate Y position
$refreshButtonY = ([int]$y) - 2
$btnRefreshProcesses.Location = New-Object System.Drawing.Point(380, $refreshButtonY)
$btnRefreshProcesses.Size = New-Object System.Drawing.Size(90, 24)
$btnRefreshProcesses.Add_Click({
    $cmbProcessName.Items.Clear()
    $processes = Get-RunningProcesses
    foreach ($proc in $processes) {
        $cmbProcessName.Items.Add($proc) | Out-Null
    }
})
$panelRight.Controls.Add($btnRefreshProcesses)

$y += 30

$lblTitlePattern = New-Object System.Windows.Forms.Label
$lblTitlePattern.Text = "Title Pattern:"
$lblTitlePattern.Location = New-Object System.Drawing.Point(10, $y)
$lblTitlePattern.Size = New-Object System.Drawing.Size(150, 20)
$panelRight.Controls.Add($lblTitlePattern)

$txtTitlePattern = New-Object System.Windows.Forms.TextBox
$txtTitlePattern.Location = New-Object System.Drawing.Point(170, $y)
$txtTitlePattern.Size = New-Object System.Drawing.Size(300, 20)
$txtTitlePattern.Anchor = "Top,Left,Right"
$txtTitlePattern.Add_TextChanged({
    Update-MatchingWindows
})
$panelRight.Controls.Add($txtTitlePattern)

$lblPatternHelp = New-Object System.Windows.Forms.Label
$lblPatternHelp.Text = "(Use * for any characters, ? for single character. Leave empty for any window)"
# Fix arithmetic: explicitly calculate Y position
$patternHelpY = ([int]$y) + 22
$lblPatternHelp.Location = New-Object System.Drawing.Point(170, $patternHelpY)
$lblPatternHelp.Size = New-Object System.Drawing.Size(450, 20)
$lblPatternHelp.ForeColor = [System.Drawing.Color]::Gray
$lblPatternHelp.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$panelRight.Controls.Add($lblPatternHelp)

$y += 50

$lblMonitor = New-Object System.Windows.Forms.Label
$lblMonitor.Text = "Monitor Number:"
$lblMonitor.Location = New-Object System.Drawing.Point(10, $y)
$lblMonitor.Size = New-Object System.Drawing.Size(150, 20)
$panelRight.Controls.Add($lblMonitor)

$numMonitor = New-Object System.Windows.Forms.NumericUpDown
$numMonitor.Location = New-Object System.Drawing.Point(170, $y)
$numMonitor.Size = New-Object System.Drawing.Size(80, 20)
$numMonitor.Minimum = 1
$numMonitor.Maximum = 10
$numMonitor.Value = 1
$panelRight.Controls.Add($numMonitor)

$y += 30

$lblPosition = New-Object System.Windows.Forms.Label
$lblPosition.Text = "Position:"
$lblPosition.Location = New-Object System.Drawing.Point(10, $y)
$lblPosition.Size = New-Object System.Drawing.Size(150, 20)
$panelRight.Controls.Add($lblPosition)

$cmbPosition = New-Object System.Windows.Forms.ComboBox
$cmbPosition.Location = New-Object System.Drawing.Point(170, $y)
$cmbPosition.Size = New-Object System.Drawing.Size(150, 20)
$cmbPosition.DropDownStyle = "DropDownList"
$cmbPosition.Items.AddRange(@("left", "right", "full"))
$cmbPosition.SelectedIndex = 0
$panelRight.Controls.Add($cmbPosition)

$y += 40

$lblMatchingWindows = New-Object System.Windows.Forms.Label
$lblMatchingWindows.Text = "Matching Windows:"
$lblMatchingWindows.Location = New-Object System.Drawing.Point(10, $y)
$lblMatchingWindows.Size = New-Object System.Drawing.Size(650, 20)
$panelRight.Controls.Add($lblMatchingWindows)

$y += 25

$txtMatchingWindows = New-Object System.Windows.Forms.TextBox
$txtMatchingWindows.Location = New-Object System.Drawing.Point(10, $y)
$txtMatchingWindows.Size = New-Object System.Drawing.Size(640, 150)
$txtMatchingWindows.Multiline = $true
$txtMatchingWindows.ScrollBars = "Vertical"
$txtMatchingWindows.ReadOnly = $true
$txtMatchingWindows.Anchor = "Top,Left,Right,Bottom"
$txtMatchingWindows.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtMatchingWindows.Text = "Enter process name to see matching windows"
$panelRight.Controls.Add($txtMatchingWindows)

$y += 160

$btnSaveRule = New-Object System.Windows.Forms.Button
$btnSaveRule.Text = "Save Rule"
$btnSaveRule.Location = New-Object System.Drawing.Point(10, $y)
$btnSaveRule.Size = New-Object System.Drawing.Size(150, 35)
$btnSaveRule.Anchor = "Bottom,Left"
$btnSaveRule.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnSaveRule.Add_Click({
    if (Save-CurrentRule) {
        Clear-RuleEditor
    }
})
$panelRight.Controls.Add($btnSaveRule)

$btnClearFields = New-Object System.Windows.Forms.Button
$btnClearFields.Text = "Clear Fields"
$btnClearFields.Location = New-Object System.Drawing.Point(170, $y)
$btnClearFields.Size = New-Object System.Drawing.Size(120, 35)
$btnClearFields.Anchor = "Bottom,Left"
$btnClearFields.Add_Click({
    Clear-RuleEditor
})
$panelRight.Controls.Add($btnClearFields)

$form.Controls.Add($splitContainer)

# ============================================================================
# FORM EVENTS
# ============================================================================

$form.Add_FormClosing({
    if ($script:UnsavedChanges) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "You have unsaved changes. Exit anyway?",
            "Unsaved Changes",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
            $_.Cancel = $true
        }
    }
})

# ============================================================================
# INITIALIZATION
# ============================================================================

try {
    $processes = Get-RunningProcesses
    foreach ($proc in $processes) {
        $cmbProcessName.Items.Add($proc) | Out-Null
    }
    
    if ($ConfigPath -and (Test-Path $ConfigPath)) {
        Load-Configuration -Path $ConfigPath
    }
    
    $form.Add_Shown({$form.Activate()})
    [void]$form.ShowDialog()
    
} catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Error initializing GUI: $_",
        "Initialization Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}

exit 0
