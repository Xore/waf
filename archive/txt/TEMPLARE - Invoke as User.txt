<#
.SYNOPSIS
    Wrapper function for Invoke-AsUser module command Invoke-AsCurrentUser. 

.DESCRIPTION
    Wrapper function for Invoke-AsUser module command Invoke-AsCurrentUser, extending
    its functionality to allow arguments to be passed into the script using enviornment variables. 

    The function takes in a scriptblock of code and a hashtable of arguments, and injects the 
    arguments into the user's environment variables. The scriptblock is then run as the user.

    The function returns a hashtable with two properties: Output and Data. The Output property contains
    whatever was outputted to the console, and the Data property contains the hashtable returned by the scriptblock.

    In order to return a hashtable, the scriptblock must return a Json object. This is done by using the ConvertTo-Json cmdlet.

    If the scriptblock is greater than 8190 characters, it will be cached to disk and run from there.

    The function also cleans up the environment variables and the script file after it has run.

.PARAMETER Scriptblock
    The scriptblock to be run as the user

.PARAMETER Arguments
    A hashtable of arguments to be passed into the scriptblock. The keys of the hashtable will be used as the names of the environment variables.

.PARAMETER Verbose
    If specified, additional logging will be outputted to the console.

.EXAMPLE
    Invoke-AsUser.ps1 <scriptblock> <Hash Table of arguments> 

    Arguments can be referenced by name in the scriptblock using $env:<argumentname>. Example: $env:firstname

.EXAMPLE

    @{
        Test123 = 'ASDF'
        Var2 = 12345
    }

    $script = {
        Write-Output $env:Test123
        Write-Output $env:Var2
    }

    $output = Invoke-AsUser -Scriptblock $script -Arguments $arguments

.VERSION
    1.2

.AUTHOR
    Joshua Gehl
#>

#==========================================================================================
# Invoke-AsUser wrapper function (copy the function below into your own script to use it)
#==========================================================================================
function Invoke-AsUser {
    param (
        [Parameter(Mandatory=$true)] [scriptblock]$Scriptblock,
        [hashtable]$Arguments
    )

    # Install RunAsUser module if not already installed. 
    if (-not (Get-Module -ListAvailable -Name RunAsUser)) {
        throw [System.ApplicationException] "RunAsUser module not found."
    }
    
    # Verify a user is logged in
    try{
        # Get domain, username, create the user object, then find the user's SID
        $domain, $userName = (Get-WmiObject -Class Win32_ComputerSystem).UserName -split '\\', 2
        $user = [System.Security.Principal.NTAccount]::new($domain, $userName)
        $sid  = $user.Translate([System.Security.Principal.SecurityIdentifier]).Value
        
        Write-Verbose "Current User: $($userName)"
    } catch{
        throw [System.SystemException] "No user accounts are currently logged in."
    }

    # Inject arguments into user's environment variables if arguments were passed in
    if ($Arguments) {
        Write-Verbose "Injecting variables into user's environment..."
        foreach ($key in $Arguments.Keys) {

            # If reg property already exists, throw error and exit. Prevents overwriting important reg properties
            if ((Get-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment").psobject.Properties | Where-Object Name -eq ${key}) {
                throw [System.SystemException] "Registry key already exists! To prevent overwriting, please rename variable."
            }

            # Inject reg properties
            Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment" -Name ${key} -Value $($Arguments.$key) -Type String
            Write-Verbose "`$env:${key} = $($Arguments.$key)`t`tInjected!"
        }
    }

    # If script block is greater than 8190 chars, cache it to disk (limitation of powershell v5)
    if ($Scriptblock.ToString().Length -gt 8190) {
      
        Write-Verbose "Script longer than 8190 characters, caching to disk..."
        $scriptPath = "C:\Users\$($userName)\AppData\Local\Temp\$(New-Guid).ps1"
        Add-Content -Path $scriptPath -Value $Scriptblock

        # Overwrite $Scriptblock to call it using absolute pathing to the file
        $Scriptblock = [ScriptBlock]::Create("powershell $($scriptPath)")

        Write-Verbose "Script cached to: $($scriptPath)`n"
    }


    # Prepare to run script and collect output
    Write-Verbose "Running script..."

    # Hashtable to store output
    $returnData = @{
        Stdout = ''
        Data = @{}
    }

    # Run the script and capture the output
    $scriptOutput = Invoke-AsCurrentUser -scriptblock $Scriptblock -CaptureOutput

    # Since the return value is the last thing that is outputted, we know that the final characater will be a closing bracket
    # Iterate over the string backwards to find the first opening bracket
    $bracketCounter = 0
    for ($i = $scriptOutput.Length - 1; $i -ge 0; $i--) {

        if ($scriptOutput[$i] -eq "}") {
            $bracketCounter += 1
            
        } elseif ($scriptOutput[$i] -eq "{") {
            $bracketCounter -= 1
            
            # If the bracket counter is 0, we know that we have found the first opening bracket
            # This means that everything after this point is the Json object
            if ($bracketCounter -eq 0) {

                # If the index is not 0, we know that there is output before the Json object
                # We need to capture that output and store it in the Output property
                if ($i -ne 0) {
                    $returnData.Stdout = -join ($scriptOutput[0..($i-1)])
                }

                # Convert the Json object to a hashtable and store it in the Data property
                $returnData.Data = (-join ($scriptOutput[$i..($scriptOutput.Length)]))| ConvertFrom-Json
                break
            }
        }
    }

    # If the Json object was not found, place output in the Output property
    if ($returnData.Data.Count -eq 0) {
        $returnData.Stdout = $scriptOutput
    }

    Write-Verbose "Script ran! Output:"
    Write-Verbose $returnData.Stdout
    Write-Verbose $returnData.Data

    # Clean up reg properties if they were passed in
    Write-Verbose "Cleaning up..."
    if($Arguments){
        foreach ($key in $Arguments.Keys) {
            Remove-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment" -Name ${key}
            Write-Verbose "`$env:${key} = $($Arguments.$key)`t`tDeleted!"
        }
    }
    
    # Clean up script if it was generated
    if ($scriptPath) {
        Remove-Item -Path $scriptPath
        Write-Verbose "Script removed. "
    }

    return $returnData
}

#==========================================================================================
#==========================================================================================

#==========================================================================================
# Example Code
#==========================================================================================

Write-Output "===================================================================="
Write-Output "1. Returning just a hashtable"
Write-Output "===================================================================="

# Script returns a hashmap and has nothing else written to output
$script1 = {
    return @{
        ABC = 5
        DEF = "FFFF"
        UserChoice = "N"
        MAP = @{
            TEST = 1
        }
    } | ConvertTo-Json # Object must be converted to Json before returning
}

$output1 = Invoke-AsUser -Scriptblock $script1
$output1.Stdout
$output1.Data | Format-Table


Write-Output "===================================================================="
Write-Output "2. Returning the output and a hashtable"
Write-Output "===================================================================="


$script2 = {

    Write-Output "Test123"

    return @{
        ABC = 5
        DEF = "FFFF"
        UserChoice = "N"
        MAP = @{
            TEST = 1
        }
        Test123 = 5.55555
    } | ConvertTo-Json # Object must be converted to Json before returning
}

$output2 = Invoke-AsUser -Scriptblock $script2
$output2.Stdout
$output2.Data | Format-Table


Write-Output "===================================================================="
Write-Output "3. Returning as plaintext"
Write-Output "===================================================================="

$script3 = {
    Write-Output "ABC"
    Write-Output "DEF"
    Write-Output "123"
}

$output3 = Invoke-AsUser -Scriptblock $script3
$output3.Stdout
$output3.Data | Format-Table

Write-Output "===================================================================="
Write-Output "4. Passing arguments"
Write-Output "===================================================================="

# Arguments can be passed in using a hashtable.
# Arguments are accessible within the scriptblock by using environment variable notation
# Example: Test123 would be accessed using $env:Test123
$arguments = @{
    Test123 = 'ASDF'
    Var2 = 12345
}

# Script will demonstrate reading variables
$script4 = {
    Write-Output $env:Test123
    Write-Output $env:Var2
}

# Use the -Arguments flag to pass in the arguments hashtable
$output4 = Invoke-AsUser -Scriptblock $script4 -Arguments $arguments
$output4.Stdout
$output4.Data | Format-Table

Write-Output "===================================================================="
Write-Output "5. Verbose"
Write-Output "===================================================================="

$script3 = {
    Write-Output "ABC"
    Write-Output "DEF"
    Write-Output "123"
}

# -Verbose can be added to the cmdlet to include additional logging
$output5 = Invoke-AsUser -Scriptblock $script3 -Verbose
$output5.Stdout
$output5.Data | Format-Table
