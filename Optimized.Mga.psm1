#region main
function Connect-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Connect-Mga will retreive a RefreshToken for the Microsoft Graph API.
    
    .DESCRIPTION
    By selecting one of these parameters you log on with the following:

    ClientSecret: Will log you on with a ClientSecret.
    Certificate: Will log you on with a Certificate.
    UserCredentials: Will log you on with basic authentication.
    RedirectUri: Will log you on with MFA Authentication.
    ManagedIdentity: Will log you on with a Managed Identity.
    DeviceCode: Will log you on with a DeviceCode.
    The OauthToken is automatically renewed when you use cmdlets.
    
    .PARAMETER Certificate
    Use a Cert to log on. you can use where X's is the certificate thumbprint:
    $Cert = get-ChildItem 'Cert:\LocalMachine\My\XXXXXXXXXXXXXXXXXXX'
    Connect-Mga -Certificate $Cert -ApplicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -Tenant 'XXXXXXXX.onmicrosoft.com'
    
    .PARAMETER ClientSecret
    Parameter description
    
    .PARAMETER RedirectUri
    Use the RedirectUri in your AzureAD app to connect with MFA. 
    RedirectUri should look something like this:
    'msalXXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX://auth' 

    If you want to know more about how to log in via MFA with a RedirectUri, go to my blog:
    https://bwit.blog/how-to-start-with-microsoft-graph-in-powershell/#I_will_use_credentials
    
    
    .PARAMETER UserCredentials
    Use Get-Credential to log on with Basic Authentication. 
    
    .PARAMETER ApplicationID
    ApplicationID is the ID for the AzureAD application. It should look like this:
    'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX'

    .PARAMETER ManagedIdentity
    This is a switch for when it's a Managed Identity authenticating to Microsoft Graph API.

    .PARAMETER DeviceCode
    This parameter is a switch and it Will let you log in with a DeviceCode.
    
    .PARAMETER Tenant
    Tenant is the TenantID or onmicrosoft.com address. Don't confuse this with ApplicationID.

    I should look like this:
    'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX'
    Or
    XXXXXXX.onmicrosoft.com

    .PARAMETER Force
    Use -Force when you want to overwrite another connection (or Accept the confirmation).
    
    .EXAMPLE
    Connect-Mga -ClientSecret '1yD3h~.KgROPO.K1sbRF~XXXXXXXXXXXXX' -ApplicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -Tenant 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' 

    .EXAMPLE
    $Cert = get-ChildItem 'Cert:\LocalMachine\My\XXXXXXXXXXXXXXXXXXX'
    Connect-Mga -Certificate $Cert -ApplicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -Tenant 'XXXXXXXX.onmicrosoft.com'

    .EXAMPLE
    Connect-Mga -Thumbprint '3A7328F1059E9802FAXXXXXXXXXXXXXX' -ApplicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -Tenant 'XXXXXXXX.onmicrosoft.com' 

    .EXAMPLE
    Connect-Mga -UserCredentials $Cred -Tenant 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -ApplicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX'

    .EXAMPLE
    Connect-Mga -redirectUri 'msalXXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX://auth' -Tenant 'XXXXXXXX.onmicrosoft.com'  -ApplicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX'

    Connect-Mga -ManagedIdentity

    Connect-Mga -DeviceCode

    Connect-Mga -DeviceCode -Tenant 'XXXXXXXX.onmicrosoft.com'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        # Thumbprint length is always 40 characters. If this was not correct and the Certificate variable did not contain a Certificate the cmdlet already knows it will not be able to retrieve an AccessToken
        [ValidateScript( { ($_.length -eq 40) -or ([System.Security.Cryptography.X509Certificates.X509Certificate2]$_) })]
        [Alias('Thumbprint')]
        $Certificate,
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [Alias('Secret', 'AppSecret', 'AppPass')]
        [string]
        $ClientSecret, 
        [Parameter(Mandatory = $true, ParameterSetName = 'RedirectUri')]
        [Alias('MFA')]
        [String]
        $RedirectUri,
        [Parameter(Mandatory = $true, ParameterSetName = 'Credentials')]
        [System.Net.ICredentials]
        $UserCredentials,
        [Parameter(Mandatory = $true, ParameterSetName = 'ManagedIdentity')]
        [Alias('Identity', 'ManagedSPN')]
        [switch]
        $ManagedIdentity,
        [Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
        [switch]
        $DeviceCode,
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RedirectUri')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Credentials')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ManagedIdentity')]
        [Parameter(Mandatory = $false, ParameterSetName = 'DeviceCode')]
        [Alias('ClientID', 'AppID', 'App', 'Application')]
        [String]
        $ApplicationID,
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RedirectUri')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Credentials')]
        # [Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ManagedIdentity')]
        [Alias('TenantID')]
        [String]
        $Tenant,
        [Parameter(Mandatory = $false)]
        [Switch]
        # By using -Force it will remove the existing variables in MgaSession in the script scope 
        $Force
    )
    begin {
        if ($Force) {
            Write-Verbose 'Connect-Mga: begin: -Force parameter found | Running Disconnect-Mga to force a log on'
            $null = Disconnect-Mga
        }
        else {
            # Starting Initialize-MgaConnect to see if there is already an existing MgaSession
            Initialize-MgaConnect
        }
        if ($Certificate.length -eq 40) {
            Write-Verbose 'Connect-Mga: begin: Certificate is a string of 40 characters | Updating value to search for certificate on client'
            $Thumbprint = $Certificate
        }
        Write-Verbose 'Connect-Mga: begin: Building MgaSession HashTable in Script scope'
        # Using a HashTable for the MgaSession Variable to Add, Call and Remove properties easily
        $MgaSession = @{
            LoginType           = $null
            headerParameters    = $null
            AppPass             = $null
            ApplicationID       = $null
            Tenant              = $null
            Secret              = $null
            Cert                = $null
            Certificate         = $null
            TPrint              = $null
            ThumbPrint          = $null
            RU                  = $null
            RedirectUri         = $null
            Basic               = $null
            UserCredentials     = $null
            ManagedIdentity     = $null
            ManagedIdentityType = $null
            DeviceCode          = $null
            TPCertificate       = $null
            LoginScope          = $null
            OriginalHeader      = $null
        }
        Write-Verbose 'Connect-Mga: begin: Adding MgaSession HashTable to Script scope'
        $Null = New-Variable -Name MgaSession -Value $MgaSession -Scope Script -Force
    }
    process { 
        try {
            $ReceiveMgaOauthToken = @{} 
            if ($Thumbprint) {
                Write-Verbose 'Connect-Mga: process: Thumbprint: Logging in with Thumbprint'
                $ReceiveMgaOauthToken.Add('ApplicationId', $ApplicationID)
                $ReceiveMgaOauthToken.Add('Tenant', $Tenant)
                $ReceiveMgaOauthToken.Add('Thumbprint', $Thumbprint)
                Receive-MgaOauthToken @ReceiveMgaOauthToken
            }
            elseif ($Certificate) {
                Write-Verbose 'Connect-Mga: process: Certificate: Logging in with certificate'
                $ReceiveMgaOauthToken.Add('ApplicationId', $ApplicationID)
                $ReceiveMgaOauthToken.Add('Tenant', $Tenant)
                $ReceiveMgaOauthToken.Add('Certificate', $Certificate)
                Receive-MgaOauthToken @ReceiveMgaOauthToken 
            }
            elseif ($ClientSecret) {
                Write-Verbose 'Connect-Mga: process: ClientSecret: Logging in with ClientSecret'
                $ReceiveMgaOauthToken.Add('ApplicationId', $ApplicationID)
                $ReceiveMgaOauthToken.Add('Tenant', $Tenant)
                $ReceiveMgaOauthToken.Add('ClientSecret', $ClientSecret)
                Receive-MgaOauthToken @ReceiveMgaOauthToken
            }
            elseif ($RedirectUri) {
                Write-Verbose 'Connect-Mga: process: MFA UserCredentials: Logging in with MFA UserCredentials'
                $ReceiveMgaOauthToken.Add('ApplicationId', $ApplicationID)
                $ReceiveMgaOauthToken.Add('Tenant', $Tenant)
                $ReceiveMgaOauthToken.Add('RedirectUri', $RedirectUri)
                Receive-MgaOauthToken @ReceiveMgaOauthToken
            }
            elseif ($UserCredentials) {
                Write-Verbose 'Connect-Mga: process: Basic UserCredentials: Logging in with Basic UserCredentials'
                $ReceiveMgaOauthToken.Add('ApplicationId', $ApplicationID)
                $ReceiveMgaOauthToken.Add('Tenant', $Tenant)
                $ReceiveMgaOauthToken.Add('UserCredentials', $UserCredentials)
                Receive-MgaOauthToken @ReceiveMgaOauthToken
            }
            elseif ($ManagedIdentity -eq $true) {
                Write-Verbose 'Connect-Mga: process: ManagedIdentity: Logging in with Managed Identity'
                $ReceiveMgaOauthToken.Add('ManagedIdentity', 'TryMe')
                Receive-MgaOauthToken @ReceiveMgaOauthToken
            }
            elseif ($DeviceCode -eq $true) {
                Write-Verbose 'Connect-Mga: process: DeviceCode: Logging in with DeviceCode'
                $ReceiveMgaOauthToken.Add('DeviceCode', $true)
                # $ReceiveMgaOauthToken.Add('Tenant', $Tenant)
                Receive-MgaOauthToken @ReceiveMgaOauthToken
            }
        }
        catch {
            throw $_ 
        }  
    }
    end {
        return "You've successfully created an AccessToken for the Microsoft.Graph.API"
    }
}

function Disconnect-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Use Disconnect-Mga to remove the MgaSession variable from the Script scope.
    
    .DESCRIPTION
    To update the OauthToken I fill the script scope with a number of properties. 
    The properties are emptied by Disconnect-Mga.
    
    .EXAMPLE
    Disconnect-Mga
    #>
    [CmdletBinding()]
    param (
    )
    begin {
    }
    process {
        try {
            Write-Verbose 'Disconnect-Mga: process: Removing MgaSession Variable in Scope script'
            # This cmdlet can not be run outside the script scope (module scope) thats why I created a wrapper function
            $Null = Get-Variable -Name 'Mga*' -Scope Script | Remove-Variable -Force -Scope Script
        }
        catch {
            throw $_.Exception.Message
        }
    }
    end {
        return "You've successfully removed the MgaSession Variable"
    }
}

function Show-MgaAccessToken {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    You can use this cmdlet to show you the decoded Oauth token.
    
    .DESCRIPTION
    Its mainly used for troubleshooting permission errors.
    
    .PARAMETER AccessToken
    You can leave this empty unless you want to decode another Oauth token.

    .PARAMETER Roles
    By using the -Roles switch it will only show you the roles that you have assigned to your App registration.
    
    .EXAMPLE
    Show-MgaAccessToken 

    Show-MgaAccessToken -Roles
    #>
    [CmdletBinding()]
    param (
        [parameter(mandatory = $false, Position = 0)]
        $AccessToken = ($Script:MgaSession.headerParameters).Authorization,
        [parameter(mandatory = $false)]
        [switch]
        $Roles
    )  
    begin {
        try {
            if ($AccessToken -like 'Bearer *') {
                Write-Verbose "Show-MgaAccessToken: begin: Removing 'Bearer ' from token for formatting"
            }
            $AccessToken = ($AccessToken).Replace('Bearer ', '')
            $AccessTokenSplitted = $AccessToken.Split('.')

            Write-Verbose 'Show-MgaAccessToken: begin: Formatting Header'
            $AccessTokenHeader = $AccessTokenSplitted[0].Replace('-', '+').Replace('_', '/')
            While ($AccessTokenHeader.Length % 4) {
                Write-Verbose "Show-MgaAccessToken: begin: Adding '=' character so we can modulus 4 for Base64 encoding"
                $AccessTokenHeader += '='
            }      
            Write-Verbose 'Show-MgaAccessToken: begin: Formatting PayLoad'
            $AccessTokenPayLoad = $AccessTokenSplitted.Split('.')[1].Replace('-', '+').Replace('_', '/')
            While ($AccessTokenPayLoad.Length % 4) {
                Write-Verbose "Show-MgaAccessToken: begin: Adding '=' character so we can modulus 4 for Base64 encoding"
                $AccessTokenPayLoad += '='
            }
        }
        catch {
            throw $_
        }
    }
    process {
        try {
            Write-Verbose 'Show-MgaAccessToken: process: Decoding Header to JSON'
            $AccessTokenHeaderJSON = [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($AccessTokenHeader))
            Write-Verbose 'Show-MgaAccessToken: process: Decoding PayLoad to JSON'
            $AccessTokenPayLoadJSON = [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($AccessTokenPayLoad))
            Write-Verbose 'Show-MgaAccessToken: process: Removing last character from Header'
            $AccessTokenHeaderUpdated = $AccessTokenHeaderJSON -replace '.$'
            Write-Verbose "Show-MgaAccessToken: process: Replacing first character by ',' in PayLoad"
            $AccessTokenPayLoadUpdated = $AccessTokenPayLoadJSON -Replace '^.', ','
            Write-Verbose 'Show-MgaAccessToken: process: Adding PayLoad to Header'
            $AccessTokenJson = $AccessTokenHeaderUpdated + $AccessTokenPayLoadUpdated
            Write-Verbose 'Show-MgaAccessToken: process: Converting from Json to EndResult'
            $AccessTokenEndResult = $AccessTokenJson | ConvertFrom-Json  
        }
        catch {
            throw $_
        }
    }  
    end {
        if ($Roles -eq $true) {
            Write-Verbose 'Show-MgaAccessToken: end: Roles switch found | returning roles only'
            return $AccessTokenEndResult.Roles
        }
        else {
            return $AccessTokenEndResult
        }
    }
}

function Get-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Get-Mga speaks for itself. All you have to provide is the URL.
    
    .DESCRIPTION
    You can grab the URL via the browser developer tools, Fiddler, or from the Microsoft Graph docs. You can use all query parameters in the URL like some in the examples.
    It will automatically use the Next Link when there is one in the returned request.
    
    .PARAMETER URL
    The URL to get data from Microsoft Graph.
    
    .PARAMETER Once
    If you only want to retrieve data once, you can use the -Once parameter.
    For example, I used this in the beta version to get the latest login. Nowadays this property is a property under the user: signInActivity.

    .PARAMETER CustomHeader
    Add CustomHeader 
    
    .EXAMPLE
    Get-Mga -URL 'https://graph.microsoft.com/v1.0/users' -Once

    .EXAMPLE
    Get-Mga -URL 'https://graph.microsoft.com/v1.0/users?$top=999'

    .EXAMPLE
    $URL = 'https://graph.microsoft.com/v1.0/users?$select={0}' -f 'id,userPrincipalName,lastPasswordChangeDateTime,createdDateTime,PasswordPolicies' 
    Get-Mga -URL $URL

    .EXAMPLE
    $URL = 'https://graph.microsoft.com/beta/users?$filter=({0})&$select=displayName,userPrincipalName,createdDateTime,signInActivity' -f "UserType eq 'Guest'"
    Get-Mga URL $URL
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $URL,
        [Parameter(Mandatory = $false)]      
        [switch]
        $Once,
        [Parameter(Mandatory = $false)]
        [object]
        $CustomHeader
    )
    begin {
        Write-Verbose 'Get-Mga: begin: Using Update-MgaOauthToken to check if the AccessToken needs to be refreshed'
        Update-MgaOauthToken
        if ($CustomHeader) {
            Write-Verbose 'Get-Mga: begin: Updating the $script:MgaSessions.HeaderParameters with CustomHeader parameters'
            Enable-MgaCustomHeader -CustomHeader $CustomHeader
        }
    }
    process {
        try {
            Write-Verbose "Get-Mga: Getting results from $URL"
            $Result = Invoke-WebRequest -UseBasicParsing -Headers $Script:MgaSession.HeaderParameters -Uri $URL -Method get
            if ($result.Headers.'Content-Type' -like 'application/octet-stream*') {
                Write-Verbose 'Get-Mga: Result is in Csv format | Converting to Csv and returning end result'
                $EndResult = ConvertFrom-Csv -InputObject $Result
            }
            if ($result.Headers.'Content-Type' -like 'application/json*') {   
                Write-Verbose 'Get-Mga: Result is in JSON format | Converting to JSON'
                $Result = ConvertFrom-Json -InputObject $Result
                if ($Result.'@odata.nextLink') {
                    if (!($Once)) {
                        Write-Verbose 'Get-Mga: There is an @odata.nextLink for more output | Restarting Get-Mga again with the next data link'
                        $EndResult = @()
                        foreach ($Line in ($Result).value) {
                            $EndResult += $Line
                        }
                        While ($Result.'@odata.nextLink') {
                            Write-Verbose 'Get-Mga: There is another @odata.nextLink for more output | Restarting Get-Mga again with the next data link'
                            Update-MgaOauthToken
                            $Result = (Invoke-WebRequest -UseBasicParsing -Headers $Script:MgaSession.HeaderParameters -Uri $Result.'@odata.nextLink' -Method Get).Content | ConvertFrom-Json
                            foreach ($Line in ($Result).value) {
                                $EndResult += $Line
                            }
                            Write-Verbose "Get-Mga: Count is: $($EndResult.count)"
                        }
                    }
                    else {
                        $EndResult = @()
                        foreach ($Line in ($Result).value) {
                            $EndResult += $Line
                        }
                        Write-Verbose 'Get-Mga: Parameter -Once found. Even if there is an @odata.nextLink for more output, we will not extract more data'
                    }
                }
                elseif ($Result.value) {
                    Write-Verbose 'Get-Mga: There is no @odata.nextLink. We will add the data to end result'
                    $EndResult = $Result.value
                }
                else {
                    Write-Verbose 'Get-Mga: There is no @odata.nextLink. We will add the data to end result'
                    $EndResult = $Result
                }
            }
        }
        catch [System.Net.WebException] {
            $WebResponse = $_.Exception.Response
            if ($WebResponse.StatusCode -eq 429) {
                [int]$RetryValue = $WebResponse.Headers['Retry-After']
                Write-Warning "WebException Error message! Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
                Start-Sleep -Seconds $($RetryValue + 1) 
                if ($Result.'@odata.nextLink') {
                    Get-Mga -URL $Result.'@odata.nextLink'
                }
                else {
                    Get-Mga -URL $URL
                }
            }
            else {
                throw $_.Exception.Message
            }
        }
        catch {
            throw $_.Exception.Message
        }
    }
    end {
        if ($CustomHeader) {
            Disable-MgaCustomHeader
        }
        return $EndResult
    }
}

function Get-MgaPreview {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Get-Mga speaks for itself. All you have to provide is the URL.
    
    .DESCRIPTION
    You can grab the URL via the browser developer tools, Fiddler, or from the Microsoft Graph docs. You can use all query parameters in the URL like some in the examples.
    It will automatically use the Next Link when there is one in the returned request.
    
    .PARAMETER URL
    The URL to get data from Microsoft Graph.
    
    .PARAMETER Once
    If you only want to retrieve data once, you can use the -Once parameter.
    For example, I used this in the beta version to get the latest login. Nowadays this property is a property under the user: signInActivity.

    .PARAMETER CustomHeader
    Add CustomHeader 
    
    .EXAMPLE
    Get-Mga -URL 'https://graph.microsoft.com/v1.0/users' -Once

    .EXAMPLE
    Get-Mga -URL 'https://graph.microsoft.com/v1.0/users?$top=999'

    .EXAMPLE
    $URL = 'https://graph.microsoft.com/v1.0/users?$select={0}' -f 'id,userPrincipalName,lastPasswordChangeDateTime,createdDateTime,PasswordPolicies' 
    Get-Mga -URL $URL

    .EXAMPLE
    $URL = 'https://graph.microsoft.com/beta/users?$filter=({0})&$select=displayName,userPrincipalName,createdDateTime,signInActivity' -f "UserType eq 'Guest'"
    Get-Mga URL $URL
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $URL,
        [Parameter(Mandatory = $false)]      
        [switch]
        $Once,
        [Parameter(Mandatory = $false)]
        [object]
        $CustomHeader
    )
    begin {
        Write-Verbose 'Get-MgaPreview: begin: Using Update-MgaOauthToken to check if the AccessToken needs to be refreshed'
        Update-MgaOauthToken
        if ($CustomHeader) {
            Write-Verbose 'Get-MgaPreview: begin: Updating the $script:MgaSessions.HeaderParameters with CustomHeader parameters'
            Enable-MgaCustomHeader -CustomHeader $CustomHeader
        }
    }
    process {
        try {
            Write-Verbose "Get-MgaPreview: Getting results from $URL"
            $Result = Invoke-RestMethod -UseBasicParsing -Headers $Script:MgaSession.HeaderParameters -Uri $URL -Method get
            if ($Result.'@odata.nextLink') {
                if (!($Once)) {
                    Write-Verbose 'Get-MgaPreview: There is an @odata.nextLink for more output | Restarting Get-MgaPreview again with the next data link'
                    $EndResult = @()
                    foreach ($Line in ($Result).value) {
                        $EndResult += $Line
                    }
                    While ($Result.'@odata.nextLink') {
                        Write-Verbose 'Get-MgaPreview: There is another @odata.nextLink for more output | Restarting Get-MgaPreview again with the next data link'
                        Update-MgaOauthToken
                        $Result = Invoke-RestMethod -UseBasicParsing -Headers $Script:MgaSession.HeaderParameters -Uri $Result.'@odata.nextLink' -Method Get
                        foreach ($Line in ($Result).value) {
                            $EndResult += $Line
                        }
                        Write-Verbose "Get-MgaPreview: Count is: $($EndResult.count)"
                    }
                }
                else {
                    $EndResult = @()
                    foreach ($Line in ($Result).value) {
                        $EndResult += $Line
                    }
                    Write-Verbose 'Get-MgaPreview: Parameter -Once found. Even if there is an @odata.nextLink for more output, we will not extract more data'
                }
            }
            elseif ($Result.value) {
                Write-Verbose 'Get-MgaPreview: There is no @odata.nextLink. We will add the data to end result'
                $EndResult = $Result.value
            }
            else {
                Write-Verbose 'Get-MgaPreview: There is no @odata.nextLink. We will add the data to end result'
                $EndResult = $Result
            }
        }
        catch [System.Net.WebException] {
            $WebResponse = $_.Exception.Response
            if ($WebResponse.StatusCode -eq 429) {
                [int]$RetryValue = $WebResponse.Headers['Retry-After']
                Write-Warning "WebException Error message! Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
                Start-Sleep -Seconds $($RetryValue + 1) 
                if ($Result.'@odata.nextLink') {
                    Get-MgaPreview -URL $Result.'@odata.nextLink'
                }
                else {
                    Get-MgaPreview -URL $URL
                }
            }
            else {
                throw $_.Exception.Message
            }
        }
        catch {
            throw $_.Exception.Message
        }
    }
    end {
        if ($CustomHeader) {
            Disable-MgaCustomHeader
        }
        return $EndResult
    }
}

function Post-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Post-Mga can be seen as the 'new' Verb. With this cmdlet you create objects in AzureAD.

    .PARAMETER URL
    URL to 'POST' to.
    
    .PARAMETER InputObject
    -InputObject will accept a PSObject or JSON.
    
    .EXAMPLE
    $InputObject = @{
        accountEnabled    = 'true'
        displayName       = "Test User Post MSGraph"
        mailNickname      = "TestUserPostMSGraph"
        userPrincipalName = "TestUserPostMSGraph@XXXXXXXXX.onmicrosoft.com"
        passwordProfile   = @{
            forceChangePasswordNextSignIn = 'true'
            password                      = 'XXXXXXXXXX'
        }
    }
    Post-Mga -URL 'https://graph.microsoft.com/v1.0/users' -InputObject $InputObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $URL,
        [Parameter(Mandatory = $false)]
        [object]
        $InputObject,
        [Parameter(Mandatory = $false)]
        [object]
        $CustomHeader
    )
    begin {
        Update-MgaOauthToken
        if ($CustomHeader) {
            Enable-MgaCustomHeader -CustomHeader $CustomHeader
        }
        $InputObject = ConvertTo-MgaJson -InputObject $InputObject
    }
    process {
        try {
            if ($InputObject) {
                Write-Verbose 'Post-Mga: Posting InputObject to Microsoft.Graph.API.'
                $Result = Invoke-RestMethod -Uri $URL -Headers $Script:MgaSession.headerParameters -Method post -Body $InputObject -ContentType application/json
            }
            else {
                $Result = Invoke-RestMethod -Uri $URL -Headers $Script:MgaSession.headerParameters -Method post -ContentType application/json    
            }
        }
        catch [System.Net.WebException] {
            Write-Warning 'WebException Error message! This could be due to throttling limit.'
            $WebResponse = $_.Exception.Response
            if ($WebResponse.StatusCode -eq 429) {
                [int]$RetryValue = $WebResponse.Headers['Retry-After']
                Write-Warning "WebException Error message! Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
                Start-Sleep -Seconds $($RetryValue + 1) 
                $Result = Post-Mga -URL $URL -InputObject $InputObject
            }
            else {
                throw $_.Exception.Message
            }
        }
        catch {
            throw $_.Exception.Message
        }
    }
    end {
        if ($CustomHeader) {
            Disable-MgaCustomHeader
        }
        Write-Verbose "Post-Mga: We've successfully Posted the data to Microsoft.Graph.API."
        return $Result
    }
}

function Put-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Put-Mga can be seen as the 'new' Verb. With this cmdlet you create objects in AzureAD.

    .PARAMETER URL
    URL to 'Put' to.
    
    .PARAMETER InputObject
    -InputObject will accept a PSObject or JSON.
    
    .EXAMPLE
    $InputObject = @{
        accountEnabled    = 'true'
        displayName       = "Test User Put MSGraph"
        mailNickname      = "TestUserPutMSGraph"
        userPrincipalName = "TestUserPutMSGraph@XXXXXXXXX.onmicrosoft.com"
        passwordProfile   = @{
            forceChangePasswordNextSignIn = 'true'
            password                      = 'XXXXXXXXXX'
        }
    }
    Put-Mga -URL 'https://graph.microsoft.com/v1.0/users' -InputObject $InputObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $URL,
        [Parameter(Mandatory = $false)]
        [object]
        $InputObject,
        [Parameter(Mandatory = $false)]
        [object]
        $CustomHeader
    )
    begin {
        Update-MgaOauthToken
        if ($Customheader) {
            Enable-MgaCustomHeader -CustomHeader $CustomHeader
        }
        elseif ($URL -notlike '*/uploadSession*') {
            $InputObject = ConvertTo-MgaJson -InputObject $InputObject
        }
    }
    process {
        try {
            if ($InputObject) {
                Write-Verbose 'Put-Mga: Puting InputObject to Microsoft.Graph.API.'
                if ($CustomHeader) {
                    $Result = Invoke-RestMethod -Uri $URL -Headers $Script:MgaSession.headerParameters -Method Put -Body $InputObject
                }
                else {
                    $Result = Invoke-RestMethod -Uri $URL -Headers $Script:MgaSession.headerParameters -Method Put -Body $InputObject -ContentType application/json
                }
            }
            else {
                $Result = Invoke-RestMethod -Uri $URL -Headers $Script:MgaSession.headerParameters -Method Put -ContentType application/json    
            }
        }
        catch [System.Net.WebException] {
            Write-Warning 'WebException Error message! This could be due to throttling limit.'
            $WebResponse = $_.Exception.Response
            if ($WebResponse.StatusCode -eq 429) {
                [int]$RetryValue = $WebResponse.Headers['Retry-After']
                Write-Warning "WebException Error message! Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
                Start-Sleep -Seconds $($RetryValue + 1) 
                $Result = Put-Mga -URL $URL -InputObject $InputObject
            }
            else {
                throw $_.Exception.Message
            }
        }
        catch {
            throw $_.Exception.Message
        }
    }
    end {
        if ($CustomHeader) {
            Disable-MgaCustomHeader
        }
        Write-Verbose "Put-Mga: We've successfully Puted the data to Microsoft.Graph.API."
        return $Result
    }
}

function Patch-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Patch-Mga can be seen as the 'Update' Verb.
    In the below example I add users to a Group.

    .PARAMETER URL
    URL to 'PATCH' to.

    .PARAMETER InputObject
    -InputObject will accept a PSObject or JSON.
    InputObject with members@odata.bind property over 20+ users will automatically be handled for you.

    .PARAMETER Batch
    -Batch is a switch to use Batch in the backend. -Batch only works with 'members@odata.bind' property.

    .EXAMPLE
    $users = Get-Mga 'https://graph.microsoft.com/v1.0/users'
    $UserPostList = [System.Collections.Generic.List[Object]]::new() 
    foreach ($User in $users)
    {
        $DirectoryObject = 'https://graph.microsoft.com/v1.0/directoryObjects/{0}' -f $User.id
        $UserPostList.Add($DirectoryObject)
    }
    $PostBody = [PSCustomObject] @{
        "members@odata.bind" = $UserPostList
    }
    Patch-Mga -URL 'https://graph.microsoft.com/v1.0/groups/4c9d31a2-c662-4f76-b3f8-52290d2aa788' -InputObject $PostBody
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $URL,
        [Parameter(Mandatory = $true)]
        [object]
        $InputObject,
        [Parameter(Mandatory = $false)]
        [switch]
        $Batch,
        [Parameter(Mandatory = $false)]
        [object]
        $CustomHeader
    )
    begin {
        Update-MgaOauthToken
        if ($CustomHeader) {
            Enable-MgaCustomHeader -CustomHeader $CustomHeader
        }
        $ValidateJson = ConvertTo-MgaJson -InputObject $InputObject -Validate
        if ($Batch -eq $true) {
            Write-Warning 'Patch-Mga: begin: Parameter Batch will only work when the InputObject contains property: members@odata.bind. If this is not the case -Batch will be ignored.'
        }
    }
    process {
        try {
            if (($ValidateJson -eq $false) -and (($InputObject.'members@odata.bind').count -gt 20)) {
                if ($Batch -eq $true) {
                    Optimize-Mga -InputObject $InputObject -URL $URL -Request 'Patch-Mga' -Batch
                }
                else {
                    Optimize-Mga -InputObject $InputObject -URL $URL -Request 'Patch-Mga'     
                }
            }
            else {
                $InputObject = ConvertTo-MgaJson -InputObject $InputObject
                Write-Verbose 'Patch-Mga: Patching InputObject to Microsoft.Graph.API.'
                $Result = Invoke-RestMethod -Uri $URL -Headers $Script:MgaSession.headerParameters -Method Patch -Body $InputObject -ContentType application/json
            }
        }
        catch [System.Net.WebException] {
            Write-Warning 'WebException Error message! This could be due to throttling limit.'
            $WebResponse = $_.Exception.Response
            if ($WebResponse.StatusCode -eq 429) {
                [int]$RetryValue = $WebResponse.Headers['Retry-After']
                Write-Warning "WebException Error message! Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
                Start-Sleep -Seconds $($RetryValue + 1) 
                $Result = Patch-Mga -URL $URL -InputObject $InputObject
            }
            else {
                throw $_.Exception.Message
            }
        }
        catch {
            throw $_.Exception.Message
        }
    }
    end {
        if ($CustomHeader) {
            Disable-MgaCustomHeader
        }
        Write-Verbose "Patch-Mga: We've successfully Patched the data to Microsoft.Graph.API."
        return $Result
    }
}

function Delete-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Delete speaks for itself. With this cmdlet you can remove objects from AzureAD.

    .PARAMETER URL
    -URL accepts an array of URLS, it will use Batch-Mga in the backend.
    
    .PARAMETER InputObject
    -InputObject will accept a PSObject or JSON.
    
    .EXAMPLE
    $GroupUsers = Get-Mga -URL 'https://graph.microsoft.com/v1.0/groups/ac252320-4194-402f-8182-2d14e4a2db5c/members'
    $UserList = @()
    foreach ($User in $GroupUsers) {
        $URL = 'https://graph.microsoft.com/v1.0/groups/ac252320-4194-402f-8182-2d14e4a2db5c/members/{0}/$ref' -f $User.Id
        $UserList += $URL
    }
    Delete-Mga -URL $UserList
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $URL,
        [Parameter(Mandatory = $false)]
        [string]
        $InputObject,
        [Parameter(Mandatory = $false)]
        [object]
        $CustomHeader
    )
    begin {
        Update-MgaOauthToken
        if ($CustomHeader) {
            Enable-MgaCustomHeader -CustomHeader $CustomHeader
        }
        if ($InputObject) {
            $ValidateJson = ConvertTo-MgaJson -InputObject $InputObject -Validate
        }
    }
    process {
        try {
            if (($ValidateJson -eq $false) -and (($InputObject.'members@odata.bind').count -gt 20)) {
                Optimize-Mga -InputObject $InputObject -URL $URL -Request 'Delete-Mga'
            }
            elseif ($URL.count -gt 1) {
                Optimize-Mga -URL $URL -Request 'Delete-Mga'
            }
            elseif ($InputObject) {
                Write-Verbose "Delete-Mga: Deleting InputObject on $URL to Microsoft.Graph.API."
                $InputObject = ConvertTo-MgaJson -InputObject $InputObject
                $Result = Invoke-RestMethod -Uri $URL -Body $InputObject -Headers $Script:MgaSession.headerParameters -Method Delete -ContentType application/json
            }
            else {
                Write-Verbose "Delete-Mga: Deleting conent on $URL to Microsoft.Graph.API."
                $Result = Invoke-RestMethod -Uri $URL -Headers $Script:MgaSession.headerParameters -Method Delete -ContentType application/json
            }

        }
        catch [System.Net.WebException] {
            Write-Warning 'WebException Error message! This could be due to throttling limit.'
            $WebResponse = $_.Exception.Response
            if ($WebResponse.StatusCode -eq 429) {
                [int]$RetryValue = $WebResponse.Headers['Retry-After']
                Write-Warning "WebException Error message! Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
                Start-Sleep -Seconds $($RetryValue + 1) 
                if ($InputObject) {
                    $Result = Delete-Mga -URL $URL -InputObject $InputObject
                }
                else {
                    $Result = Delete-Mga -URL $URL
                }
            }
            else {
                throw $_.Exception.Message
            }
        }
        catch {
            throw $_.Exception.Message
        }
    }
    end {
        if ($CustomHeader) {
            Disable-MgaCustomHeader
        }
        Write-Verbose "Delete-Mga: We've successfully deleted the data on Microsoft.Graph.API."
        return $Result
    }
}

function Batch-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Batch-Mga is for speed and bulk.
    See the related link for more.
    
    .DESCRIPTION
    Batch-Mga will take care of the limitations(20 requests per batch) and will sleep for the amount of time a throttle limit is returned and then continue.

    .PARAMETER InputObject
    -InputObject will accept an ArrayList.
    See the examples for more information.
    
    .PARAMETER Headers
    You can manually change the header for the Batch, but this will change all headers.
    
    .PARAMETER Beta
    Switch to batch to beta instead.
    Default is v1.0. 
    
    .EXAMPLE
    $DeletedObjects = Get-Mga -URL 'https://graph.microsoft.com/v1.0/directory/deletedItems/microsoft.graph.user?$top=999'
    $Batch = [System.Collections.Generic.List[Object]]::new()
    foreach ($User in $DeletedObjects) {
        $Object = [PSCustomObject]@{
            url    = "/directory/deletedItems/$($User.id)"
            method = 'delete'
        }
        $Batch.Add($object)
    }
    Batch-Mga -InputObject $batch

    .EXAMPLE
    $BatchDependsOn = [System.Collections.Generic.List[Object]]::new()
    foreach ($User in $Response) {
        $Object = [PSCustomObject]@{
            Url       = "/users/$($User.UserPrincipalName)"
            method    = 'patch'
            body      = [PSCustomObject] @{
                officeLocation = "18/2111"
            }
            dependsOn = 2
        }
        $test.Add($object)
    }
    Batch-Mga -InputObject $BatchDependsOn
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]
        $InputObject,
        [Parameter(Mandatory = $false)]
        [string]
        [Alias('CustomHeader')]
        $Headers,
        [Parameter(Mandatory = $false)]
        [switch]
        $Beta
    )
    begin {
        $i = 1
        $Batch = [System.Collections.Generic.List[System.Object]]::new()
        $ValidateJson = ConvertTo-MgaJson -Validate
        if ($Beta -eq $true) {
            $URI = 'https://graph.microsoft.com/beta/$batch'
        }
        else {
            $URI = 'https://graph.microsoft.com/v1.0/$batch'
        }
    }
    process {
        if (($ValidateJson -eq $false) -and ($InputObject.count -gt 20)) {
            Optimize-Mga -InputObject $InputObject -Request 'Batch-Mga'
        }
        else {
            Write-Verbose 'Batch-Mga: Creating Batch request.'
            foreach ($Line in $InputObject) {
                try {
                    if ($Line.Url -like 'https://graph.microsoft.com/v1.0*') {
                        $URL = ($Line.Url).Replace('https://graph.microsoft.com/v1.0', '')
                    }
                    elseif ($Line.Url -like 'https://graph.microsoft.com/beta*') {
                        $URL = ($Line.Url).Replace('https://graph.microsoft.com/beta', '')
                    }
                    else {
                        $URL = $Line.Url
                    }
                    if ($null -eq $Line.Header) {
                        $Header = [PSCustomObject]@{
                            'Content-Type' = 'application/json'
                        }
                    }
                    else {
                        $Header = $Line.Header
                    }
                    $Hashtable = @{
                        id      = $i
                        Method  = ($Line.Method).ToUpper()
                        url     = $URL
                        Headers = $Header
                    }
                    if ($Line.Body.length -ne 0) {
                        $Hashtable.Add('body', $($Line.Body))
                    }
                    if ($Line.DependsOn.length -ne 0) {
                        if ($Line.DependsOn.count -gt 1) {
                            $Hashtable.Add('dependsOn', $Line.DependsOn )
                        }
                        else {
                            $Hashtable.Add('dependsOn', ($Line.DependsOn).ToString().ToCharArray() )
                        }
                    }
                    $Object = [PSCustomObject]$Hashtable
                    $Batch.Add($Object)
                    if ($i -eq $($InputObject.Count)) {
                        $EndBatch = [PSCustomObject]@{
                            Requests = $Batch
                        }
                    }
                    else {
                        $i++
                    }
                }
                catch {
                    throw $_.Exception.Message
                }
            }
            Write-Verbose 'Batch-Mga: Patching Batch request.'
            $Results = Post-Mga -URL $URI -InputObject $EndBatch
            $EndResult = [System.Collections.Generic.List[System.Object]]::new()
            :EndResults foreach ($result in $results.Responses) {
                try {
                    $Object = [PSCustomObject]@{
                        id     = $Result.id
                        status = $Result.status
                        code   = $Result.body.error.code
                        body   = $Result.body.error.message
                    }
                    $EndResult.Add($Object)
                    if ($Object.body -like '*Your request is throttled temporarily.*') {
                        $ThrottleHit = $true
                        break :EndResults
                    }
                }
                catch {
                    throw $_.Exception.Message
                }
            }
            if ($ThrottleHit -eq $true) {
                $ThrottleHit = $null
                $ThrottleTime = $object.body -replace '[^0-9]' , ''
                Write-Warning 'WebException Error message! This could be due to throttling limit.'
                Write-Warning "WebException Error message! Throttling error. Retry-After value: $($ThrottleTime) seconds. Sleeping for $($ThrottleTime)s."
                Start-Sleep -Seconds ([int]$ThrottleTime + 1)
                $Results = Post-Mga -URL $URI -InputObject $EndBatch
                $EndResult = [System.Collections.Generic.List[System.Object]]::new()
                foreach ($result in $results.Responses) {
                    try {
                        $Object = [PSCustomObject]@{
                            id     = $Result.id
                            status = $Result.status
                            code   = $Result.body.error.code
                            body   = $Result.body.error.message
                        }
                        $EndResult.Add($Object)
                    }
                    catch {
                        continue
                    }
                    
                }
            }
        }
    }
    end {
        Write-Verbose "Delete-Mga: We've successfully batched the data to Microsoft.Graph.API."
        return $EndResult | Sort-Object id
    }
}
#endregion main
#region experimental
function Get-MgaVariable {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Request the script variables that belong to the Optimized.Mga module
    
    .DESCRIPTION
    With this cmdlet you can check if the Mga variables contain the information that it should contain

    .PARAMETER Variable
    Leave Empty to see all variables, otherwise name the variable you'd like to see
    
    .EXAMPLE
    Get-Variable

    Get-Variable -Variable HeaderParameter
    #>
    [CmdletBinding()]
    param (
        [parameter(mandatory = $false)]
        [string]
        $Variable = 'All' 
    )
    begin {
        Write-Verbose "Get-MgaVariable: begin: Variable: $Variable"
    } 
    process {
        if ($Variable -ne 'All') {
            Write-Verbose "Get-MgaVariable: process: Variable contains something else then 'All'"
            $ReturnResult = $Script:MgaSession.$($Variable)
        }
        else {
            $ReturnResult = $Script:MgaSession
        }
    }
    end {
        return $ReturnResult
    }
}

function Update-MgaVariable {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Update Variables in the MgaSession script scope.
    
    .DESCRIPTION
    Update Variables in the MgaSession script scope. 
    This will mostly be for testing purposes.

    Not all variables will be overwritten since some are ReadOnly by default. 
    Keep in mind that by updating these properties the module can stop functioning.
    
    .PARAMETER Variable
    This Parameter is mandatory & is the PropertyName.
    You can add several subproperties by using 'property1.subproperty.subproperty'
    
    .PARAMETER InputObject
    The InputObject will overwrite the original content.
    
    .EXAMPLE
    Update-MgaVariable -Variable 'HeaderParameters.Content-Type' -InputObject (Get-Date).AddHours(-2)
    #>
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $Variable,
        [parameter(mandatory = $true)]
        $InputObject
    )   
    begin {
        Write-Verbose "Update-MgaVariable: begin: Updating Variable: $Variable"
    }
    process {
        $ObjectToTest = '$Script:MgaSession'
        if ($Variable -like '*.*') {
            Write-Verbose 'Update-MgaVariable: process: Variable contains a dot(.) splitting on dot(.)'
            $Variable = $Variable.Split('.')
            Write-Verbose "Update-MgaVariable: process: ArrayCount: $($Variable.Count)"
        } 
        Write-Verbose 'Update-MgaVariable: process: Creating String builder class'
        $SB = [System.Text.StringBuilder]::new()
        foreach ($Prop in $Variable) {
            Write-Verbose "Update-MgaVariable: process: Adding $Prop"
            if ($Prop -like '*-*') {
                Write-Verbose "Update-MgaVariable: process: Property containing - | Adding '' to Property"
                $Prop = "'{0}'" -f $Prop
            }
            Write-Verbose 'Update-MgaVariable: process: Adding a dot(.) after each property'
            [void]$SB.Append($Prop + '.')
        }
        Write-Verbose 'Update-MgaVariable: process: Trimming last dot(.)'
        $commandParameter = $SB.ToString().TrimEnd('.')
        Write-Verbose "Update-MgaVariable: process: CommandParameter: $CommandParameter"
        Write-Verbose 'Update-MgaVariable: process: Building cmdlet to Invoke'
        $Command = [string]::Format('{0}.{1} = "{2}"', $ObjectToTest, $commandParameter, $InputObject)
        Write-Verbose "Update-MgaVariable: process: ScriptBlock: $Command"
        $scriptBlock = [scriptblock]::Create($Command)
        $null = $scriptBlock.Invoke()
    }
    end {
        return "Updated $Variable"
    }
} 
#endregion experimental
#region internal
function Initialize-MgaConnect {
    [CmdletBinding()]
    param (
    )
    if ($Script:MgaSession.LoginType.length -ge 1) {
        Write-Verbose "Initialize-MgaConnect: You're already logged on."
        $Confirmation = Read-Host 'You already logged on. Are you sure you want to proceed? Type (Y)es to continue.'
        if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true') -or ($Confirmation -eq '(Y)es')) {
            Write-Verbose 'Initialize-MgaConnect: We will continue logging in.'
            $null = Disconnect-Mga
        }
        else {
            Write-Verbose 'Initialize-MgaConnect: Aborting log in.'
            throw 'Login aborted'
        }
    }
}

function Update-MgaOauthToken {  
    [CmdletBinding()]
    param (
    )
    if ($null -ne $Script:MgaSession.AppPass) {
        Receive-MgaOauthToken `
            -ApplicationID $Script:MgaSession.ApplicationID `
            -Tenant $Script:MgaSession.Tenant `
            -ClientSecret $Script:MgaSession.Secret
    }
    elseif ($null -ne $Script:MgaSession.Cert) {
        Receive-MgaOauthToken `
            -ApplicationID $Script:MgaSession.ApplicationID `
            -Tenant $Script:MgaSession.Tenant `
            -Certificate $Script:MgaSession.Certificate
    }
    elseif ($null -ne $Script:MgaSession.TPrint) {
        Receive-MgaOauthToken `
            -ApplicationID $Script:MgaSession.ApplicationID `
            -Tenant $Script:MgaSession.Tenant `
            -Thumbprint $Script:MgaSession.Thumbprint 
    }
    elseif ($null -ne $Script:MgaSession.RU) {
        Receive-MgaOauthToken `
            -ApplicationID $Script:MgaSession.ApplicationID `
            -Tenant $Script:MgaSession.Tenant `
            -RedirectUri $Script:MgaSession.RedirectUri 
        # -LoginScope $Script:MgaSession.LoginScope
    }
    elseif ($null -ne $Script:MgaSession.Basic) {
        Receive-MgaOauthToken `
            -ApplicationID $Script:MgaSession.ApplicationID `
            -Tenant $Script:MgaSession.Tenant `
            -UserCredentials $Script:MgaSession.UserCredentials 
    }
    elseif ($null -ne $Script:MgaSession.ManagedIdentity) {
        Receive-MgaOauthToken `
            -ManagedIdentity $Script:MgaSession.ManagedIdentityType
    }
    elseif ($null -ne $Script:MgaSession.DeviceCode) {
        Receive-MgaOauthToken `
            -DeviceCode
    }
    else {
        Throw 'You need to run Connect-Mga before you can continue. Exiting script...'
    }
}

function Receive-MgaOauthToken {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        #[Parameter(Mandatory = $true, ParameterSetName = 'Thumbprint')]
        #[Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        #[Parameter(Mandatory = $true, ParameterSetName = 'RedirectUri')]
        #[Parameter(Mandatory = $true, ParameterSetName = 'Credentials')]
        #[Parameter(Mandatory = $false, ParameterSetName = 'ManagedIdentity')]
        [string]
        $ApplicationID, 
        #[Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        #[Parameter(Mandatory = $true, ParameterSetName = 'Thumbprint')]
        #[Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        #[Parameter(Mandatory = $true, ParameterSetName = 'RedirectUri')]
        #[Parameter(Mandatory = $true, ParameterSetName = 'Credentials')]
        #[Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
        #[Parameter(Mandatory = $false, ParameterSetName = 'ManagedIdentity')]
        [string]
        $Tenant,
        #[Parameter(Mandatory = $true, ParameterSetName = 'Thumbprint')]
        [string]
        $Thumbprint, 

        #[Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
        [switch]
        $DeviceCode,
        #[Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        $Certificate, 
        #[Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        $ClientSecret,
        #[Parameter(Mandatory = $true, ParameterSetName = 'ManagedIdentity')]
        [string]
        $ManagedIdentity,
        #[Parameter(Mandatory = $true, ParameterSetName = 'Redirecturi')]
        [string]
        $RedirectUri, 
        <#[Parameter(Mandatory = $false, ParameterSetName = 'Redirecturi')]
        [AllowEmptyString()]  
        [Object]
        $LoginScope, #>
        #[Parameter(Mandatory = $true, ParameterSetName = 'Credentials')]
        [System.Net.ICredentials]
        $UserCredentials
    )
    begin {
        try { 
            $Script:MgaSession.Tenant = $Tenant
            $Script:MgaSession.ApplicationID = $ApplicationID
            <#if ($null -eq $LoginScope) {#>
            [System.Collections.Generic.List[String]]$LoginScope = @('https://graph.microsoft.com/.default')
            <#
            }
            else {
                $Data = @('https://graph.microsoft.com/')
                foreach ($Scp in $LoginScope) {
                    $Data += $Scp
                }
                [System.Collections.Generic.List[String]]$LoginScope = ([string]$Data).replace('/ ', '/')
            } #>
            [datetime]$UnixDateTime = '1970-01-01 00:00:00'
            $Date = Get-Date
            $UTCDate = [System.TimeZoneInfo]::ConvertTimeToUtc($Date)
            if ($thumbprint.length -gt 5) { 
                Write-Verbose 'Receive-MgaOauthToken: Certificate: We will continue logging in with Certificate.'
                if (($null -eq $Script:MgaSession.TPCertificate) -or ($Thumbprint -ne ($Script:MgaSession.TPCertificate).Thumbprint)) {
                    Write-Verbose 'Receive-MgaOauthToken: Certificate: Starting search in CurrentUser\my.'
                    $TPCertificate = Get-Item Cert:\CurrentUser\My\$Thumbprint -ErrorAction SilentlyContinue
                    if ($null -eq $TPCertificate) {
                        Write-Verbose 'Receive-MgaOauthToken: Certificate not found in CurrentUser. Continuing in LocalMachine\my.'
                        $TPCertificate = Get-Item Cert:\localMachine\My\$Thumbprint -ErrorAction SilentlyContinue
                    }
                    if ($null -eq $TPCertificate) {
                        throw "We did not find a certificate under: $Thumbprint. Exiting script..."
                    }
                }
                else {
                    $TPCertificate = $Script:MgaSession.TPCertificate
                    Write-Verbose 'Receive-MgaOauthToken: Certificate: We already obtained a certificate from a previous login. We will continue logging in.'
                }
            }
        }
        catch {
            throw $_.Exception.Message          
        }
    }
    process {
        try {
            if ($ClientSecret) {
                if ($clientsecret.gettype().name -ne 'securestring') {
                    $Secret = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force
                }
                else {
                    $Secret = $ClientSecret
                }
                $TempPass = [PSCredential]::new('.', $Secret).GetNetworkCredential().Password
                if (!($Script:MgaSession.AppPass)) {
                    Write-Verbose 'Receive-MgaOauthToken: ApplicationSecret: This is the first time logging in with a ClientSecret.'
                    $Builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($ApplicationID).WithTenantId($Tenant).WithClientSecret($TempPass).Build()
                    $Script:MgaSession.AppPass = $Builder.AcquireTokenForClient($LoginScope).ExecuteAsync()
                    if ($null -eq $Script:MgaSession.AppPass.result.AccessToken) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $Script:MgaSession.headerParameters = @{
                            Authorization  = $Script:MgaSession.AppPass.result.CreateAuthorizationHeader()
                            'Content-Type' = 'application/json'
                        }
                        $Script:MgaSession.LoginType = 'ClientSecret'
                        $Script:MgaSession.Secret = $Secret
                    }
                }
                else {
                    Write-Verbose 'Receive-MgaOauthToken: ApplicationSecret: Oauth token already exists from previously running cmdlets.'
                    Write-Verbose 'Receive-MgaOauthToken: ApplicationSecret: Running test to see if Oauth token expired.'
                    $OauthExpiryTime = $Script:MgaSession.AppPass.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose 'Receive-MgaOauthToken: ApplicationSecret: Oauth token expired. Emptying Oauth variable and re-running function.'
                        $Script:MgaSession.AppPass = $null
                        Receive-MgaOauthToken `
                            -ApplicationID $ApplicationID `
                            -Tenant $Tenant `
                            -ClientSecret $ClientSecret           
                    }
                    else {
                        Write-Verbose 'Receive-MgaOauthToken: ApplicationSecret: Oauth token from last run is still active.'
                    }
                }
            }
            elseif ($Certificate) {
                if (!($Script:MgaSession.Cert)) {
                    Write-Verbose 'Receive-MgaOauthToken: Certificate: This is the first time logging in with a Certificate.'
                    $Builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($ApplicationID).WithTenantId($tenant).WithCertificate($Certificate).Build()  
                    $Script:MgaSession.Cert = $Builder.AcquireTokenForClient($LoginScope).ExecuteAsync()
                    if ($null -eq $Script:MgaSession.Cert.result.AccessToken) {
                        throw "We did not retrieve an Oauth access token to continue script. Exiting script... $($Script:MgaSession.Cert.Exception)"
                    }
                    else {
                        $Script:MgaSession.headerParameters = @{
                            Authorization  = $Script:MgaSession.Cert.result.CreateAuthorizationHeader()
                            'Content-Type' = 'application/json'
                        }
                        $Script:MgaSession.LoginType = 'Certificate'
                        $Script:MgaSession.Certificate = $Certificate
                    }
                }
                else {
                    Write-Verbose 'Receive-MgaOauthToken: Certificate: Oauth token already exists from previously running cmdlets.'
                    Write-Verbose 'Receive-MgaOauthToken: Certificate: Running test to see if Oauth token expired.'
                    $OauthExpiryTime = $Script:MgaSession.Cert.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose 'Receive-MgaOauthToken: Certificate: Oauth token expired. Emptying Oauth variable and re-running function.'
                        $Script:MgaSession.Cert = $null
                        Receive-MgaOauthToken `
                            -ApplicationID $ApplicationID `
                            -Certificate $Certificate `
                            -Tenant $Tenant
                    }
                    else {
                        Write-Verbose 'Receive-MgaOauthToken: Certificate: Oauth token from last run is still active.'
                    }
                }
            }
            elseif ($Thumbprint) {
                if (!($Script:MgaSession.TPrint)) {
                    Write-Verbose 'Receive-MgaOauthToken: Certificate: This is the first time logging in with a Certificate.'
                    $Builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($ApplicationID).WithTenantId($tenant).WithCertificate($TPCertificate).Build()  
                    $Script:MgaSession.TPrint = $Builder.AcquireTokenForClient($LoginScope).ExecuteAsync()
                    if ($null -eq $Script:MgaSession.TPrint.result.AccessToken) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $Script:MgaSession.headerParameters = @{
                            Authorization  = $Script:MgaSession.TPrint.result.CreateAuthorizationHeader()
                            'Content-Type' = 'application/json'
                        }
                        $Script:MgaSession.LoginType = 'Thumbprint'
                        $Script:MgaSession.Thumbprint = $Thumbprint
                        $Script:MgaSession.TPCertificate = $TPCertificate
                    }
                }
                else {
                    Write-Verbose 'Receive-MgaOauthToken: Certificate: Oauth token already exists from previously running cmdlets.'
                    Write-Verbose 'Receive-MgaOauthToken: Certificate: Running test to see if Oauth token expired.'
                    $OauthExpiryTime = $Script:MgaSession.TPrint.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose 'Receive-MgaOauthToken: Certificate: Oauth token expired. Emptying Oauth variable and re-running function.'
                        $Script:MgaSession.TPrint = $null
                        Receive-MgaOauthToken `
                            -ApplicationID $ApplicationID `
                            -Thumbprint $Thumbprint `
                            -Tenant $Tenant
                    }
                    else {
                        Write-Verbose 'Receive-MgaOauthToken: Certificate: Oauth token from last run is still active.'
                    }
                }
            }
            elseif ($RedirectUri) { 
                if (!($Script:MgaSession.RU)) {
                    $Builder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ApplicationID).WithTenantId($Tenant).WithRedirectUri($RedirectUri).Build()
                    $Script:MgaSession.RU = $Builder.AcquireTokenInteractive($LoginScope).ExecuteAsync()
                    if ($null -eq $Script:MgaSession.RU.result.AccessToken) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $Script:MgaSession.headerParameters = @{
                            Authorization  = $Script:MgaSession.RU.Result.CreateAuthorizationHeader()
                            'Content-Type' = 'application/json'
                        }
                        $Script:MgaSession.LoginType = 'RedirectUri'
                        $Script:MgaSession.RedirectUri = $RedirectUri
                        $Script:MgaSession.LoginScope = $LoginScope
                    }
                }
                else {
                    Write-Verbose 'Receive-MgaOauthToken: MFA UserCredentials: Oauth token already exists from previously running cmdlets.'
                    Write-Verbose 'Receive-MgaOauthToken: MFA UserCredentials: Running test to see if Oauth token expired.'
                    $OauthExpiryTime = $Script:MgaSession.RU.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose 'Receive-MgaOauthToken: MFA UserCredentials: Oauth token expired. Emptying Oauth variable and re-running function.'
                        $Script:MgaSession.RU = $null
                        Receive-MgaOauthToken `
                            -ApplicationID $ApplicationID `
                            -Tenant $Tenant `
                            -RedirectUri $RedirectUri # `
                        # -LoginScope $LoginScope
                    }
                    else {
                        Write-Verbose 'Receive-MgaOauthToken: MFA UserCredentials: Oauth token from last run is still active.'
                    }
                }
            }
            elseif ($userCredentials) {
                $loginURI = 'https://login.microsoft.com'
                $Resource = 'https://graph.microsoft.com'
                $Body = @{
                    grant_type = 'password';
                    resource   = $Resource;
                    username   = $($userCredentials.UserName)
                    password   = $($UserCredentials.Password)
                    client_id  = $ApplicationID;
                    scope      = 'openid'
                }
                if (!($Script:MgaSession.Basic)) {
                    $Script:MgaSession.Basic = Invoke-RestMethod -Method Post -Uri $loginURI/$Tenant/oauth2/token?api-version=1.0 -Body $Body -UseBasicParsing
                    if ($null -eq $Script:MgaSession.Basic.access_token) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $Script:MgaSession.headerParameters = @{
                            Authorization  = "$($Script:MgaSession.Basic.token_type) $($Script:MgaSession.Basic.access_token)"
                            'Content-Type' = 'application/json'
                        }
                        $Script:MgaSession.LoginType = 'UserCredentials'
                        $Script:MgaSession.UserCredentials = $UserCredentials
                    }
                }
                else {
                    Write-Verbose 'Receive-MgaOauthToken: Basic UserCredentials: Oauth token already exists from previously running cmdlets.'
                    Write-Verbose 'Receive-MgaOauthToken: Basic UserCredentials: Running test to see if Oauth token expired.'
                    $OauthExpiryTime = $UnixDateTime.AddSeconds($Script:MgaSession.Basic.expires_on)
                    if ($null -ne $Script:MgaSession.Basic.refresh_token) {
                        Write-Verbose 'Receive-MgaOauthToken: '
                        $Body = @{
                            refresh_token = $Script:MgaSession.Basic.refresh_token
                            grant_type    = 'refresh_token'
                        }
                        $Script:MgaSession.Basic = Invoke-RestMethod -Method Post -Uri $loginURI/$Tenant/oauth2/token?api-version=1.0 -Body $Body -UseBasicParsing
                        if ($null -eq $Script:MgaSession.Basic.access_token) {
                            Write-Warning 'We did not retrieve an Oauth access token from the refresh_token. Re-trying to log in with new token.'
                            $Script:MgaSession.Basic = $null
                            Receive-MgaOauthToken `
                                -UserCredentials $UserCredentials `
                                -Tenant $Tenant `
                                -ApplicationID $ApplicationID
                        }
                        else {
                            $Script:MgaSession.headerParameters = @{
                                Authorization  = "$($Script:MgaSession.Basic.token_type) $($Script:MgaSession.Basic.access_token)"
                                'Content-Type' = 'application/json'
                            }
                            $Script:MgaSession.LoginType = 'UserCredentials'
                            $Script:MgaSession.UserCredentials = $UserCredentials
                        }
                    }
                    if ($OauthExpiryTime -le $UTCDate) {
                        $Script:MgaSession.Basic = $null
                        Receive-MgaOauthToken `
                            -UserCredentials $UserCredentials `
                            -Tenant $Tenant `
                            -ApplicationID $ApplicationID
                    }
                    else {
                        Write-Verbose 'Receive-MgaOauthToken: Basic UserCredentials: Oauth token from last run is still active.'
                    }
                }
            }
            elseif ($ManagedIdentity) {
                if (!($Script:MgaSession.ManagedIdentity)) {
                    $Resource = 'https://graph.microsoft.com/'
                    $Body = @{
                        resource = $($Resource)
                    }
                    if (($ManagedIdentity -eq 'AzFunction') -or ($ManagedIdentity -eq 'Function') -or ($ManagedIdentity -eq 'AppService') -or ($ManagedIdentity -eq 'AzAutomation') -or ($ManagedIdentity -eq 'Automation') -or ($ManagedIdentity -eq 'AA')) {
                        $tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resource&api-version=2019-08-01"
                        $Script:MgaSession.ManagedIdentity = Invoke-RestMethod -Method Get -Headers @{'X-IDENTITY-HEADER' = "$($env:IDENTITY_HEADER)" } -Uri $tokenAuthURI
                        if ($null -eq $Script:MgaSession.ManagedIdentity.access_token) {
                            throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                        }
                        else {
                            $Script:MgaSession.HeaderParameters = @{
                                Authorization  = "$($Script:MgaSession.ManagedIdentity.token_type) $($Script:MgaSession.ManagedIdentity.access_token)"
                                'Content-Type' = 'application/json'
                            }
                            $Script:MgaSession.LoginType = 'ManagedIdentity'
                            $Script:MgaSession.ManagedIdentityType = $ManagedIdentity
                        }
                    }
                    elseif (($ManagedIdentity -eq 'VirtualMachine') -or ($ManagedIdentity -eq 'VM')) {
                        $Script:MgaSession.ManagedIdentity = Invoke-RestMethod -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$Resource" -Headers @{Metadata = 'true' }
                        if ($null -eq $Script:MgaSession.ManagedIdentity.access_token) {
                            throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                        }
                        else {
                            $Script:MgaSession.HeaderParameters = @{
                                Authorization  = "$($Script:MgaSession.ManagedIdentity.token_type) $($Script:MgaSession.ManagedIdentity.access_token)"
                                'Content-Type' = 'application/json'
                            }
                            $Script:MgaSession.LoginType = 'ManagedIdentity'
                            $Script:MgaSession.ManagedIdentityType = $ManagedIdentity
                        }
                    } 
                    elseif ($ManagedIdentity -eq 'TryMe') {
                        try {
                            Write-Verbose 'Receive-MgaOauthToken: ManagedIdentity: Trying Virtual Machine Managed Identity'
                            Receive-MgaOauthToken -ManagedIdentity 'VM'
                        }
                        catch {
                            Write-Verbose 'Receive-MgaOauthToken: ManagedIdentity: Virtual Machine Managed Identity: FAILED'
                            try {
                                Write-Verbose 'Receive-MgaOauthToken: ManagedIdentity: Trying Azure Automation Managed Identity'
                                Receive-MgaOauthToken -ManagedIdentity 'AA'
                            }
                            catch {
                                Write-Verbose 'Receive-MgaOauthToken: ManagedIdentity: Azure App Service Managed Identity: FAILED'
                                throw 'Cannot find the Managed Identity type... Login is aborted...'
                            }
                        }
                    }
                }
                else {
                    if (($ManagedIdentity -eq 'AzFunction') -or ($ManagedIdentity -eq 'Function') -or ($ManagedIdentity -eq 'AppService') -or ($ManagedIdentity -eq 'AzAutomation') -or ($ManagedIdentity -eq 'Automation') -or ($ManagedIdentity -eq 'AA')) {
                        Write-Verbose 'Receive-MgaOauthToken: ManagedIdentity: Oauth token already exists from previously running cmdlets.'
                        Write-Verbose 'Receive-MgaOauthToken: ManagedIdentity: Running test to see if Oauth token expired.'
                        $OauthExpiryTime = $UnixDateTime.AddSeconds($Script:MgaSession.ManagedIdentity.expires_on)
                        if ($OauthExpiryTime -le $UTCDate) {
                            $Script:MgaSession.ManagedIdentity = $null
                            Receive-MgaOauthToken `
                                -ManagedIdentity $ManagedIdentity
                        }
                        else {
                            Write-Verbose 'Receive-MgaOauthToken: Basic UserCredentials: Oauth token from last run is still active.'
                        }
                    } 
                    elseif (($ManagedIdentity -eq 'VirtualMachine') -or ($ManagedIdentity -eq 'VM')) {
                        Write-Verbose 'Receive-MgaOauthToken: ManagedIdentity: Oauth token already exists from previously running cmdlets.'
                        Write-Verbose 'Receive-MgaOauthToken: ManagedIdentity: Running test to see if Oauth token expired.'
                        $OauthExpiryTime = $UnixDateTime.AddSeconds($Script:MgaSession.ManagedIdentity.expires_on)
                        if ($OauthExpiryTime -le $UTCDate) {
                            $Script:MgaSession.ManagedIdentity = $null
                            Receive-MgaOauthToken `
                                -ManagedIdentity $ManagedIdentity
                        }
                        else {
                            Write-Verbose 'Receive-MgaOauthToken: Basic UserCredentials: Oauth token from last run is still active.'
                        }
                    }
                }
            }
            <# elseif ($DeviceCodeOLD) {
                if (!($Script:MgaSession.DeviceCodeOLD)) {
                    if (!($Script:MgaSession.LoginType -eq 'DeviceCodeOLD')) {
                        Add-Type -Path "$PSScriptRoot\Microsoft.Identity.Client.dll"
                        $Code = @'
using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Identity.Client;



public class CallbackBridge
{

public DeviceCodeResult DeviceCodeResult {get;set;}
public AuthenticationResult AuthenticationResult {get;set;}



public async Task<AuthenticationResult> StartDeviceCodeFlow(System.Collections.Generic.IEnumerable<string> authScopes, Microsoft.Identity.Client.PublicClientApplication application)
{
var tokenResponse = await application.AcquireTokenWithDeviceCode(authScopes,
deviceCodeResult =>
{
this.DeviceCodeResult = deviceCodeResult;
Console.WriteLine(DeviceCodeResult.Message);
return Task.FromResult(0);
}).ExecuteAsync();
return tokenResponse;
}
}



'@
                         
                        Add-Type -TypeDefinition $Code -ReferencedAssemblies "$PSScriptRoot\Microsoft.Identity.Client.dll"
                    } 
                    $LoginScope = '.default'
                    $Data = @('https://graph.microsoft.com/')
                    foreach ($Scp in $LoginScope) {
                        $Data += $Scp
                    }
                    [System.Collections.Generic.List[String]]$LoginScope = ([string]$Data).replace('/ ', '/')
            
                    $clientId = '1b730954-1685-4b74-9bfd-dac224a7b894'
                    $App = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($clientId).Build()
                    $Builder = [CallbackBridge]::new()
                    $Script:MgaSession.DeviceCodeOLD = $Builder.StartDeviceCodeFlow($LoginScope, $App)

                    if ($null -eq $Script:MgaSession.DeviceCodeOLD.result.AccessToken) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $Script:MgaSession.headerParameters = @{
                            Authorization  = $Script:MgaSession.DeviceCodeOLD.Result.CreateAuthorizationHeader()
                            'Content-Type' = 'application/json'
                        }
                        $Script:MgaSession.LoginType = 'DeviceCodeOLD'
                    }
                }
                else {
                    Write-Verbose 'Receive-MgaOauthToken: DeviceCodeOLD: Oauth token already exists from previously running cmdlets.'
                    Write-Verbose 'Receive-MgaOauthToken: DeviceCodeOLD: Running test to see if Oauth token expired.'
                    $OauthExpiryTime = $Script:MgaSession.DeviceCodeOLD.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose 'Receive-MgaOauthToken: DeviceCodeOLD: Oauth token expired. Emptying Oauth variable and re-running function.'
                        $Script:MgaSession.DeviceCodeOLD = $null
                        Receive-MgaOauthToken `
                            -DeviceCode
                    }
                    else {
                        Write-Verbose 'Receive-MgaOauthToken: DeviceCodeOLD: Oauth token from last run is still active.'
                    }
                }
            }
            #>   
            elseif ($DeviceCode) {
                if (!($Script:MgaSession.DeviceCode)) {
                    $clientId = '1b730954-1685-4b74-9bfd-dac224a7b894'
                    $Resource = 'https://graph.microsoft.com/'
                    $DeviceCodeRequestParams = @{
                        Method = 'POST'
                        Uri    = 'https://login.microsoftonline.com/common/oauth2/devicecode'
                        Body   = @{
                            client_id = $ClientId
                            resource  = $Resource
                        }
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
                            if ($LoggedInTryCount -ne 870) {
                                Write-Verbose 'Receive-MgaOauthToken: DeviceCode: User has not authorized the DeviceCode yet'
                                Write-Verbose "Start sleeping for 1 second of the $LoggedInTryCount retries with a maximum of 60"
                                Start-Sleep -Seconds 5
                                $LoggedInTryCount = $LoggedInTryCount + 5
                            }
                            else {
                                Throw 'The user has not verified the DeviceCode within 15 minutes. Login is aborted...'
                            }
                        }
                    } 
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
                    
                    if ($null -eq $Script:MgaSession.DeviceCode.access_token) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $Script:MgaSession.headerParameters = @{
                            Authorization  = "$($Script:MgaSession.DeviceCode.token_type) $($Script:MgaSession.DeviceCode.access_token)"
                            'Content-Type' = 'application/json'
                        }
                        $Script:MgaSession.LoginType = 'DeviceCode'
                    }
                }
                else {
                    Write-Verbose 'Receive-MgaOauthToken: DeviceCode: Oauth token already exists from previously running cmdlets.'
                    Write-Verbose 'Receive-MgaOauthToken: DeviceCode: Running test to see if Oauth token expired.'
                    $OauthExpiryTime = $UnixDateTime.AddSeconds($Script:MgaSession.DeviceCode.expires_on)
                    if ($null -ne $Script:MgaSession.DeviceCode.refresh_token) {
                        Write-Verbose 'Receive-MgaOauthToken: '
                        $Body = @{
                            refresh_token = $Script:MgaSession.DeviceCode.refresh_token
                            grant_type    = 'refresh_token'
                        }
                        $Script:MgaSession.DeviceCode = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$Tenant/oauth2/token?api-version=1.0" -Body $Body -UseBasicParsing
                        if ($null -eq $Script:MgaSession.DeviceCode.access_token) {
                            Write-Warning 'We did not retrieve an Oauth access token from the refresh_token. Re-trying to log in with new token.'
                            $Script:MgaSession.DeviceCode = $null
                            Receive-MgaOauthToken `
                                -DeviceCodePreview 
                        }
                        else {
                            $Script:MgaSession.headerParameters = @{
                                Authorization  = "$($Script:MgaSession.DeviceCode.token_type) $($Script:MgaSession.DeviceCode.access_token)"
                                'Content-Type' = 'application/json'
                            }
                            $Script:MgaSession.LoginType = 'DeviceCode'
                        }
                    }
                    elseif ($OauthExpiryTime -le $UTCDate) {
                        $Script:MgaSession.DeviceCode = $null
                        Receive-MgaOauthToken `
                            -DeviceCodePreview 
                    }
                    else {
                        Write-Verbose 'Receive-MgaOauthToken: DeviceCode: Oauth token from last run is still active.'
                    }
                }
            }         
        }
        catch {
            throw $_.Exception.Message
        }
    }
    end {
    }
}

function ConvertTo-MgaJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        $InputObject,
        [Parameter(Mandatory = $false)]
        [switch]
        $Validate
    )
    begin {
        
    }  
    process {
        try {
            $null = ConvertFrom-Json -InputObject $InputObject -ErrorAction Stop
            $ValidateJson = $true
        }
        catch {
            if ($Validate -ne $true) {
                $InputObject = ConvertTo-Json -InputObject $InputObject -Depth 100
            }
            else {
                $ValidateJson = $false
            }
        }    
    }
    end {
        if ($Validate -ne $true) {
            return $InputObject
        }
        else {
            return $ValidateJson
        }
    }
}

function Optimize-Mga {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        $InputObject,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Batch-Mga', 'Patch-Mga', 'Delete-Mga')]
        $Request,
        [Parameter(Mandatory = $false)]
        $URL,
        [Parameter(Mandatory = $false)]
        [switch]
        $Batch
    )
    begin {
        Write-Verbose 'Optimize-Mga: InputObject is multiple requests. Splitting up request.'
    } 
    process {  
        $GroupedInputObject = [system.Collections.Generic.List[system.Object]]::new()
        if ($Request -eq 'Batch-Mga') {
            foreach ($Line in $InputObject) {
                $GroupedInputObject.Add($Line)
                if ($($GroupedInputObject).count -eq 20) {
                    Write-Verbose "Optimize-Mga: Batching $($GroupedInputObject.count) requests."
                    Batch-Mga -InputObject $GroupedInputObject
                    $GroupedInputObject = [system.Collections.Generic.List[system.Object]]::new()
                }
            }
        }
        if ($Request -eq 'Patch-Mga') {
            foreach ($Line in $InputObject.'members@odata.bind') {
                $GroupedInputObject.Add($Line)
                if ($($GroupedInputObject).count -eq 20) {
                    $GroupedInputObject = [PSCustomObject] @{
                        'members@odata.bind' = $GroupedInputObject
                    }
                    if ($Batch -eq $true) {
                        if ($null -eq $PatchToBatch) {
                            
                            $PatchToBatch = [system.Collections.Generic.List[system.Object]]::new()
                        }
                        $ToBatch = [PSCustomObject]@{
                            Method = 'PATCH'
                            Url    = $URL
                            Body   = $GroupedInputObject
                        }
                        $PatchToBatch.Add($ToBatch)
                    }
                    else {
                        Write-Verbose 'Optimize-Mga: patching request.'
                        Patch-Mga -InputObject $GroupedInputObject -URL $URL
                    }
                    $GroupedInputObject = [system.Collections.Generic.List[system.Object]]::new()
                }
            }
        }
        if (($Batch -eq $true) -and ($Request -eq 'Patch-Mga')) {
            Write-Verbose 'Optimize-Mga: Batching Patch to Batch-Mga.'
            Batch-Mga -InputObject $PatchToBatch
        } 
        if ($Request -eq 'Delete-Mga') {
            if ($InputObject.'members@odata.bind') {
                foreach ($Line in $InputObject.'members@odata.bind') {
                    $GroupedInputObject.Add($Line)
                    if ($($GroupedInputObject).count -eq 20) {
                        $OdataBind = [PSCustomObject] @{
                            'members@odata.bind' = $GroupedInputObject
                        }
                        Write-Verbose 'Optimize-Mga: Delete request.'
                        Delete-Mga -InputObject $OdataBind -URL $URL 
                        $GroupedInputObject = [system.Collections.Generic.List[system.Object]]::new()
                    }
                }
            }
            else {
                foreach ($Line in $URL) {
                    $Object = [PSCustomObject]@{
                        url    = $Line
                        method = 'Delete'
                    }
                    $GroupedInputObject.Add($Object)
                    if ($($GroupedInputObject).count -eq 20) {
                        Write-Verbose "Optimize-Mga: Batching $($GroupedInputObject.count) delete requests."
                        Batch-Mga -InputObject $GroupedInputObject
                        $GroupedInputObject = [system.Collections.Generic.List[system.Object]]::new()
                    }
                }
            }
        }
        if ($($GroupedInputObject.count) -ge 1) {
            if ($Request -eq 'Batch-Mga') {
                Write-Verbose 'Optimize-Mga: Batching last Batch-Mga.'
                Batch-Mga -InputObject $GroupedInputObject
            }
            if ($Request -eq 'Patch-Mga') {
                Write-Verbose 'Optimize-Mga: Batching last Patch-Mga.'
                if ($GroupedInputObject.count -gt 1) {
                    $GroupedInputObject = [PSCustomObject] @{
                        'members@odata.bind' = $GroupedInputObject
                    }
                }
                else {
                    $GroupedInputObject = [PSCustomObject] @{
                        '@odata.id' = $GroupedInputObject
                    }
                }
                Patch-Mga -InputObject $GroupedInputObject -URL $URL

            }
            if ($Request -eq 'Delete-Mga') {
                Write-Verbose 'Optimize-Mga: Batching last Delete-Mga.'
                if ($InputObject.'members@odata.bind') {   
                    Delete-Mga -InputObject $OdataBind -URL $URL 
                }
                else {
                    Batch-Mga -InputObject $GroupedInputObject
                }
            }
        }
    }
    end {
        return $Results
    }
}

function Enable-MgaCustomHeader {
    [CmdletBinding()]
    param (
        $CustomHeader
    )
    
    begin {
        Write-Verbose 'Enable-MgaCustomHeader: begin: saving original header.'
        $Script:MgaSession.OriginalHeader = @{}
        foreach ($Header in $Script:MgaSession.HeaderParameters.GetEnumerator()) {
            $Script:MgaSession.OriginalHeader.Add($Header.Key, $Header.Value)
        }
    }
    process {
        Write-Verbose 'Enable-MgaCustomHeader: begin: Merging headers.'
        # $Script:MgaSession.HeaderParameters = $Script:MgaSession.OriginalHeader + $CustomHeader
        foreach ($Header in $CustomHeader.GetEnumerator()) {
            try {
                if ($null -ne $Script:MgaSession.HeaderParameters[$Header.Key]) {
                    $Script:MgaSession.HeaderParameters[$Header.Key] = $Header.Value
                }
                else {
                    $Script:MgaSession.HeaderParameters.Add($Header.key, $Header.Value)
                }
            }
            catch {
                throw $_.Exception.Message
            }
        }   
    } 
    end {
        Write-Verbose 'Enable-MgaCustomHeader: end: CustomHeader created.'
    }
}

function Disable-MgaCustomHeader {
    [CmdletBinding()]
    param (
    )
    begin {
        Write-Verbose 'Disable-MgaCustomHeader: begin: Changing back to original header.'
    }
    process {
        try {
            if ($Script:MgaSession.HeaderParameters -ne $Script:MgaSession.OriginalHeader) {
                Write-Verbose 'Disable-MgaCustomHeader: process: Reverting header.'
                Write-Output 1
                $Script:MgaSession.HeaderParameters = @{}
                Write-Output 2
                $Script:MgaSession.HeaderParameters += $Script:MgaSession.OriginalHeader
                Write-Output 3
                Remove-Variable -Name 'MgaOriginalHeader' -Scope Global
                Write-Output 4
            }
            else {
                Write-Verbose 'Disable-MgaCustomHeader: process: Header is already original header.'
            }
        }
        catch {
            throw 'Something went wrong with reverting back to original header. Re-login with Connect-Mga to continue.'
        }
    } 
    end {
        Write-Verbose 'Disable-MgaCustomHeader: end: Header changed back to original header.'
    }
}
#endregion internal