function Clear-MgaMSALAccessToken {
    param (
        $ApplicationId,
        $Tenant,
        $ClientSecret,
        $Certificate,
        $Type
    )
    try {
        $Date = Get-Date
        $UTCDate = [System.TimeZoneInfo]::ConvertTimeToUtc($Date)
        $OauthExpiryTime = $Script:MgaSession.AccessToken.Result.ExpiresOn.UtcDateTime
        if ($OauthExpiryTime -le $UTCDate) {
            $Script:MgaSession.AccessToken = $null
            $ReceiveMgaOauthTokenSplat = @{
                ApplicationId = $ApplicationId
                Tenant        = $Tenant
            }
            if ($ClientSecret) {
                Receive-MgaOauthToken @ReceiveMgaOauthTokenSplat -ClientSecret $ClientSecret   
            }
            elseif ($Certificate) {
                Receive-MgaOauthToken @ReceiveMgaOauthTokenSplat -Certificate $Certificate  
            }        
        }
    }
    catch {
        throw $_
    }
}