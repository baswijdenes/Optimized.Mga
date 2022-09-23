function Get-MgaMSALAccessToken {
    param (
        $ApplicationID,
        $Tenant,
        $Secret,
        $Certificate
    )
    try {
        [System.Collections.Generic.List[String]]$LoginScope = @('https://graph.microsoft.com/.default')
        $Builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($ApplicationID).WithTenantId($Tenant)
        if ($Secret) {
            $Builder = $Builder.WithClientSecret($Secret).Build()
        }
        elseif ($Certificate) {
            $Builder = $Builder.WithCertificate($Certificate).Build()  
        }
        $Script:MgaSession.AccessToken = $Builder.AcquireTokenForClient($LoginScope).ExecuteAsync()
        if ($null -eq $Script:MgaSession.AccessToken.result.AccessToken) {
            throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
        }
        else {
            $Script:MgaSession.headerParameters = @{
                Authorization  = $Script:MgaSession.AccessToken.result.CreateAuthorizationHeader()
                'Content-Type' = 'application/json'
            }
        }
    }
    catch {
        throw $_
    }
}