function Clear-MgaIdentityAccessToken {
    param (
        $ManagedIdentity
    )
    try {
        [datetime]$UnixDateTime = '1970-01-01 00:00:00'
        $Date = Get-Date
        $UTCDate = [System.TimeZoneInfo]::ConvertTimeToUtc($Date)
        $OauthExpiryTime = $UnixDateTime.AddSeconds($Script:MgaSession.ManagedIdentity.expires_on)
        if ($OauthExpiryTime -le $UTCDate) {
            $Script:MgaSession.ManagedIdentity = $null
            Receive-MgaOauthToken -ManagedIdentity $ManagedIdentity
        }
    }
    catch {
        throw $_
    }
}       