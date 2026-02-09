#Requires -Version 5.1

<#
.SYNOPSIS
    Analyzes Domain Controller health and reports diagnostic test results.

.DESCRIPTION
    Runs comprehensive DCDiag tests on a Domain Controller and reports the results.
    Tests include connectivity, replication, SYSVOL, DNS, and more. Results can
    optionally be saved to a WYSIWYG custom field for NinjaRMM reporting.
    
    The script requires:
    - Administrator privileges
    - Execution on a Domain Controller
    - Active Directory PowerShell module availability

.PARAMETER wysiwygCustomField
    Name of a WYSIWYG custom field to save HTML-formatted results.
    Must be a valid custom field name in NinjaRMM.

.EXAMPLE
    .\AD-DomainControllerHealthReport.ps1
    
    Runs all DCDiag tests and displays results in console output.

.EXAMPLE
    .\AD-DomainControllerHealthReport.ps1 -wysiwygCustomField "DCHealthReport"
    
    Runs tests and saves HTML results to the specified custom field.

.NOTES
    Minimum OS Architecture Supported: Windows Server 2016
    Version: 2.0
    Release Notes:
    - 2.0: Standards compliance refactor (logging, validation, error handling)
    - 1.0: Initial Release

.LINK
    https://docs.microsoft.com/windows-server/identity/ad-ds/manage/dcdiag
#>

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$wysiwygCustomField
)

begin {
    $StartTime = Get-Date
    $ExitCode = 0
    
    # Function to log messages
    function Write-Log {
        param([String]$Message)
        Write-Output $Message
    }

    # If script form variables are used, replace command line parameters with their value
    if ($env:wysiwygCustomFieldName -and $env:wysiwygCustomFieldName -notlike "null") {
        $wysiwygCustomField = $env:wysiwygCustomFieldName
    }
    
    # Validate wysiwygCustomField if provided
    if ($wysiwygCustomField -and $wysiwygCustomField.Length -gt 200) {
        Write-Log "Error: Custom field name exceeds 200 character limit"
        exit 1
    }

    # Function to test if the current machine is a domain controller
    function Test-IsDomainController {
        $OS = if ($PSVersionTable.PSVersion.Major -lt 5) {
            Get-WmiObject -Class Win32_OperatingSystem
        }
        else {
            Get-CimInstance -ClassName Win32_OperatingSystem
        }

        # Check if the OS is a domain controller (ProductType 2)
        if ($OS.ProductType -eq "2") {
            return $true
        }
        return $false
    }

    function Get-DCDiagResults {
        # Define the list of DCDiag tests to run
        $DCDiagTestsToRun = "Connectivity", "Advertising", "FrsEvent", "DFSREvent", "SysVolCheck", "KccEvent", "KnowsOfRoleHolders", "MachineAccount", "NCSecDesc", "NetLogons", "ObjectsReplicated", "Replications", "RidManager", "Services", "SystemLog", "VerifyReferences", "CheckSDRefDom", "CrossRefValidation", "LocatorCheck", "Intersite"
    
        foreach ($DCTest in $DCDiagTestsToRun) {
            $OutputFile = "$env:TEMP\dc-diag-$DCTest.txt"
            
            try {
                # Run DCDiag for the current test and save the output to a file
                $DCDiag = Start-Process -FilePath "DCDiag.exe" -ArgumentList "/test:$DCTest", "/f:$OutputFile" -PassThru -Wait -NoNewWindow

                # Check if the DCDiag test failed
                if ($DCDiag.ExitCode -ne 0) {
                    Write-Log "Error: DCDiag test $DCTest exited with code $($DCDiag.ExitCode)"
                    exit 1
                }

                # Read the raw results from the output file and filter out empty lines
                $RawResult = Get-Content -Path $OutputFile | Where-Object { $_.Trim() }
            
                # Find the status line indicating whether the test passed or failed
                $StatusLine = $RawResult | Where-Object { $_ -match "\. .* test $DCTest" }

                # Extract the status (passed or failed) from the status line
                $Status = $StatusLine -split ' ' | Where-Object { $_ -like "passed" -or $_ -like "failed" }

                # Create a custom object to store the test results
                [PSCustomObject]@{
                    Test   = $DCTest
                    Status = $Status
                    Result = $RawResult
                }
            }
            catch {
                Write-Log "Error: Failed to run DCDiag test $DCTest - $($_.Exception.Message)"
                throw
            }
            finally {
                # Remove the temporary output file if it exists
                if (Test-Path $OutputFile) {
                    Remove-Item -Path $OutputFile -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter()]
            [String]$Type,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value,
            [Parameter()]
            [String]$DocumentName
        )
    
        $Characters = $Value | Out-String | Measure-Object -Character | Select-Object -ExpandProperty Characters
        if ($Characters -ge 200000) {
            throw [System.ArgumentOutOfRangeException]::New("Character limit exceeded: the value is greater than or equal to 200,000 characters.")
        }
        
        # If requested to set the field value for a Ninja document, specify it here
        $DocumentationParams = @{}
        if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }
        
        # This is a list of valid fields that can be set
        $ValidFields = "Attachment", "Checkbox", "Date", "Date or Date Time", "Decimal", "Dropdown", "Email", "Integer", "IP Address", "MultiLine", "MultiSelect", "Phone", "Secure", "Text", "Time", "URL", "WYSIWYG"
        if ($Type -and $ValidFields -notcontains $Type) {
            Write-Log "Warning: $Type is an invalid type. Please check documentation for valid types."
        }
        
        # The field below requires additional information to set
        $NeedsOptions = "Dropdown"
        if ($DocumentName) {
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Docs-Options -AttributeName $Name @DocumentationParams 2>&1
            }
        }
        else {
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Options -Name $Name 2>&1
            }
        }
        
        # If an error is received with an exception property, exit the function with that error information
        if ($NinjaPropertyOptions.Exception) { throw $NinjaPropertyOptions }
        
        # Convert input values to appropriate formats for different field types
        switch ($Type) {
            "Checkbox" {
                $NinjaValue = [System.Convert]::ToBoolean($Value)
            }
            "Date or Date Time" {
                $Date = (Get-Date $Value).ToUniversalTime()
                $TimeSpan = New-TimeSpan (Get-Date "1970-01-01 00:00:00") $Date
                $NinjaValue = $TimeSpan.TotalSeconds
            }
            "Dropdown" {
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selection = $Options | Where-Object { $_.Name -eq $Value } | Select-Object -ExpandProperty GUID
        
                if (-not $Selection) {
                    throw [System.ArgumentOutOfRangeException]::New("Value is not present in dropdown options.")
                }
        
                $NinjaValue = $Selection
            }
            default {
                $NinjaValue = $Value
            }
        }
        
        # Set the field differently depending on whether it's a field in a Ninja Document or not
        if ($DocumentName) {
            $CustomField = Ninja-Property-Docs-Set -AttributeName $Name -AttributeValue $NinjaValue @DocumentationParams 2>&1
        }
        else {
            $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
        }
        
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }
   
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

process {
    try {
        Write-Log "Starting Domain Controller Health Report"
        Write-Log "Timestamp: $StartTime"
        
        # Check if the script is run with Administrator privileges
        if (!(Test-IsElevated)) {
            Write-Log "Error: Access Denied - Administrator privileges required"
            exit 1
        }
        Write-Log "Administrator privileges verified"

        # Check if the script is run on a Domain Controller
        if (!(Test-IsDomainController)) {
            Write-Log "Error: This script must be executed on a Domain Controller"
            exit 1
        }
        Write-Log "Domain Controller role verified"

        # Initialize lists to store passing and failing tests
        $PassingTests = New-Object System.Collections.Generic.List[object]
        $FailedTests = New-Object System.Collections.Generic.List[object]

        # Notify the user that the tests are being retrieved
        Write-Log ""
        Write-Log "Retrieving Directory Server Diagnosis Test Results"
        $TestResults = Get-DCDiagResults
        Write-Log "DCDiag tests completed"

        # Process each test result
        foreach ($Result in $TestResults) {
            $TestFailed = $False

            # Check if any status in the result indicates a failure
            $Result.Status | ForEach-Object {
                if ($_ -notmatch "pass") {
                    $TestFailed = $True
                }
            }

            # Add the result to the appropriate list
            if ($TestFailed) {
                $FailedTests.Add($Result)
            }
            else {
                $PassingTests.Add($Result)
            }
        }

        # Optionally set a WYSIWYG custom field if specified
        if ($wysiwygCustomField) {
            try {
                Write-Log ""
                Write-Log "Building HTML for Custom Field"

                # Create an HTML report for the custom field
                $HTML = New-Object System.Collections.Generic.List[object]

                $HTML.Add("<h1 style='text-align: center'>Directory Server Diagnosis Test Results (DCDiag.exe)</h1>")
                $FailedPercentage = $([math]::Round((($FailedTests.Count / ($FailedTests.Count + $PassingTests.Count)) * 100), 2))
                $SuccessPercentage = 100 - $FailedPercentage
                $HTML.Add(
                    @"
<div class='p-3 linechart'>
    <div style='width: $FailedPercentage%; background-color: #C6313A;'></div>
    <div style='width: $SuccessPercentage%; background-color: #007644;'></div>
        </div>
        <ul class='unstyled p-3' style='display: flex; justify-content: space-between; '>
            <li><span class='chart-key' style='background-color: #C6313A;'></span><span>Failed ($($FailedTests.Count))</span></li>
            <li><span class='chart-key' style='background-color: #007644;'></span><span>Passed ($($PassingTests.Count))</span></li>
        </ul>
"@
                )

                # Add failed tests to the HTML report
                $FailedTests | Sort-Object Test | ForEach-Object {
                    $HTML.Add(
                        @"
<div class='info-card error'>
    <i class='info-icon fa-solid fa-circle-exclamation'></i>
    <div class='info-text'>
        <div class='info-title'>$($_.Test)</div>
        <div class='info-description'>
            $($_.Result | Out-String)
        </div>
    </div>
</div>
"@
                    )
                }

                # Add passing tests to the HTML report
                $PassingTests | Sort-Object Test | ForEach-Object {
                    $HTML.Add(
                        @"
<div class='info-card success'>
    <i class='info-icon fa-solid fa-circle-check'></i>
    <div class='info-text'>
        <div class='info-title'>$($_.Test)</div>
        <div class='info-description'>
            Test passed.
        </div>
    </div>
</div>
"@
                    )
                }

                # Set the custom field with the HTML report
                Write-Log "Attempting to set Custom Field: $wysiwygCustomField"
                Set-NinjaProperty -Name $wysiwygCustomField -Value $HTML
                Write-Log "Successfully set Custom Field: $wysiwygCustomField"
            }
            catch {
                Write-Log "Error: Failed to set custom field - $($_.Exception.Message)"
                $ExitCode = 1
            }
        }

        # Display the list of passing tests
        if ($PassingTests.Count -gt 0) {
            Write-Log ""
            $PassingTestList = ($PassingTests.Test | Sort-Object) -join ", "
            Write-Log "Passing Tests: $PassingTestList"
            Write-Log ""
        }

        # Display the list of failed tests with detailed output
        if ($FailedTests.Count -gt 0) {
            Write-Log "Alert: Failed Tests Detected"
            $FailedTestList = ($FailedTests.Test | Sort-Object) -join ", "
            Write-Log "Failed Tests: $FailedTestList"

            Write-Log ""
            Write-Log "### Detailed Output ###"
            $FailedTests | Sort-Object Test | ForEach-Object {
                Write-Log ""
                Write-Log ($_.Result | Out-String)
                Write-Log ""
            }
            $ExitCode = 1
        }
        else {
            Write-Log "All Directory Server Diagnosis Tests Pass"
        }
    }
    catch {
        Write-Log "Error: Script execution failed - $($_.Exception.Message)"
        $ExitCode = 1
    }
}

end {
    $EndTime = Get-Date
    $Duration = $EndTime - $StartTime
    Write-Log ""
    Write-Log "Script execution completed in $($Duration.TotalSeconds) seconds"
    Write-Log "Exit Code: $ExitCode"
    
    exit $ExitCode
}