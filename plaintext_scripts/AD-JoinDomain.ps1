$JoinCred = [PSCredential]::new($env:user, $(ConvertTo-SecureString -String $env:pass" -AsPlainText -Force))
Add-Computer -DomainName $env:domain -Credential $JoinCred -PassThru -Verbose -Restart