function Connect-MSGraphCertificate
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("ID", "AppID", "ClientID", "App")]
        [string]
        $ApplicationID,
        [Parameter(Mandatory = $true)]
        [string]
        $Thumbprint, 
        [Parameter(Mandatory = $true)]
        [Alias("TenantName", "TenantID")]
        [string]
        $Tenant,
        [switch]
        $force
    )
    begin
    {
        $global:ErrorList = [system.Collections.Generic.List[system.Object]]::new()
        try
        {
            If ($global:login -eq 'MSGraphAppSecret')
            {
                Write-Verbose "Connect-MSGraphCertificate: You're already logged on with ClientID and ClientScret. Keep in mind that Certificate is more safe."
                if ($force)
                {
                    Write-Verbose "Connect-MSGraphCertificate: -Force parameter found. We will continue logging in with ClientSecret (less safe)"
                    $global:login = $null
                    $global:AppPass = $null
                }
                else
                {
                    $Confirmation = Read-Host 'You already logged on with ClientID and ClientSecret. Are you sure you want to proceed with Certificate? Type yes to continue.'
                    if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true'))
                    {
                        Write-Verbose "We will continue logging in with Certificate"
                        $global:login = $null
                        $global:AppPass = $null
                    }
                    else
                    {
                        Write-Verbose "Connect-MSGraphCertificate: Aborting logging in with ClientSecret"
                        throw "Connect-MSGraphCertificate aborted"
                    }
                }
            }
            $global:ApplicationID = $ApplicationID
            $global:Thumbprint = $Thumbprint
            $global:Tenant = $Tenant
            $Global:Login = 'MSGraphCertificate'
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "Connect-MSGraphCertificate: Error in process of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            break
        }
    }
    process
    {
        try
        {
            Get-MSGRAPHOauthToken `
                -AppID $global:ApplicationID `
                -Thumbprint $global:Thumbprint `
                -Tenant $global:Tenant
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "Connect-MSGraphCertificate: Error in process of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'Connect-MSGraphCertificate: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break
        }
    }
    end
    {
        Write-Verbose "Connect-MSGraphCertificate: We've succesfully logged in."
        return 'you succesfully logged in with a Certificate. We will keep you logged in until you close your Session.'
    }
}

function Connect-MSGraphAppSecret
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("ID", "AppID", "ClientID", "App")]
        [string]
        $ApplicationID,
        [Parameter(Mandatory = $true)]
        [Alias("Password", "PW", "AppSecret", "Pass")]
        [string]
        $ApplicationSecret, 
        [Parameter(Mandatory = $true)]
        [Alias("TenantName", "TenantID")]
        [string]
        $Tenant,
        [switch]
        $force
    )
    begin
    {
        $global:ErrorList = [system.Collections.Generic.List[system.Object]]::new()
        try 
        {
            If ($global:login -eq 'MSGraphCertificate')
            {
                Write-Verbose "Connect-MSGraphAppSecret: You're already logged on with ClientID and Certificate. Keep in mind that Certificate is more safe."
                if ($force)
                {
                    Write-Verbose "Connect-MSGraphCertificate: -Force parameter found. We will continue logging in with ClientSecret (less safe)."
                    $global:login = $null
                    $global:AppPass = $null
                }
                else
                {
                    $Confirmation = Read-Host 'You already logged on with a Certificate. Are you sure you want to proceed with ClientSecret (less safe)? Type (Y)es to continue.'
                    if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true') -or ($Confirmation -eq '(Y)es'))
                    {
                        Write-Verbose "We will continue logging in with ClientSecret (less safe)."
                        $global:login = $null
                        $global:AppPass = $null
                    }
                    else
                    {
                        Write-Verbose "Connect-MSGraphAppSecret: Aborting logging in with ClientSecret"
                        throw "Connect-MSGraphAppSecret aborted"
                    }
                }
            }
            $global:ApplicationID = $ApplicationID
            $global:ClientSecret = (ConvertTo-SecureString $ApplicationSecret -AsPlainText -Force)
            $ApplicationSecret = $null
            $global:Tenant = $Tenant
            $global:Login = 'MSGraphAppSecret'
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "Connect-MSGraphAppSecret: Error in begin of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            break
        }
    }
    process
    {
        try
        {   
            Get-MSGRAPHOauthToken `
                -AppID $global:ApplicationID `
                -AppPass $global:ClientSecret `
                -Tenant $global:Tenant
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "Connect-MSGraphAppSecret: Error in process of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'Connect-MSGraphAppSecret: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break
        }
    }
    end
    {
        Write-Verbose "Connect-MSGraphAppSecret: We've succesfully logged in."
        return 'You succesfully logged in with an App Secret. We will keep you logged in until you close your Session.'
    }
}

function Disconnect-MSGraph
{    
    [CmdletBinding()]
    param (
        [switch]
        $force
    )
    begin
    {
        if ($global:AppPass)
        {
            Write-Verbose 'Disconnect-MSGraph: You logged in with a Client Secret.'
        }

        elseif ($global:CertLogin)
        {
            Write-Verbose 'Disconnect-MSGraph: You logged in with a Certificate.'
        }
        else
        {
            Write-Verbose 'Disconnect-MSGraph: No login found. We will throw an error.'
            Throw 'There is no session to disconnect. You are not logged in to Microsoft Graph (yet). Use Connect-MSGraphCertificate or Connect-MSGraphAppSecret to log on.'
        }

    }
    process
    {
        if (!($force))
        {
            $Confirmation = Read-Host 'You already logged on with a Certificate. Are you sure you want to proceed with ClientSecret (less safe)? Type (Y)es to continue.'
            if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true') -or ($Confirmation -eq '(Y)es'))
            {
                Write-Verbose 'Disconnect-MSGraph: We will start removing the login including all $global:scope strings.'
                $global:AppPass = $null
                $global:headerParameters = $null
                $global:Certificate = $null
                $global:CertLogin = $null
                $global:ErrorList = $null
                $global:AppPass = $null
                $global:ApplicationID = $null
                $global:ClientSecret = $null
                $global:Tenant = $null
                $global:Thumbprint = $null
                $global:JSON = $null
            }
            else
            {
                Write-Verbose "Disconnect-MSGraph: Confirmation not equals Yes. canceling logout."
                throw "Disconnect-MSGraph canceled."
            }
        }
        else
        {
            Write-Verbose 'Disconnect-MSGraph: -Force parameter found. We will start removing the login including all $global:scope strings.'
            $global:AppPass = $null
            $global:headerParameters = $null
            $global:Certificate = $null
            $global:CertLogin = $null
            $global:ErrorList = $null
            $global:AppPass = $null
            $global:ApplicationID = $null
            $global:ClientSecret = $null
            $global:Tenant = $null
            $global:Thumbprint = $null
            $global:JSON = $null
        }
    }
    end
    {
        return "You're logged out from Microsoft Graph."
        Write-Verbose 'Disconnect-MSGraph: Login has been removed.'
    }
}

function Get-MSGRAPHOauthToken
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $AppID,
        [Parameter(Mandatory = $false)]
        [string]
        $AppPass, 
        [Parameter(Mandatory = $false)]
        [string]
        $Thumbprint, 
        [Parameter(Mandatory = $true)]
        [string]
        $Tenant
    )
    begin
    {
        try
        {  
            $loginURL = "https://login.microsoft.com"
            $Resource = "https://graph.microsoft.com"
            Write-Verbose "Get-MSGRAPHOauthToken: Login URL is: $LoginUrl."
            Write-Verbose "Get-MSGRAPHOauthToken: Resource is: $Resource." 
            if (($null -eq $global:AppPass) -and ($null -eq $global:CertLogin))
            {
                if ($AppPass)
                {
                    Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: We will continue logging in with ApplicationSecret."
                }
                elseif ($Thumbprint)
                { 
                    Write-Verbose "Get-MSGRAPHOauthToken: Thumbprint: We will continue logging in with Certificate."
                    if ($null -eq $global:Certificate)
                    {
                        if ($Thumbprint.length -eq '40')
                        {
                            Write-Verbose "Get-MSGRAPHOauthToken: Thumbprint length is correct. We will continue searching for the cerrtificate in CurrentUser\My and LocalMachine\My."
                            $Certificate = $null
                        }
                        else
                        {
                            throw 'The thumbprint length is incorrect. Make sure you paste the thumbprint correctly. Exiting script...'
                            break
                        }
                        Write-Verbose "Get-MSGRAPHOauthToken: Starting search in CurrentUser\my."
                        $global:Certificate = Get-Item Cert:\CurrentUser\My\$Thumbprint -ErrorAction SilentlyContinue
                        if ($null -eq $global:Certificate)
                        {
                            Write-Verbose "Get-MSGRAPHOauthToken: Certificate not found in CurrentUser. Continuing in LocalMachine\my."
                            $global:Certificate = Get-Item Cert:\localMachine\My\$Thumbprint -ErrorAction SilentlyContinue
                        }
                        if ($null -eq $global:Certificate)
                        {
                            throw "We did not find a thumbprint under: $Thumbprint. Exiting script..."
                            break
                        }    
                    }
                    else
                    {
                        Write-Verbose "Get-MSGRAPHOauthToken: We already obtained a certificate from a previous login. We will continue logging in."
                    }
                    $AssertionCert = [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate]::new($AppID, $global:Certificate)
                    $AuthContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new("https://login.microsoftonline.com/$Tenant")
                }
                else
                {
                    Throw "There is no Password nor Thumbprint. Exiting script..."
                    break
                }
            } 
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "Get-MSGRAPHOauthToken: Error in begin of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'Get-MSGRAPHOauthToken: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break
        }
    }
    process
    {
        try
        {
            [datetime]$UnixDateTime = '1970-01-01 00:00:00'
            $Date = Get-Date
            $UTCDate = [System.TimeZoneInfo]::ConvertTimeToUtc($Date)
            if ($AppPass)
            {
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($global:ClientSecret)
                $TempPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: We will continue logging in with ApplicationSecret."
                $Body = @{
                    grant_type    = "client_credentials";
                    resource      = $Resource;
                    client_id     = $AppID;
                    client_secret = $TempPass 
                }

                if (!($global:AppPass))
                {
                    $Body = @{
                        grant_type    = "client_credentials";
                        resource      = $Resource;
                        client_id     = $AppID;
                        client_secret = $TempPass 
                    }
                    Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Body has formed to retrieve Oauth access token from $Resource."
                    $global:AppPass = Invoke-RestMethod -Method Post -Uri $loginURL/$Tenant/oauth2/token?api-version=1.0 -Body $Body 
                    if ($null -eq $global:AppPass.access_token)
                    {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                        break
                    }
                    else
                    {
                        $global:headerParameters = @{
                            Authorization = "$($global:AppPass.token_type) $($global:AppPass.access_token)"
                        }
                    }
                }
                else
                {
                    Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $UnixDateTime.AddSeconds($global:AppPass.expires_on)
                    if ($OauthExpiryTime -le $UTCDate)
                    {
                        Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Oauth token expired. Emptying Oauth variable and re-running function."
                        $global:AppPass = $null
                        Get-MSGRAPHOauthToken `
                            -AppID $ApplicationID `
                            -AppPass $ApplicationSecret `
                            -Tenant $Tenant
                    }
                    else 
                    {
                        Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Oauth token from last run is still active."
                    }
                }
            }
            else
            {
                [datetime]$UnixDateTime = '1970-01-01 00:00:00'
                $Date = Get-Date
                $UTCDate = [System.TimeZoneInfo]::ConvertTimeToUtc($Date)
                if (!($global:CertLogin))
                {
                    Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Using certificate to log on $Resource."
                    $global:CertLogin = $AuthContext.AcquireTokenAsync('https://graph.microsoft.com', $AssertionCert)
                    if ($null -eq $global:CertLogin.result.AccessToken)
                    {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                        break
                    }
                    else
                    {
                        $global:headerParameters = @{
                            Authorization = "$($global:CertLogin.result.AccessTokenType) $($global:CertLogin.result.AccessToken)"
                        }
                    }
                }
                else
                {
                    Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $global:CertLogin.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate)
                    {
                        Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Oauth token expired. Emptying Oauth variable and re-running function."
                        $global:CertLogin = $null
                        Get-MSGRAPHOauthToken `
                            -AppID $ApplicationID `
                            -Thumbprint $Thumbprint `
                            -Tenant Tenant
                    }
                    else 
                    {
                        Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Oauth token from last run is still active."
                    }
                }
            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "Get-MSGRAPHOauthToken: Error in process of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'Get-MSGRAPHOauthToken: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break
        }
    }
    end
    {
        if ($global:AppPass)
        {
            Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: We have succesfully retrieved the Oauth access token. We will continue the script."
            $BSTR = $null
        } 
        elseif ($global:CertLogin)
        {
            Write-Verbose "Get-MSGRAPHOauthToken: Certificate: We have succesfully retrieved the Oauth access token. We will continue the script."
        }
        else 
        {
            Write-Verbose "There is no active Oauth token available or it expired. We will empty Oauth token variable and re-run the script."
        }
    }
}

function New-MSGraphGetRequest
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("URI")]
        [string]
        $URL
    )
    begin
    {
        try
        {
            $global:ErrorList = [system.Collections.Generic.List[system.Object]]::new()
            if ($global:Login -eq 'MSGraphAppSecret')
            {
                Get-MSGRAPHOauthToken `
                    -AppID $global:ApplicationID `
                    -AppPass $global:ClientSecret `
                    -Tenant $global:Tenant
            }
            elseif ($global:Login -eq 'MSGraphCertificate')
            {
                Get-MSGRAPHOauthToken `
                    -AppID $global:ApplicationID `
                    -Thumbprint $global:Thumbprint `
                    -Tenant $global:Tenant
            }
            else
            {
                Throw "You need to run one of these cmdlets: Connect-MSGraphAppSecret or Connect-MSGraphCertificate before you can continue. Exiting script..."
                break
            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "New-MSGraphGETRequest: Error in begin of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'New-MSGraphGETRequest: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break
        }
    }
    process
    {
        try
        {
            Write-Verbose "New-MSGraphGETRequest: Getting results from $URL."
            $Result = Invoke-WebRequest -UseBasicParsing -Headers $global:HeaderParameters -Uri $URL -Method get
            if ($result.Headers.'Content-Type' -like "application/octet-stream*")
            {
                Write-Verbose "New-MSGraphGETRequest: Result is in CSV format. Converting to CSV."
                Write-Verbose "New-MSGraphGETRequest: We will add the data to endresult."
                $EndResult = ConvertFrom-Csv -InputObject $Result
            }
            if ($result.Headers.'Content-Type' -like "application/json*")
            {   
                Write-Verbose "New-MSGraphGETRequest: Result is in JSON format. Converting to JSON."
                $JSON = ConvertFrom-Json -InputObject $Result
                if ($JSON.'@odata.nextLink')
                {
                    Write-Verbose "New-MSGraphGETRequest: Data output is more than 100 results. We will run script again with next data link."
                    $EndResult = @()
                    foreach ($Line in ($JSON).value)
                    {
                        $EndResult += $Line
                    }
                    While ($JSON.'@odata.nextLink')
                    {
                        [datetime]$UnixDateTime = '1970-01-01 00:00:00'
                        $Date = Get-Date
                        $UTCDate = [System.TimeZoneInfo]::ConvertTimeToUtc($Date)
                        if ($global:AppPass)
                        {
                            Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Oauth token already exists from previously running cmdlets."
                            Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Running test to see if Oauth token expired."
                            $OauthExpiryTime = $UnixDateTime.AddSeconds($global:AppPass.expires_on)
                            if ($OauthExpiryTime -le $UTCDate)
                            {
                                Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Oauth token expired. Emptying Oauth variable and re-running function."
                                $global:AppPass = $null
                                Get-MSGRAPHOauthToken -URL $URL `
                                    -AppID $ApplicationID `
                                    -AppPass $ApplicationSecret `
                                    -Tenant Tenant
                            }
                            else 
                            {
                                Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Oauth token from last run is still active."
                            }
                        }
                        else
                        {
                            Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Oauth token already exists from previously running cmdlets."
                            Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Running test to see if Oauth token expired."
                            $OauthExpiryTime = $global:CertLogin.Result.ExpiresOn.UtcDateTime
                            if ($OauthExpiryTime -le $UTCDate)
                            {
                                Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Oauth token expired. Emptying Oauth variable and re-running function."
                                $global:CertLogin = $null
                                Get-MSGRAPHOauthToken `
                                    -AppID $ApplicationID `
                                    -Thumbprint $Thumbprint `
                                    -Tenant Tenant
                            }
                            else 
                            {
                                Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Oauth token from last run is still active."
                            }
                        }
                        Write-Verbose "New-MSGraphGETRequest: Data output is still more than 100 results. We will run script again with next data link."
                        $JSON = (Invoke-WebRequest -UseBasicParsing -Headers $HeaderParameters -Uri $JSON.'@odata.nextLink' -Method Get).Content | ConvertFrom-Json
                        foreach ($Line in ($JSON).value)
                        {
                            $EndResult += $Line
                        }
                        Write-Verbose "New-MSGraphGETRequest: Count is: $($EndResult.count)."
                    }
                }
                elseif ($JSON.value)
                {
                    Write-Verbose "New-MSGraphGETRequest: Data output is less than 100 results. We will add the data to end result."
                    $EndResult = $JSON.value
                }
                else
                {
                    Write-Verbose "New-MSGraphGETRequest: Data output is less than 100 results. We will add the data to end result."
                    $EndResult = $JSON
                }
            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "New-MSGraphGETRequest: Error in process of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'New-MSGraphGETRequest: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message       
            break
        }
    }
    end
    {
        Write-Verbose "New-MSGraphGETRequest: We've succesfully retrieved the end result. The end result will be returned."
        return $EndResult
    }
}

function New-MSGraphPreGetRequest
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("ListUsers", "ListGroups", "ListApplications", "ListDirectoryAudits", "ListSignIns")]
        [string]
        $Query,
        [Parameter(Mandatory = $false)]
        [switch]
        $Beta
    )
    begin
    {
        if ($Beta)
        {
            Write-Verbose "New-MSGraphPreGetRequest: BETA: We will get the report $Query from BETA."
        }
        Else
        {
            Write-Verbose "New-MSGraphPreGetRequest: v1.0: We will get the report $Query from v1.0. If you want to use the Beta version, use the -Beta parameter."
        }
    }
    Process
    {
        try
        {
            switch ($Query)
            {
                "ListUsers"
                {
                    if ($Beta)
                    {
                        Write-Verbose "New-MSGraphPreGetRequest: BETA: https://graph.microsoft.com/beta/users"
                        New-MSGraphGetRequest -URL 'https://graph.microsoft.com/beta/users'
                    }
                    Else
                    {
                        Write-Verbose "New-MSGraphPreGetRequest: v1.0: https://graph.microsoft.com/v1.0/users"
                        New-MSGraphGetRequest -URL 'https://graph.microsoft.com/v1.0/users'
                    }
                }
                "ListGroups"
                {
                    if ($Beta)
                    {
                        Write-Verbose "New-MSGraphPreGetRequest: BETA: https://graph.microsoft.com/beta/groups"
                        New-MSGraphGetRequest -URL 'https://graph.microsoft.com/beta/groups'
                    }
                    Else
                    {
                        Write-Verbose "New-MSGraphPreGetRequest: v1.0: https://graph.microsoft.com/v1.0/groups"
                        New-MSGraphGetRequest -URL 'https://graph.microsoft.com/v1.0/groups'
                    }
                }
                "ListApplications"
                {
                    if ($Beta)
                    {
                        Write-Verbose "New-MSGraphPreGetRequest: BETA: https://graph.microsoft.com/beta/applications"
                        New-MSGraphGetRequest -URL 'https://graph.microsoft.com/beta/applications'
                    }
                    Else
                    {
                        Write-Verbose "New-MSGraphPreGetRequest: v1.0: https://graph.microsoft.com/v1.0/applications"
                        New-MSGraphGetRequest -URL 'https://graph.microsoft.com/v1.0/applications'
                    }
                }
                "ListDirectoryAudits"
                {
                    if ($Beta)
                    {
                        Write-Verbose "New-MSGraphPreGetRequest: BETA: https://graph.microsoft.com/beta/auditLogs/directoryAudits"
                        New-MSGraphGetRequest -URL 'https://graph.microsoft.com/beta/auditLogs/directoryAudits'
                    }
                    Else
                    {
                        Write-Verbose "New-MSGraphPreGetRequest: v1.0: https://graph.microsoft.com/v1.0/auditLogs/directoryAudits"
                        New-MSGraphGetRequest -URL 'hhttps://graph.microsoft.com/v1.0/auditLogs/directoryAudits'
                    }
                } 
                "ListSignIns"
                {
                    if ($Beta)
                    {
                        Write-Verbose "New-MSGraphPreGetRequest: BETA: https://graph.microsoft.com/beta/auditLogs/signIns"
                        New-MSGraphGetRequest -URL 'https://graph.microsoft.com/beta/auditLogs/signIns'
                    }
                    Else
                    {
                        Write-Verbose "New-MSGraphPreGetRequest: v1.0: https://graph.microsoft.com/v1.0/auditLogs/signIns"
                        New-MSGraphGetRequest -URL 'https://graph.microsoft.com/v1.0/auditLogs/signIns'
                    }
                }

            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "New-MSGraphPreGetRequest: Error in process of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'New-MSGraphPreGetRequest: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message       
            break
        }
    }
    end
    {
        Write-Verbose "New-MSGraphPreGetRequest: Your report will be returned by New-MSGraphPreGetRequest"
    }   
}

function New-MSGraphPostRequest
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("URI")]
        [string]
        $URL,
        [Parameter(Mandatory = $true)]
        [Alias('Data', 'Post')]
        [object]
        $JSON
    )
    begin
    {
        try
        {
            $global:ErrorList = [system.Collections.Generic.List[system.Object]]::new()
            if ($global:Login -eq 'MSGraphAppSecret')
            {
                Get-MSGRAPHOauthToken `
                    -AppID $global:ApplicationID `
                    -AppPass $global:ClientSecret `
                    -Tenant $global:Tenant
            }
            elseif ($global:Login -eq 'MSGraphCertificate')
            {
                Get-MSGRAPHOauthToken `
                    -AppID $global:ApplicationID `
                    -Thumbprint $global:Thumbprint `
                    -Tenant $global:Tenant
            }
            else
            {
                Throw "You need to run one of these cmdlets: Connect-MSGraphAppSecret or Connect-MSGraphCertificate before you can continue. Exiting script..."
                break
            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "New-MSGraphPOSTRequest: Error in begin of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'New-MSGraphPOSTRequest: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break
        }
    }
    process
    {
        try
        {
            try
            {
                $null = ConvertFrom-Json $JSON -ErrorAction Stop;
                $validJson = $true;
            }
            catch
            {
                $validJson = $false;
            }       
            if ($validJson)
            {
                Write-Verbose "New-MSGraphPATCHRequest: Output is already in JSON format"
            }
            else
            {
                Write-Verbose "New-MSGraphPATCHRequest: Converting data to JSON format."
                $global:JSON = ConvertTo-Json -InputObject $JSON
            }
            Write-Verbose "New-MSGraphPOSTRequest: Posting JSON data to Microsoft Graph"
            $EndResult = Invoke-RestMethod -Uri $URL -Headers $global:headerParameters -Method post -Body $global:JSON -ContentType application/json
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "New-MSGraphPOSTRequest: Error in process of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'New-MSGraphPOSTRequest: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break 
        }
    }
    end
    {
        Write-Verbose "New-MSGraphPOSTRequest: We've succesfully Posted the data to Microsoft Graph. The end result will be returned."
        return $EndResult
    }
}

function New-MSGraphPatchRequest
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("URI")]
        [string]
        $URL,
        [Parameter(Mandatory = $true)]
        [Alias('Data', 'Post')]
        [object]
        $JSON
    )
    begin
    {
        try
        {
            $global:ErrorList = [system.Collections.Generic.List[system.Object]]::new()
            if ($global:Login -eq 'MSGraphAppSecret')
            {
                Get-MSGRAPHOauthToken `
                    -AppID $global:ApplicationID `
                    -AppPass $global:ClientSecret `
                    -Tenant $global:Tenant
            }
            elseif ($global:Login -eq 'MSGraphCertificate')
            {
                Get-MSGRAPHOauthToken `
                    -AppID $global:ApplicationID `
                    -Thumbprint $global:Thumbprint `
                    -Tenant $global:Tenant
            }
            else
            {
                Throw "You need to run one of these cmdlets: Connect-MSGraphAppSecret or Connect-MSGraphCertificate before you can continue. Exiting script..."
                break
            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "New-MSGraphPATCHRequest: Error in begin of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'New-MSGraphPATCHRequest: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break
        }
    }
    process
    {
        try
        {
            try
            {
                $null = ConvertFrom-Json $JSON -ErrorAction Stop;
                $validJson = $true;
            }
            catch
            {
                $validJson = $false;
            }       
            if ($validJson)
            {
                Write-Verbose "New-MSGraphPATCHRequest: Output is already in JSON format"
            }
            else
            {
                Write-Verbose "New-MSGraphPATCHRequest: Converting data to JSON format."
                $global:JSON = ConvertTo-Json -InputObject $JSON
            }
            Write-Verbose "New-MSGraphPATCHRequest: Posting JSON data to Microsoft Graph."
            $EndResult = Invoke-RestMethod -Uri $URL -Headers $global:headerParameters -Method Patch -Body $global:JSON -ContentType application/json
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "New-MSGraphPATCHRequest: Error in process of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'New-MSGraphPATCHRequest: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break 
        }
    }
    end
    {
        Write-Verbose "New-MSGraphPATCHRequest: We've succesfully Posted the data to Microsoft Graph. The end result will be returned."
        return $EndResult
    }
}

function New-MSGraphDeleteRequest
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("URI")]
        [string]
        $URL <#,
        [Parameter(Mandatory = $false)]
        [Alias('Value', 'UserPrincipalName')]
        [object]
        $ID #>
    )
    begin
    {
        try
        {
            $global:ErrorList = [system.Collections.Generic.List[system.Object]]::new()
            if ($global:Login -eq 'MSGraphAppSecret')
            {
                Get-MSGRAPHOauthToken `
                    -AppID $global:ApplicationID `
                    -AppPass $global:ClientSecret `
                    -Tenant $global:Tenant
            }
            elseif ($global:Login -eq 'MSGraphCertificate')
            {
                Get-MSGRAPHOauthToken `
                    -AppID $global:ApplicationID `
                    -Thumbprint $global:Thumbprint `
                    -Tenant $global:Tenant
            }
            else
            {
                Throw "You need to run one of these cmdlets: Connect-MSGraphAppSecret or Connect-MSGraphCertificate before you can continue. Exiting script..."
                break
            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "New-MSGraphDELETERequest: Error in begin of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'New-MSGraphDELETERequest: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break
        }
    }
    process
    {
        try
        {
            if ($ID)
            {
        
            }
            else
            {
                $EndResult = Invoke-RestMethod -Uri $URL -Headers $global:headerParameters -Method Delete -ContentType application/json
            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "New-MSGraphDELETERequest: Error in process of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'New-MSGraphDELETERequest: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break 
        }
    }
    end
    {
        Write-Verbose "New-MSGraphDELETERequest: We've succesfully deleted (SOMETHING). The end result (NO RESULT) will be returned."
        return $EndResult
    }
}