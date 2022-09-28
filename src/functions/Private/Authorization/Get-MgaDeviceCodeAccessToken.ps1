function Get-MgaDeviceCodeAccessToken {
    try {
        $ClientId = '1b730954-1685-4b74-9bfd-dac224a7b894'
        $DeviceCodeRequestParams = @{
            Method          = 'POST'
            Uri             = 'https://login.microsoftonline.com/common/oauth2/devicecode'
            Body            = @{
                client_id = $ClientId
                resource  = 'https://graph.microsoft.com/'
            }
            UseBasicParsing = $true
        }           
        $DeviceCodeRequest = Invoke-RestMethod @DeviceCodeRequestParams
        Write-Host $DeviceCodeRequest.message
        $LoggedInTryCount = 0
        while ($null -eq $Script:MgaSession.DeviceCode) {
            try {
                $TokenRequestParams = @{
                    Method = 'POST'
                    Uri    = 'https://login.microsoftonline.com/organizations/oauth2/token'
                    Body   = @{
                        grant_type = 'urn:ietf:params:oauth:grant-type:device_code'
                        code       = $DeviceCodeRequest.device_code
                        client_id  = $ClientId
                    }
                }
                $Script:MgaSession.DeviceCode = Invoke-RestMethod @TokenRequestParams
            } 
            catch {
                if ($LoggedInTryCount -le 890) {
                    Start-Sleep -Seconds 2
                    $LoggedInTryCount = $LoggedInTryCount + 2
                }
                else {
                    Throw 'The user has not verified the DeviceCode within 15 minutes... Login is aborted...'
                }
            }
        }                     
        if ($null -eq $Script:MgaSession.DeviceCode.access_token) {
            throw 'No AccessToken retrieved... Exiting script...'
        }
        else {
            $Script:MgaSession.headerParameters = @{
                Authorization  = "$($Script:MgaSession.DeviceCode.token_type) $($Script:MgaSession.DeviceCode.access_token)"
                'Content-Type' = 'application/json'
            }
        }
    }
    catch {
        throw $_
    }
}