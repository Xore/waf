$JoinCred = [PSCredential]::new($env:user, $(ConvertTo-SecureString -String $env:pass -AsPlainText -Force))
Test-ComputerSecureChannel -Repair -Credential $JoinCred -Verbose