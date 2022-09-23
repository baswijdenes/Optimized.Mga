function Update-MgaOauthToken {
    try {
        $ReceiveMgaOauthTokenSplat = @{
            ApplicationId = $Script:MgaSession.ApplicationID
            Tenant         = $Script:MgaSession.Tenant
        }
        if ($null -ne $Script:MgaSession.Secret) {
            Receive-MgaOauthToken @ReceiveMgaOauthTokenSplat -ClientSecret $Script:MgaSession.Secret
        }
        elseif ($null -ne $Script:MgaSession.Certificate) {
            Receive-MgaOauthToken @ReceiveMgaOauthTokenSplat -Certificate $Script:MgaSession.Certificate
        }
        elseif ($null -ne $Script:MgaSession.ManagedIdentity) {
            Receive-MgaOauthToken -ManagedIdentity $Script:MgaSession.ManagedIdentityType
        }
        elseif ($null -ne $Script:MgaSession.DeviceCode) {
            Receive-MgaOauthToken -DeviceCode
        }
        else {
            Throw 'You need to run Connect-Mga before you can continue... Exiting script...'
        }
    }
    catch {
        throw $_
    }
}