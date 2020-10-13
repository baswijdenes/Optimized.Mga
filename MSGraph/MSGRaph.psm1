function Connect-MSGraphCertificate
{
    [CmdletBinding(HelpURI = 'https://bwit.blog')]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("ID", "AppID", "ClientID", "App")]
        [string]
        $ApplicationID,
        [Parameter(Mandatory = $true)]
        [string]
        $Thumbprint, 
        [Parameter(Mandatory = $true)]
        [Alias("TenantName", "Tenant")]
        [string]
        $TenantID
    )
    begin
    {
        $global:ApplicationID = $ApplicationID
        $global:Thumbprint = $Thumbprint
        $global:TenantID = $TenantID
        $Global:Login = 'MSGraphCertificate'
        $global:ErrorList = [system.Collections.Generic.List[system.Object]]::new()
    }
    process
    {
        try
        {
            Get-MSGRAPHOauthToken `
                -AppID $global:ApplicationID `
                -Thumbprint $global:Thumbprint `
                -Tenant $global:TenantID
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
        return $EndResult
    }
}

function Connect-MSGraphAppSecret
{
    [CmdletBinding(HelpURI = 'https://bwit.blog')]
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
        [Alias("TenantName", "Tenant")]
        [string]
        $TenantID
    )
    begin
    {
        $global:ApplicationID = $ApplicationID
        $global:ApplicationSecret = $ApplicationSecret
        $global:TenantID = $TenantID
        $global:Login = 'MSGraphAppSecret'
        $global:ErrorList = [system.Collections.Generic.List[system.Object]]::new()
    }
    process
    {
        try
        {
            Get-MSGRAPHOauthToken `
                -AppID $global:ApplicationID `
                -AppPass $global:ApplicationSecret `
                -Tenant $global:TenantID
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "Connect-MSGraphAppSecret: Error in begin of function."
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
        return $EndResult
    }
}

function Get-MSGraphReport
{
    [CmdletBinding(HelpURI = 'https://bwit.blog')]
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
                    -AppPass $global:ApplicationSecret `
                    -Tenant $global:TenantID
            }
            elseif ($global:Login -eq 'MSGraphCertificate')
            {
                Get-MSGRAPHOauthToken `
                    -AppID $global:ApplicationID `
                    -Thumbprint $global:Thumbprint `
                    -Tenant $global:TenantID
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
                Information  = "Get-MSGRaphReport: Error in begin of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'Get-MSGRaphReport: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break
        }
    }
    process
    {
        try
        {
            Write-Verbose "Get-MSGRaphReport: Getting results from $URL."
            $Result = Invoke-WebRequest -UseBasicParsing -Headers $global:HeaderParameters -Uri $URL -Method get
            if ($result.Headers.'Content-Type' -like "application/octet-stream*")
            {
                Write-Verbose "Get-MSGRaphReport: Result is in CSV format. Converting to CSV."
                Write-Verbose "Get-MSGRaphReport: We will add the data to endresult."
                $EndResult = ConvertFrom-Csv -InputObject $Result
            }
            if ($result.Headers.'Content-Type' -like "application/json*")
            {   
                Write-Verbose "Get-MSGRaphReport: Result is in JSON format. Converting to JSON."
                $JSON = ConvertFrom-Json -InputObject $Result
                if ($JSON.'@odata.nextLink')
                {
                    Write-Verbose "Get-MSGRaphReport: Data output is more than 100 results. We will run script again with next data link."
                    $EndResult = @()
                    foreach ($Line in ($JSON).value)
                    {
                        $EndResult += $Line
                    }
                    While ($JSON.'@odata.nextLink')
                    {
                        Write-Verbose "Get-MSGRaphReport: Data output is still more than 100 results. We will run script again with next data link."
                        $JSON = (Invoke-WebRequest -UseBasicParsing -Headers $HeaderParameters -Uri $JSON.'@odata.nextLink' -Method Get).Content | ConvertFrom-Json
                        foreach ($Line in ($JSON).value)
                        {
                            $EndResult += $Line
                        }
                        Write-Verbose "Get-MSGRaphReport: Count is: $($EndResult.count)"
                    }
                }
                elseif ($JSON.value)
                {
                    Write-Verbose "Get-MSGRaphReport: Data output is less than 100 results. We will add the data to end result."
                    $EndResult = $JSON.value
                }
                else
                {
                    Write-Verbose "Get-MSGRaphReport: Data output is less than 100 results. We will add the data to end result."
                    $EndResult = $JSON
                }
            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "Get-MSGRaphReport: Error in process of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'Get-MSGRaphReport: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message       
            break
        }
    }
    end
    {
        Write-Verbose "Get-MSGRaphReport: We've succesfully retrieved the end result. The end result will be returned."
        return $EndResult
    }
}

function Get-MSGraphOauthToken
{
    [CmdletBinding(HelpURI = 'https://bwit.blog')]
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
            if ($AppPass)
            {
                Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: We will continue logging in with ApplicationSecret."
                $global:Body = @{
                    grant_type    = "client_credentials";
                    resource      = $Resource;
                    client_id     = $AppID;
                    client_secret = $AppPass
                }
            }
            elseif ($Thumbprint)
            { 
                Write-Verbose "Get-MSGRAPHOauthToken: Thumbprint: We will continue logging in with Certificate."
                $Cert = Search-MSGRAPHCertByThumbprint -Thumbprint $Thumbprint
                $AssertionCert = [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate]::new($AppID, $Cert)
                $AuthContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new("https://login.microsoftonline.com/$Tenant")
            }
            else
            {
                Throw "There is no Password nor Thumbprint. Exiting script..."
                break
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
                if (!($global:AppPass))
                {
                    Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Body has formed to retrieve Oauth access token from $Resource."
                    $global:AppPass = Invoke-RestMethod -Method Post -Uri $loginURL/$TenantID/oauth2/token?api-version=1.0 -Body $Body 
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
                        Get-MSGRAPHOauthToken -URL $URL `
                            -AppID $ApplicationID `
                            -AppPass $ApplicationSecret `
                            -Tenant $TenantID
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
                            -Tenant $TenantID
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
            Write-Verbose "Get-MSGRAPHOauthToken: ClientSecret: We have succesfully retrieved the Oauth access token. We will continue the script."
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

function Search-MSGraphCertByThumbprint
{
    param (
        [parameter(mandatory = $true)]
        [string]
        $Thumbprint
    )
    begin
    {
        try
        {
            if ($Thumbprint.length -eq '40')
            {
                Write-Verbose "Search-MSGRAPHCertByThumbprint: Thumbprint length is correct. We will continue searching for the cerrtificate in CurrentUser\My and LocalMachine\My."
                $Certificate = $null
            }
            else
            {
                throw 'The thumbprint length is incorrect. Make sure you paste the thumbprint correctly. Exiting script...'
                break
            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "Search-MSGRAPHCertByThumbprint: Error in begin of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'Search-MSGRAPHCertByThumbprint: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break
        }
    }
    process
    {
        try
        {
            Write-Verbose "Search-MSGRAPHCertByThumbprint: Starting search in CurrentUser\my."
            $Certificate = Get-Item Cert:\CurrentUser\My\$Thumbprint -ErrorAction SilentlyContinue
            if ($null -eq $Certificate)
            {
                Write-Verbose "Search-MSGRAPHCertByThumbprint: Certificate not found in CurrentUser. Continuing in LocalMachine\my."
                $Certificate = Get-Item Cert:\localMachine\My\$Thumbprint -ErrorAction SilentlyContinue
            }
            if ($null -eq $Certificate)
            {
                throw "We did not find a thumbprint under: $Thumbprint. Exiting script..."
                break
            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "Search-MSGRAPHCertByThumbprint: Error in process of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorList.Add($Object) 
            Write-Warning 'Search-MSGRAPHCertByThumbprint: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break
        }
    }
    end
    {
        Write-Verbose "Search-MSGRAPHCertByThumbprint: Certificate has been found. Returning Certificate."
        Return $Certificate
    }
}

