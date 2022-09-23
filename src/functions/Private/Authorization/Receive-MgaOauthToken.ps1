function Receive-MgaOauthToken {
    [CmdletBinding()]
    param (
        [string]
        $ApplicationID, 
        [string]
        $Tenant,
        [string]
        $Thumbprint, 
        [switch]
        $DeviceCode,
        $Certificate, 
        $ClientSecret,
        [string]
        $ManagedIdentity,
        [System.Net.ICredentials]
        $UserCredentials
    )
    try {
        $Script:MgaSession.Tenant = $Tenant
        $Script:MgaSession.ApplicationID = $ApplicationID
        if ($ClientSecret) {
            if ($clientsecret.gettype().name -ne 'securestring') {
                $Secret = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force
            }
            else {
                $Secret = $ClientSecret
            }
            $Script:MgaSession.Secret = $Secret
            $TempPass = [PSCredential]::new('.', $Secret).GetNetworkCredential().Password
            if (!($Script:MgaSession.AccessToken) ) {
                Get-MgaMSALAccessToken -ApplicationID $ApplicationID -Tenant $Tenant -Secret $TempPass
            }
            else {
                Clear-MgaMSALAccessToken -ApplicationID $ApplicationID -Tenant $Tenant -ClientSecret $ClientSecret   
            }
        }
        elseif (($Certificate) -or ($Thumbprint)) {
            if ($Thumbprint) {
                $Certificate = Get-Item "Cert:\CurrentUser\My\$Thumbprint" -ErrorAction SilentlyContinue
                if ($null -eq $Certificate) {
                    $Certificate = Get-Item "Cert:\localMachine\My\$Thumbprint" -ErrorAction SilentlyContinue
                }
                if ($null -eq $Certificate) {
                    throw "No certificate found with thumbprint: $Thumbprint found... Exiting script..."
                }
            }
            $Script:MgaSession.Certificate = $Certificate
            if (!($Script:MgaSession.AccessToken) ) {
                Get-MgaMSALAccessToken -ApplicationID $ApplicationID -Tenant $Tenant -Certificate $Certificate
            }
            else {
                Clear-MgaMSALAccessToken -ApplicationID $ApplicationID -Tenant $Tenant -Certificate $Certificate   
            }
        }
        elseif ($ManagedIdentity) {
            if (!($Script:MgaSession.ManagedIdentity)) {
                Get-MgaIdentityAccessToken -ManagedIdentity $ManagedIdentity
            }
            else {
                Clear-MgaIdentityAccessToken -ManagedIdentity $ManagedIdentity
            }
        }
        elseif ($DeviceCode) {
            if (!($Script:MgaSession.DeviceCode)) {
                Get-MgaDeviceCodeAccessToken
            }
            else {
                Clear-MgaDeviceCodeAccessToken -Tenant $Tenant
            }
        }         
    }
    catch {
        throw $_
    }
}