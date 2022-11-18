function Get-MgaToken {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/

    .LINK 
    https://baswijdenes.com/c/microsoft/mga/

    .SYNOPSIS
    Get-MgaToken will retreive a RefreshToken for the Microsoft Graph API.
    
    .DESCRIPTION    
    The AccessToken is automatically renewed when you use cmdlets.
    
    .PARAMETER Certificate
    Use Certificate to get an AccessToken with a Certificate.
    You can also use a Certificate thumbprint.

    .PARAMETER Secret
    Use a ClientSecret to get an AccessToken.
    
    .PARAMETER ClientId
    CliendId is the AzureAD Application registration ObjectId.

    .PARAMETER Identity
    Parameter is a switch, it can be used for when it's a Managed Identity authenticating to Microsoft Graph API.
    Examples are: Azure Automation, Azure Functions, & Azure Virtual Machines.

    .PARAMETER DeviceCode
    Parameter is a switch and it will let you log in with a DeviceCode. 
    It will open a browser window and you will have to log in with your credentials. 
    You have 15 minutes before it cancels the request.
    
    .PARAMETER TenantId
    TenantId is the TenantId or XXX.onmicrosoft.com address.

    .PARAMETER Force
    Use -Force when you want to overwrite the AccessToken with a new one.
    
    .EXAMPLE
    Get-MgaToken -ClientSecret '1yD3h~.KgROPO.K1sbRF~XXXXXXXXXXXXX' -CliendId 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -TenantId 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' 

    .EXAMPLE
    $Cert = get-ChildItem 'Cert:\LocalMachine\My\XXXXXXXXXXXXXXXXXXX'
    Get-MgaToken -Certificate $Cert -CliendId 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -TenantId 'XXXXXXXX.onmicrosoft.com'

    .EXAMPLE
    Get-MgaToken -Certificate '3A7328F1059E9802FAXXXXXXXXXXXXXX' -CliendId 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -TenantId 'XXXXXXXX.onmicrosoft.com' 

    .EXAMPLE
    Get-MgaToken -Credential $Cred -TenantId 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -CliendId 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX'

    .EXAMPLE
    Get-MgaToken -Identity

    .EXAMPLE
    Get-MgaToken -DeviceCode
    #>
    [CmdletBinding(DefaultParameterSetName = 'DeviceCode')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [ValidateScript( { ($_.length -eq 40) -or ([System.Security.Cryptography.X509Certificates.X509Certificate2]$_) })]
        [Alias('Thumbprint')]
        $Certificate,
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [Alias('ClientSecret', 'AppSecret', 'AppPass')]
        [string]
        $Secret,
        [Parameter(Mandatory = $true, ParameterSetName = 'ManagedIdentity')]
        [Alias('ManagedIdentity', 'ManagedSPN')]
        [switch]
        $Identity,
        [Parameter(Mandatory = $false, ParameterSetName = 'DeviceCode')]
        [switch]
        $DeviceCode,
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ManagedIdentity')]
        [Parameter(Mandatory = $false, ParameterSetName = 'DeviceCode')]
        [Alias('ApplicationID', 'AppID', 'App', 'Application')]
        [String]
        $ClientId,
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ManagedIdentity')]
        [Alias('Tenant')]
        [String]
        $TenantId,
        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )
    begin {
        try {
            if ($Force) {
                Write-Verbose 'Running Remove-MgaToken to force a new AccessToken'
                $null = Remove-MgaToken
            }
            else {
                if ($Script:MgaSession.headerParameters) {
                    $Confirmation = Read-Host 'You already have an AccessToken, are you sure you want to proceed? Type (Y)es to continue'
                    if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true') -or ($Confirmation -eq '(Y)es')) {
                        $null = Remove-MgaToken
                    }
                    else {
                        throw 'Login aborted'
                    }
                }
            }
            if ($Certificate.length -eq 40) {
                Write-Verbose 'Certificate is a string of 40 characters, updating value to search for certificate on client'
                $Thumbprint = $Certificate
            }
            Write-Verbose 'Creating MgaSession HashTable for Script scope'
            $MgaSession = @{
                headerParameters    = $null
                ApplicationID       = $null
                Tenant              = $null
                Secret              = $null
                Certificate         = $null
                AccessToken         = $null
                ManagedIdentity     = $null
                ManagedIdentityType = $null
                DeviceCode          = $null
                LoginScope          = $null
                OriginalHeader      = $null
            }
            $Null = New-Variable -Name MgaSession -Value $MgaSession -Scope Script -Force
        }
        catch {
            throw $_
        }
    }
    process { 
        try {
            $ReceiveMgaOauthToken = @{  
                ApplicationId = $ClientId
                Tenant        = $TenantId
            } 
            if ($Thumbprint) {
                $ReceiveMgaOauthToken.Add('Thumbprint', $Thumbprint)
                Receive-MgaOauthToken @ReceiveMgaOauthToken
            }
            elseif ($Certificate) {
                $ReceiveMgaOauthToken.Add('Certificate', $Certificate)
                Receive-MgaOauthToken @ReceiveMgaOauthToken 
            }
            elseif ($Secret) {
                $ReceiveMgaOauthToken.Add('ClientSecret', $Secret)
                Receive-MgaOauthToken @ReceiveMgaOauthToken
            }
            elseif ($Identity -eq $true) {
                Receive-MgaOauthToken -ManagedIdentity 'TryMe'
            }
            else {
                Start-Process 'https://microsoft.com/devicelogin'
                Receive-MgaOauthToken -DeviceCode
            }
        }
        catch {
            throw $_ 
        }  
    }
    end {
        return "AccessToken received, you can now use other cmdlets from module 'Mga'"

    }
}