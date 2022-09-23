function Clear-MgaDeviceCodeAccessToken {
    try {
        $Date = Get-Date
        $UTCDate = [System.TimeZoneInfo]::ConvertTimeToUtc($Date)
        [datetime]$UnixDateTime = '1970-01-01 00:00:00'
        $OauthExpiryTime = $UnixDateTime.AddSeconds($Script:MgaSession.DeviceCode.expires_on)
        if (($OauthExpiryTime -le $UTCDate) -and ($null -eq $Script:MgaSession.DeviceCode.Refresh_token)) {
            $Script:MgaSession.DeviceCode = $null
            Receive-MgaOauthToken -DeviceCode 
        }
        elseif (($OauthExpiryTime -le $UTCDate) -and ($null -ne $Script:MgaSession.DeviceCode.refresh_token)) {
            $Body = @{
                refresh_token = $Script:MgaSession.DeviceCode.refresh_token
                grant_type    = 'refresh_token'
            }
            try {
                $Script:MgaSession.DeviceCode = Invoke-RestMethod -Method Post -Uri 'https://login.microsoftonline.com/organizations/oauth2/token?api-version=1.0' -Body $Body -UseBasicParsing -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning 'No AccessToken retrieved from the refresh_token... Renewing AccessToken by using variables...'
            }
            if ($null -eq $Script:MgaSession.DeviceCode.access_token) {
                $Script:MgaSession.DeviceCode = $null
                Receive-MgaOauthToken -DeviceCode
            }
            else {
                $Script:MgaSession.headerParameters = @{
                    Authorization  = "$($Script:MgaSession.DeviceCode.token_type) $($Script:MgaSession.DeviceCode.access_token)"
                    'Content-Type' = 'application/json'
                }
            }
        }
    }
    catch {
        throw $_
    }
}