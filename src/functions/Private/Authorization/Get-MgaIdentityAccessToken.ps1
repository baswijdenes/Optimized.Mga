function Get-MgaIdentityAccessToken {
    param (
        $ManagedIdentity
    )
    function Test-MgaIdentityAccessToken {
        if ($null -eq $Script:MgaSession.ManagedIdentity.access_token) {
            throw 'No AccessToken retrieved... Exiting script...'
        }
        else {
            $Script:MgaSession.HeaderParameters = @{
                Authorization  = "$($Script:MgaSession.ManagedIdentity.token_type) $($Script:MgaSession.ManagedIdentity.access_token)"
                'Content-Type' = 'application/json'
            }
            $Script:MgaSession.ManagedIdentityType = $ManagedIdentity        
        }
    }
    try {
        $Resource = 'https://graph.microsoft.com/'
        if ($ManagedIdentity -eq 'AA') {
            $tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resource&api-version=2019-08-01"
            $Script:MgaSession.ManagedIdentity = Invoke-RestMethod -Method Get -Headers @{'X-IDENTITY-HEADER' = "$($env:IDENTITY_HEADER)" } -Uri $tokenAuthURI
            Test-MgaIdentityAccessToken
        }
        elseif ($ManagedIdentity -eq 'VM') {
            $Script:MgaSession.ManagedIdentity = Invoke-RestMethod -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$Resource" -Headers @{Metadata = 'true' }
            Test-MgaIdentityAccessToken
        } 
        elseif ($ManagedIdentity -eq 'TryMe') {
            try {
                Receive-MgaOauthToken -ManagedIdentity 'VM'
            }
            catch {
                try {
                    Receive-MgaOauthToken -ManagedIdentity 'AA'
                }
                catch {
                    throw 'Cannot find the Managed Identity type... Login is aborted...'
                }
            }
        }
    }
    catch {
        throw $_
    }
}