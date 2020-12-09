<# START USER FUNCTIONS #>
function Connect-MSGraphAPI
{
    <#
    .SYNOPSIS
    Connect-MSGraph is used to connect to Microsoft.Graph.API.
    
    .DESCRIPTION
    You need to use either Thumbprint, ApplicationSecret, RedirectUri or UserCredentials to choose your login. 
    Certificate Login = Certificate, AppID and Tenant.
    Application = ApplicationSecret, AppID and Tenant.
    UserCredentials (MFA) = RedirectUri, AppID and Tenant.
    UserCredentials (Basic) = UserCredentials, AppID and Tenant.
    
    .PARAMETER Thumbprint
    This is the Certificate thumbprint used to logon with a certificate. 
    The certificate also needs to be uploaded to your AzureAD Application. 
    
    .PARAMETER ApplicationSecret
    This is the ClientSecret used to log on with AppID and ClientSecret. 
    
    .PARAMETER RedirectUri
    We need a RedirectUri (MSAL) to logon Microsoft.Graph.API with MFA.
    
    .PARAMETER UserCredentials
    To log on with UserCredentials and basic authentication you can use Get-Credential for Parameter UserCredentials.
    
    .PARAMETER ApplicationID
    This is your AzureAD ApplicationID.
    
    .PARAMETER Tenant
    This is your tenantID or Tenant name (baswijdenes.onmicrosoft.com)
    
    .PARAMETER Force
    The parameter -Force will force log you on and remove other previously logged on methods. It will only remove active sessions. 
    
    .EXAMPLE
    ApplicationSecret:
    Connect-MSGraph -applicationsecret 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' -applicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' -tenantid '47fada39-12f3-4310-8618-97cd05a2f8ef' -verbose
    Connect-MSGraph -applicationsecret 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' -applicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' -tenantid 'baswijdenes.onmicrosoft.com' -verbose -force

    Certificate:
    Connect-MSGraph -thumbprint 'F6533F114ED7D8BCAEFD9D1219188CEFA90386A5' -applicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' -tenantid 'baswijdenes.onmicrosoft.com' -verbose
    Connect-MSGraph -thumbprint 'F6533F114ED7D8BCAEFD9D1219188CEFA90386A5' -applicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' -tenantid '47fada39-12f3-4310-8618-97cd05a2f8ef' -verbose -force

    MFA Credentials:
    Connect-MSGraph -redirectUri 'msalXXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX://auth'  -Tenant 'baswijdenes.onmicrosoft.com' -AppID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' -verbose
    Connect-MSGraph -RedirectUri 'msalXXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX://auth'  -Tenant '47fada39-12f3-4310-8618-97cd05a2f8ef' -AppID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' -verbose -force

    Basic Credentials:
    if (!($Cred)) {
        $cred = Get-Credential
    }
    Connect-MSGraph -UserCredentials $Cred -Tenant '47fada39-12f3-4310-8618-97cd05a2f8ef' -AppID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' -verbose
    Connect-MSGraph -UserCredentials $cred -Tenant 'baswijdenes.onmicrosoft.com' -AppID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' -verbose -force

    .NOTES 
    Please contact me @ github when you find a bug.
    https://github.com/baswijdenes/Microsoft.Graph.API
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [string]
        $Thumbprint, 
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [Alias("Password", "PW", "AppSecret", "Pass")]
        [string]
        $ApplicationSecret, 
        [Parameter(Mandatory = $true, ParameterSetName = 'RedirectUri')]
        [Alias("RegAppUri", "RegAppURL", "RedirectURL")]
        [String]
        $RedirectUri,
        [Parameter(Mandatory = $true, ParameterSetName = 'Credentials')]
        [System.Net.ICredentials]
        $UserCredentials,
        [Parameter(Mandatory = $true)]
        [Alias("ID", "AppID", "ClientID", "App")]
        [string]
        $ApplicationID,
        [Parameter(Mandatory = $true)]
        [Alias("TenantName", "TenantID")]
        [string]
        $Tenant,
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )
    $global:Tenant = $Tenant
    $global:ApplicationID = $ApplicationID

    if ($thumbprint)
    {
        if ($force)
        {
            Connect-MSGraphCertificate -Thumbprint $Thumbprint `
                -ApplicationID $ApplicationID `
                -TenantID $Tenant `
                -Force
        }
        else
        {
            Connect-MSGraphCertificate -Thumbprint $Thumbprint `
                -ApplicationID $ApplicationID `
                -TenantID $Tenant `
        
        }
    }
    elseif ($ApplicationSecret)
    { 
        if ($force)
        {
            Connect-MSGraphAppSecret -ApplicationSecret $ApplicationSecret `
                -TenantID $Tenant `
                -ApplicationID $ApplicationID `
                -Force
        }
        else
        {
            Connect-MSGraphAppSecret -ApplicationSecret $ApplicationSecret `
                -TenantID $Tenant `
                -ApplicationID $ApplicationID
        }
    }
    elseif ($RedirectUri)
    {
        if ($force)
        {
            Connect-MSGraphDelegate -RedirectUri $RedirectUri `
                -ApplicationID $ApplicationID `
                -Tenant $Tenant `
                -Force
        }
        else
        {
            Connect-MSGraphDelegate -RedirectUri $RedirectUri `
                -ApplicationID $ApplicationID `
                -Tenant $Tenant
        }
    }
    elseif ($UserCredentials)
    {
        if ($force)
        {
            Connect-MSGraphDelegate -UserCredentials $UserCredentials `
                -ApplicationID $ApplicationID `
                -Tenant $Tenant `
                -Force
        }
        else
        {
            Connect-MSGraphDelegate -UserCredentials $UserCredentials `
                -ApplicationID $ApplicationID `
                -Tenant $Tenant
        }
    }
}

function Disconnect-MSGraphAPI
{    
    <#
    .SYNOPSIS
    Will disconnect live sessions.
    
    .DESCRIPTION
    Disconnect-MSGraph speaks for itself. It will remove all live sesions from Microsoft.Graph.API. 
    It will remove all Scopes regarding MSGraph.
    
    .PARAMETER force
    Will -Force disconnect live sessions.
    
    .EXAMPLE
    Disconnect-MSGraph -Verbose
    Disconnect-MSGraph -Verbose -Force
    
     .NOTES 
    Please contact me @ github when you find a bug.
    https://github.com/baswijdenes/Microsoft.Graph.API
    #>
    [CmdletBinding()]
    param (
        [switch]
        $Force
    )
    begin
    {
        if ($global:AppPass)
        {
            Write-Verbose 'Disconnect-MSGraph: You are logged in with a ClientSecret.'
        }

        elseif ($global:CertLogin)
        {
            Write-Verbose 'Disconnect-MSGraph: You are logged in with a Certificate.'
        }
        elseif ($global:Delegate)
        {
            Write-Verbose 'Disconnect-MSGraph: You are logged in with UserCredentials.'
        }
        else
        {
            Write-Verbose 'Disconnect-MSGraph: No login found. We will throw an error.'
            Throw 'There is no session to disconnect. You are not logged on to Microsoft Graph (yet). Use Connect-MSGraph to log on.'
        }

    }
    process
    {
        if (!($force))
        {
            $Confirmation = Read-Host 'Are you sure you want to disconnect from Microsoft Graph API? Type (Y)es to continue.'
            if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true') -or ($Confirmation -eq '(Y)es'))
            {
                Write-Verbose 'Disconnect-MSGraph: We will start removing the login.'
                $global:AppPass = $null
                $global:headerParameters = $null
                $global:Certificate = $null
                $global:CertLogin = $null
                $global:AppPass = $null
                $global:ApplicationID = $null
                $global:ClientSecret = $null
                $global:Tenant = $null
                $global:Thumbprint = $null
                $global:JSON = $null
                $global:Delegate = $null
                $global:login = $null
                $global:RedirectUri = $null
                $global:UserCredentials = $null
            }
            else
            {
                Write-Verbose "Disconnect-MSGraph: Confirmation not equals (Y)es. Canceling logout."
                throw "Disconnect-MSGraph canceled."
            }
        }
        else
        {
            Write-Verbose 'Disconnect-MSGraph: -Force parameter found. We will start removing the login.'
            $global:AppPass = $null
            $global:headerParameters = $null
            $global:Certificate = $null
            $global:CertLogin = $null
            $global:AppPass = $null
            $global:ApplicationID = $null
            $global:ClientSecret = $null
            $global:Tenant = $null
            $global:Thumbprint = $null
            $global:JSON = $null
            $global:Delegate = $null
            $global:login = $null
            $global:RedirectUri = $null
            $global:UserCredentials = $null
        }
    }
    end
    {   
        Write-Verbose 'Disconnect-MSGraph: Login has been removed.'
        return "You are logged out from Microsoft.Graph.API."
    }
}

function New-MSGraphGetRequest
{
    <#
    .SYNOPSIS
    New-MSGraphGetRequest can be used for all GET requests. 
    
    .DESCRIPTION
    New-MSGraphGetRequest can be used for all your GET Requests (not only reports). With this cmdlet you will only have to provide the URL. It will return your data formatted. 
    
    .PARAMETER URL
    -URL Parameter is the URL for your Get Request. You can add filtering, sorting, etc. in your URL. 
    
    .PARAMETER Once
    With the -Once parameter it will only get the request once, even if there is an next datalink. 
    
    .EXAMPLE
    New-MSGraphGETRequest -URL 'https://graph.microsoft.com/v1.0/users' -Verbose
    New-MSGraphGETRequest -URL 'https://graph.microsoft.com/v1.0/users' -Once -Verbose
    
    .NOTES 
    Please contact me @ github when you find a bug.
    https://github.com/baswijdenes/Microsoft.Graph.API
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("URI")]
        [string]
        $URL,
        [Parameter(Mandatory = $false)]      
        [switch]
        $Once
    )
    begin
    {
        try
        {
            Format-MSGRAPHRequests
        }
        catch
        {
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
                $Result = ConvertFrom-Json -InputObject $Result
                if ($Result.'@odata.nextLink')
                {
                    if (!($Once))
                    {
                        Write-Verbose "New-MSGraphGETRequest: There is an @odata.nextLink for more output. We will run script again with next data link."
                        $EndResult = @()
                        foreach ($Line in ($Result).value)
                        {
                            $EndResult += $Line
                        }
                        While ($Result.'@odata.nextLink')
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
                                        -AppID $global:ApplicationID `
                                        -AppPass $global:ClientSecret `
                                        -Tenant $global:Tenant
                                }
                                else 
                                {
                                    Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Oauth token from last run is still active."
                                }
                            }
                            elseif ($global:CertLogin)
                            {
                                Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Oauth token already exists from previously running cmdlets."
                                Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Running test to see if Oauth token expired."
                                $OauthExpiryTime = $global:CertLogin.Result.ExpiresOn.UtcDateTime
                                if ($OauthExpiryTime -le $UTCDate)
                                {
                                    Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Oauth token expired. Emptying Oauth variable and re-running function."
                                    $global:CertLogin = $null
                                    Get-MSGRAPHOauthToken `
                                        -AppID $global:ApplicationID `
                                        -Thumbprint $global:Thumbprint `
                                        -Tenant $global:Tenant
                                }
                                else 
                                {
                                    Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Oauth token from last run is still active."
                                }
                            }
                            elseif ($global:Delegate)
                            {
                                Write-Verbose "Get-MSGRAPHOauthToken: Delegate: Oauth token already exists from previously running cmdlets."
                                Write-Verbose "Get-MSGRAPHOauthToken: Delegate: Running test to see if Oauth token expired."
                                $OauthExpiryTime = $UnixDateTime.AddSeconds($global:Delegate.expires_on)
                                if ($OauthExpiryTime -le $UTCDate)
                                {
                                    Write-Verbose "Get-MSGRAPHOauthToken: Delegate: Oauth token expired. Emptying Oauth variable and re-running function."
                                    $global:Delegate = $null

                                    if ($global:RedirectUri)
                                    {
                                        Connect-MSGraphDelegate -RedirectUri $global:RedirectUri `
                                            -ApplicationID $global:ApplicationID `
                                            -Tenant $global:Tenant 
                                    }
                                    elseif ($global:UserCredentials)
                                    {
                                        Connect-MSGraphDelegate -UserCredentials $global:UserCredentials `
                                            -ApplicationID $global:ApplicationID `
                                            -Tenant $global:Tenant
                                    }
                                }
                                else 
                                {
                                    Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Oauth token from last run is still active."
                                }
                            }
                            Write-Verbose "New-MSGraphGETRequest: Data output is still more than 100 results. We will run script again with next data link."
                            $Result = (Invoke-WebRequest -UseBasicParsing -Headers $HeaderParameters -Uri $Result.'@odata.nextLink' -Method Get).Content | ConvertFrom-Json
                            foreach ($Line in ($Result).value)
                            {
                                $EndResult += $Line
                            }
                            Write-Verbose "New-MSGraphGETRequest: Count is: $($EndResult.count)."
                        }
                    }
                    else
                    {
                        $EndResult = @()
                        foreach ($Line in ($Result).value)
                        {
                            $EndResult += $Line
                        }
                        Write-Verbose 'New-MSGraphGETRequest: Parameter -Once found. Even if there is an @odata.nextLink for more output, we will not extract more data.'
                    }
                }
                elseif ($Result.value)
                {
                    Write-Verbose "New-MSGraphGETRequest: There is no @odata.nextLink. We will add the data to end result."
                    $EndResult = $Result.value
                }
                else
                {
                    Write-Verbose "New-MSGraphGETRequest: There is no @odata.nextLink. We will add the data to end result."
                    $EndResult = $Result
                }
            }
        }
        catch [System.Net.WebException] 
        {
            Write-Verbose "New-MSGRaphRequest: We hit a catch block. This could be due to throttling limit."
            $WebResponse = $_.Exception.Response
            if ($WebResponse.StatusCode -eq 429)
            {
                [int]$RetryValue = $WebResponse.Headers['Retry-After']
                Write-Verbose "New-MSGRaphRequest: Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
                Start-Sleep -Seconds $($RetryValue + 1) 
                if ($Result.'@odata.nextLink')
                {
                    New-MSGraphGetRequest -URL $Result.'@odata.nextLink'
                }
                
                else
                {
                    New-MSGraphGetRequest -URL $URL
                }
            }
            else
            {
                Write-Verbose "New-MSGRaphRequest: We did not hit the throttling limit."
                throw $_.Exception.Message      
            }
        }
    }
    end
    {
        Write-Verbose "New-MSGraphGETRequest: We've successfully retrieved the end result. The end result will be returned."
        return $EndResult
    }
}

function New-MSGraphPreGetRequest
{
    <#
    .SYNOPSIS
    New-MSGraphPreGetRequest has preformatted GET requests like GET Users etc..
    
    .DESCRIPTION
    New-MSGraphPreGetRequest has the following ValidateSet:
    [ValidateSet("ListUsers", "ListGroups", "ListApplications", "ListDirectoryAudits", "ListSignIns")] 

    You can use this cmdlet when you want to get one of these GET Requests.
    
    .PARAMETER Query
    Query is the predefined URL you want to get data from.
    
    .PARAMETER Beta
    I've added a switch parameter -Beta. 
    There are 2 different MSGraph types. -Beta uses Beta URLS. These usually contain more properties, but are subject to change and better not used in production. 
    Or (like I do) keep an eye on the Beta changes. 
    
    .PARAMETER Once
    With the -Once parameter it will only get the request once, even if there is an next datalink. 
    
    .EXAMPLE
    New-MSGraphPreGetRequest -Beta -Query ListUsers 
    New-MSGraphPreGetRequest -Beta -Query ListSignIns -Verbose 

    New-MSGraphPreGetRequest -Query ListApplications
    New-MSGraphPreGetRequest -Query ListGroups -Verbose

    .NOTES 
    Do you need more preformatted get requests? Please contact me @ github.

    Please contact me @ github when you find a bug.
    https://github.com/baswijdenes/Microsoft.Graph.API
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("ListUsers", "ListGroups", "ListApplications", "ListDirectoryAudits", "ListSignIns")]
        [string]
        $Query,
        [Parameter(Mandatory = $false)]
        [switch]
        $Beta,
        [Parameter(Mandatory = $false)]
        [switch]
        $Once
    )
    begin
    {
        if ($Beta)
        {
            $script:beta
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
                    Format-MSGRAPHPreGetRequest -URL 'https://graph.microsoft.com/v1.0/users' -BETAURL 'https://graph.microsoft.com/beta/users'
                }
                "ListGroups"
                {
                    Format-MSGRAPHPreGetRequest -URL 'https://graph.microsoft.com/v1.0/groups' -BETAURL 'https://graph.microsoft.com/beta/groups'
                }
                "ListApplications"
                {
                    Format-MSGRAPHPreGetRequest -URL 'https://graph.microsoft.com/v1.0/applications' -BETAURL 'https://graph.microsoft.com/beta/applications'
                }
                "ListDirectoryAudits"
                {
                    Format-MSGRAPHPreGetRequest -URL 'https://graph.microsoft.com/v1.0/auditLogs/directoryAudits' -BETAURL 'https://graph.microsoft.com/beta/auditLogs/directoryAudits'
                } 
                "ListSignIns"
                {
                    Format-MSGRAPHPreGetRequest -URL 'https://graph.microsoft.com/v1.0/auditLogs/signIns' -BETAURL 'https://graph.microsoft.com/beta/auditLogs/signIns'
                }

            }
        }
        catch
        {
            throw $_.Exception.Message       
            break
        }
    }
    end
    {
        $script:beta = $null
        Write-Verbose "New-MSGraphPreGetRequest: Your report will be returned by New-MSGraphPreGetRequest."
    }   
}

function New-MSGraphPostRequest
{
    <#
    .SYNOPSIS
    New-MSGraphPostRequest is still under construction.
    
    .DESCRIPTION
    With New-MSGraphPostRequest you can post data(JSON) to Microsoft.Graph.API.

    .PARAMETER URL
    the -URL parameter needs to be the URL you'll post your request to.
    
    .PARAMETER JSON
    This is your formatted data that needs to be posted. See the Example below for more information about the JSON.
    
    .EXAMPLE
        $json = @{
        accountEnabled    = 'true'
        displayName       = "New User"
        mailNickname      = "NewUser"
        userPrincipalName = "NewUser@baswijdenes.onmicrosoft.com"
        passwordProfile   = @{
            forceChangePasswordNextSignIn = 'true'
            password                      = 'H78302ehpib'
        }
    }
    New-MSGraphPOSTRequest -URL 'https://graph.microsoft.com/v1.0/users' -data $JSON -Verbose
    
    .NOTES
    New-MSGraphPostRequest is still under construction. If you have a good idea for this cmdlet, please let me know @ github.

        Please contact me @ github when you find a bug.
    https://github.com/baswijdenes/Microsoft.Graph.API
    #>
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
            Format-MSGRAPHRequests
        }
        catch
        {
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
            throw $_.Exception.Message
            break 
        }
    }
    end
    {
        Write-Verbose "New-MSGraphPOSTRequest: We've successfully Posted the data to Microsoft Graph. The end result will be returned."
        return $EndResult
    }
}

function New-MSGraphPatchRequest
{  
    <#
    .SYNOPSIS
    New-MSGraphPatchRequest is still under construction.
    
    .DESCRIPTION
    With New-MSGraphPatchRequest you can patch data(JSON) to Microsoft.Graph.API.
        
    .PARAMETER URL
    the -URL parameter needs to be the URL you'll patch your request to.
    
    .PARAMETER JSON
    This is your formatted data that needs to be patched. See the Example below for more information about the JSON.
    
    .EXAMPLE
    $Users = "NewUser@baswijdenes.onmicrosoft.com"
    $UserPostList = [System.Collections.Generic.List[Object]]::new() 
    foreach ($User in $users)
    {
        $Result = New-MSGraphGETRequest -URL "https://graph.microsoft.com/v1.0/users/$user" -Verbose
        $DirectoryObject = 'https://graph.microsoft.com/v1.0/directoryObjects/{0}' -f $Result.id
        $UserPostList.Add($DirectoryObject)
    }
    $PostBody = [PSCustomObject] @{
        "members@odata.bind" = $UserPostList
    }

    New-MSGraphPATCHRequest -URL 'https://graph.microsoft.com/v1.0/groups/089025ff-fa7a-47d6-b9e5-6010ab0a0680' -data $JSON -Verbose
    
    .NOTES
    New-MSGraphPatchRequest is still under construction. If you have a good idea for this cmdlet, please let me know @ github.

        Please contact me @ github when you find a bug.
    https://github.com/baswijdenes/Microsoft.Graph.API
    #>
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
            Format-MSGRAPHRequests
        }
        catch
        {
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
            throw $_.Exception.Message
            break 
        }
    }
    end
    {
        Write-Verbose "New-MSGraphPATCHRequest: We've successfully Posted the data to Microsoft Graph. The end result will be returned."
        return "New-MSGraphPatchRequest on $URL run successfully."
    }
}

function New-MSGraphDeleteRequest
{
    <#
    .SYNOPSIS
    With New-MSGraphDeleteRequest you can delete the data on the -URL you provide.
    
    .DESCRIPTION
    With New-MSGraphDeleteRequest you can delete the data on the -URL you provide.
    
    .PARAMETER URL
    the -URL parameter needs to be the URL that goes to the data you want to Delete. You can check the url in Microsoft Graph Explorer before you continue
    
    .EXAMPLE
    New-MsGraphDeleteRequest -URL 'https://graph.microsoft.com/v1.0/users/NewUser@baswijdenesoutlook.onmicrosoft.com' 
    
    .NOTES
    New-MSGraphDeleteRequest is still under construction. If you have a good idea for this cmdlet, please let me know @ github.

        Please contact me @ github when you find a bug.
    https://github.com/baswijdenes/Microsoft.Graph.API
    #>
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
            Format-MSGRAPHRequests
        }
        catch
        {
            throw $_.Exception.Message
            break
        }
    }
    process
    {
        try
        {
            $EndResult = Invoke-RestMethod -Uri $URL -Headers $global:headerParameters -Method Delete -ContentType application/json
        }
        catch
        {
            throw $_.Exception.Message
            break 
        }
    }
    end
    {
        Write-Verbose "New-MSGraphDELETERequest: We've successfully deleted (SOMETHING). The end result (NO RESULT) will be returned."
        return "New-MSGraphDeleteRequest on $URL run successfully."
    }
}
<# END USER FUNCTIONS #>

<# START INTERNAL FUNCTIONS #>
function Connect-MSGRAPHCertificate
{
    <#
    This is an internal function used in Connect-MSGraph to log on with a Certificate.
    #>
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
        [Parameter(Mandatory = $false)]
        [switch]
        $force
    )
    begin
    {
        try
        {
            $global:force = $force
            Format-MSGRAPHPreCheckLogin -LoginType 'Connect-MSGraphCertificate'      
            $global:Thumbprint = $Thumbprint
            $Global:Login = 'MSGraphCertificate'
        }
        catch
        {
            throw $_.Exception.Message
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
            throw $_.Exception.Message
            break
        }
    }
    end
    {
        Write-Verbose "Connect-MSGraphCertificate: We've successfully logged in."
        return 'You successfully logged in with a Certificate. We will keep you logged in until you close your Session.'
    }
}

function Connect-MSGRAPHAppSecret
{
    <#
    This is an internal function used in Connect-MSGraph to log on with a Client Secret.
    #>
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
        [Parameter(Mandatory = $false)]
        [switch]
        $force
    )
    begin
    {
        try 
        {
            $global:force = $force
            Format-MSGRAPHPreCheckLogin -LoginType 'Connect-MSGraphAppSecret'
            $global:ClientSecret = (ConvertTo-SecureString $ApplicationSecret -AsPlainText -Force)
            $ApplicationSecret = $null
            $global:Login = 'MSGraphAppSecret'
        }
        catch
        {
            throw $_.Exception.Message
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
            throw $_.Exception.Message
            break
        }
    }
    end
    {
        Write-Verbose "Connect-MSGraphAppSecret: We've successfully logged in."
        return 'You successfully logged in with an App Secret. We will keep you logged in until you close your Session.'
    }
}

function Connect-MSGRAPHDelegate
{
    <#
    This is an internal function used in Connect-MSGraph to log on with Delegated Permission (and MFA).
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("ID", "AppID", "ClientID", "App")]
        [string]
        $ApplicationID,
        [Parameter(Mandatory = $false)]
        [string]
        $RedirectUri,
        [Parameter(Mandatory = $false)]
        [System.Net.ICredentials]
        $UserCredentials,
        [Parameter(Mandatory = $true)]
        [Alias("TenantName", "TenantID")]
        [string]
        $Tenant,
        [Parameter(Mandatory = $false)]
        [switch]
        $force
    )
    begin
    {
        try 
        { 
            if (($null -eq $UserCredentials) -and ($null -eq $RedirectUri))
            {
                Throw "There is no UserCredentials or RedirectUri defined. Exiting script..."
                break
            } 
            if ($UserCredentials)
            {
                Write-Verbose "Connect-MSGraphDelegate: UserCredentials - Basic: Logging in with Basic UserCredentials"
                $global:RedirectUri = $null
                $global:UserCredentials = $UserCredentials
            }
            elseif ($redirectUri)
            {
                Write-Verbose "Connect-MSGraphDelegate: UserCredentials - MFA: Logging in with MFA UserCredentials"
                $global:UserCredentials = $null
                $global:RedirectUri = $RedirectUri
            }
            $global:force = $force
            Format-MSGRAPHPreCheckLogin -LoginType 'Connect-MSGraphDelegate'
            $global:Login = 'MSGraphDelegate'
        }
        catch
        {
            throw $_.Exception.Message
            break
        }
    }
    process
    {
        try
        {
            if ($global:RedirectUri)
            {
                Get-MSGRAPHOauthToken `
                    -RedirectUri $global:RedirectUri `
                    -Tenant $global:Tenant `
                    -AppID $global:ApplicationID
            }
            elseif ( $global:UserCredentials)
            {
                Get-MSGRAPHOauthToken `
                    -UserCredentials $global:UserCredentials `
                    -Tenant $global:Tenant `
                    -AppID $global:ApplicationID
            }
        }
        catch
        {
            throw $_.Exception.Message
            break
        }
    }
    end
    {
        Write-Verbose "Connect-MSGraphDelegate: We've successfully logged in."
        return 'You successfully logged in with UserCredentials. We will keep you logged in until you close your Session.'
    }
}

function Format-MSGRAPHPreCheckLogin
{
    <#
    This is an internal function used in Connect-MSGraphAppSecret, Connect-MSGraphdelegate and Connect-MSGraphCertificate.
    It will check if you're already logged on to one of these connections and to confirm you want to continue.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Connect-MSGraphAppSecret', 'Connect-MSGraphdelegate', 'Connect-MSGraphCertificate')]
        $LoginType
    )
    if ($global:force)
    {
        Write-Verbose "Connect-MSGraph: -Force parameter found. We will continue logging in without confirmation. Even if these is already a session active."
        $global:login = $null
        $global:AppPass = $null
        $global:Delegate = $null
        $global:force = $null
    } 
    else 
    {
        switch ($LoginType)
        {
            'Connect-MSGraphAppSecret'
            {
                if ($global:login -eq 'MSGraphCertificate')
                {
                    Write-Verbose "Connect-MSGraphAppSecret: You're already logged on with a Certificate."
                    $Confirmation = Read-Host 'You already logged on with a Certificate. Are you sure you want to proceed with a ClientSecret? Type (Y)es to continue.'
                    if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true') -or ($Confirmation -eq '(Y)es'))
                    {
                        Write-Verbose "Connect-MSGraphAppSecret: We will continue logging in with a ClientSecret."
                        $global:login = $null
                        $global:Delegate = $null
                    }
                    else
                    {
                        Write-Verbose "Connect-MSGraphAppSecret: Aborting logging in with ClientSecret."
                        throw "Connect-MSGraph aborted"
                    }
                }
                elseif ($global:login -eq 'MSGraphDelegate')
                {
                    Write-Verbose "Connect-MSGraphAppSecret: You're already logged on with UserCredentials."
                    $Confirmation = Read-Host 'You already logged on with delegated permissions. Are you sure you want to proceed with a ClientSecret? Type (Y)es to continue.'
                    if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true') -or ($Confirmation -eq '(Y)es'))
                    {
                        Write-Verbose "Connect-MSGraphAppSecret: We will continue logging in with a ClientSecret."
                        $global:login = $null
                        $global:Delegate = $null
                    }
                    else
                    {
                        Write-Verbose "Connect-MSGraphAppSecret: Aborting logging in with a ClientSecret."
                        throw "Connect-MSGraph aborted"
                    } 
                }
            }
            'Connect-MSGraphCertificate'
            {
                If ($global:login -eq 'MSGraphAppSecret')
                {
                    Write-Verbose "Connect-MSGraphCertificate: You're already logged on with ClientID and ClientScret."
                    $Confirmation = Read-Host 'You already logged on with ClientID and ClientSecret. Are you sure you want to proceed with Certificate? Type (Y)es to continue.'
                    if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true'))
                    {
                        Write-Verbose "Connect-MSGraphCertificate: We will continue logging in with a Certificate."
                        $global:login = $null
                        $global:Delegate = $null
                        $global:AppPass = $null
                    }
                    else
                    {
                        Write-Verbose "Connect-MSGraphCertificate: Aborting logging in with Certificate."
                        throw "Connect-MSGraph aborted"
                    }

                } 
                elseif ($global:login -eq 'MSGraphDelegate')
                {
                    Write-Verbose "Connect-MSGraphCertificate: You're already logged on with UserCredentials."
                    $Confirmation = Read-Host 'You already logged on with UserCredentials. Are you sure you want to proceed with Certificate? Type (Y)es to continue.'
                    if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true') -or ($Confirmation -eq '(Y)es'))
                    {
                        Write-Verbose "Connect-MSGraphCertificate: We will continue logging in with a Certificate."
                        $global:login = $null
                        $global:Delegate = $null
                        $global:AppPass = $null
                    }
                    else
                    {
                        Write-Verbose "Connect-MSGraphCertificate: Aborting logging in with a Certificate"
                        throw "Connect-MSGraph aborted"
                    }
                }
            }
            'Connect-MSGraphDelegate'
            {
                If ($global:login -eq 'MSGraphAppSecret')
                {
                    Write-Verbose "Connect-MSGraphDelegate: You're already logged on with Certificate."
                    $Confirmation = Read-Host 'You already logged on with a ClientSecret. Are you sure you want to proceed with UserCredentials? Type (Y)es to continue.'
                    if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true') -or ($Confirmation -eq '(Y)es'))
                    {
                        Write-Verbose "Connect-MSGraphDelegate: We will continue logging in with UserCredentials."
                        $global:login = $null
                        $global:AppPass = $null
                        $global:CertLogin = $null
                    }
                    else
                    {
                        Write-Verbose "Connect-MSGraphDelegate: Aborting logging in with UserCredentials."
                        throw "Connect-MSGraph aborted"
                    }
                } 
                elseif ($global:login -eq 'MSGraphCertificate')
                {
                    Write-Verbose "Connect-MSGraphDelegate: You're already logged on with a Certificate."
                    $Confirmation = Read-Host 'You already logged on with a Certificate. Are you sure you want to proceed with UserCredentials? Type (Y)es to continue.'
                    if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true') -or ($Confirmation -eq '(Y)es'))
                    {
                        Write-Verbose "Connect-MSGraphDelegate: We will continue logging in with UserCredentials."
                        $global:login = $null
                        $global:CertLogin = $null
                        $global:AppPass = $null
                    }
                    else
                    {
                        Write-Verbose "Connect-MSGraphDelegate: Aborting logging in with UserCredentials."
                        throw "Connect-MSGraph aborted"
                    }

                }
            }
        }
    }
}

function Format-MSGRAPHRequests
{  
    <#
     This is an internal function used in Connect-MSGraphAppSecret, Connect-MSGraphdelegate and Connect-MSGraphCertificate.
     This will trigger Get-MSGRAPHOauthToken.
    #>
    [CmdletBinding()]
    param (
    )
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
    elseif ($global:Login -eq 'MSGraphDelegate')
    {
        if ($global:RedirectUri)
        {
            Get-MSGRAPHOauthToken `
                -RedirectUri $global:RedirectUri `
                -Tenant $global:Tenant `
                -AppID $global:ApplicationID
        }
        elseif ($global:UserCredentials)
        {
            Get-MSGRAPHOauthToken `
                -UserCredentials $global:UserCredentials `
                -Tenant $global:Tenant `
                -AppID $global:ApplicationID
        }
    }
    else
    {
        Throw "You need to run Connect-MSGraph before you can continue. Exiting script..."
        break
    }
}

function Get-MSGRAPHOauthToken
{
    <#
    This is an internal function used in Connect-MSGraph and more cmdlets. 
    It will log you on Microsoft Graph and it will also refresh your AccessToken after it expired.
    #>
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
        [Parameter(Mandatory = $false)]
        [string]
        $RedirectUri,
        [Parameter(Mandatory = $false)]
        [System.Net.ICredentials]
        $UserCredentials,
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
            if (($null -eq $global:AppPass) -and ($null -eq $global:CertLogin) -and ($null -eq $global:Delegate))
            {
                if ($AppPass)
                {
                    Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: We will continue logging in with ApplicationSecret."
                }
                elseif ($Thumbprint)
                { 
                    Write-Verbose "Get-MSGRAPHOauthToken: Certificate: We will continue logging in with Certificate."
                    if ($null -eq $global:Certificate)
                    {
                        if ($Thumbprint.length -eq '40')
                        {
                            Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Thumbprint length is correct. We will continue searching for the certificate in CurrentUser\My and LocalMachine\My."
                            $Certificate = $null
                        }
                        else
                        {
                            throw 'The thumbprint length is incorrect. Make sure you paste the thumbprint correctly. Exiting script...'
                            break
                        }
                        Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Starting search in CurrentUser\my."
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
                        Write-Verbose "Get-MSGRAPHOauthToken: Certificate: We already obtained a certificate from a previous login. We will continue logging in."
                    }
                    [System.Collections.Generic.List[String]]$scopes = @('https://graph.microsoft.com/.default')
                    $Builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($AppID).
                    WithTenantId($tenant).
                    WithCertificate($global:Certificate).
                    Build()
                }
                elseif ($RedirectUri)
                {
                    Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials - MFA: We will continue logging in with UserCredentials."
                    [System.Collections.Generic.List[String]]$scopes = @('https://graph.microsoft.com/.default')
                    $Builder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($AppID).
                    WithTenantId($tenant).
                    WithRedirectUri($redirecturi).
                    Build()
                }
                elseif ($UserCredentials)
                {
                    Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials - Basic: We will continue logging in with UserCredentials."
                }
                else
                {
                    Throw "There is no Password, Thumbprint, RedirectUri, or UserCredentials. Exiting script..."
                    break
                }
            }
            else
            {
                Write-Verbose "Get-MSGRAPHOauthToken: A previous Login already exists."
            }
        }
        catch
        {
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
                $Body = @{
                    grant_type    = "client_credentials";
                    resource      = $Resource;
                    client_id     = $AppID;
                    client_secret = $TempPass 
                }
                if (!($global:AppPass))
                {
                    Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: This is the first time logging in with a ClientSecret."
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
                            -AppID $global:ApplicationID `
                            -AppPass $global:ClientSecret `
                            -Tenant $global:Tenant
                    }
                    else 
                    {
                        Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: Oauth token from last run is still active."
                    }
                }
            }
            elseif ($Thumbprint) 
            {
                [datetime]$UnixDateTime = '1970-01-01 00:00:00'
                $Date = Get-Date
                $UTCDate = [System.TimeZoneInfo]::ConvertTimeToUtc($Date)
                if (!($global:CertLogin))
                {
                    Write-Verbose "Get-MSGRAPHOauthToken: Certificate: This is the first time logging in with a Certificate."
                    $global:CertLogin = $Builder.AcquireTokenForClient($scopes).
                    ExecuteAsync()
                    if ($null -eq $global:CertLogin.result.AccessToken)
                    {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                        break
                    }
                    else
                    {
                        $global:headerParameters = @{
                            Authorization = "Bearer $($global:CertLogin.result.AccessToken)"
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
                            -AppID $global:ApplicationID `
                            -Thumbprint $global:Thumbprint `
                            -Tenant $global:Tenant
                    }
                    else 
                    {
                        Write-Verbose "Get-MSGRAPHOauthToken: Certificate: Oauth token from last run is still active."
                    }
                }
            }
            elseif ($RedirectUri)
            { 
                [datetime]$UnixDateTime = '1970-01-01 00:00:00'
                $Date = Get-Date
                $UTCDate = [System.TimeZoneInfo]::ConvertTimeToUtc($Date)
                if (!($global:Delegate))
                {
                    $global:Delegate = $Builder.AcquireTokenInteractive($scopes).ExecuteAsync()
                    if ($null -eq $global:Delegate.result.AccessToken)
                    {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                        break
                    }
                    else
                    {
                        $global:headerParameters = @{
                            Authorization = "Bearer $($global:Delegate.result.AccessToken)"
                        }
                    }
                }
                else
                {
                    Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials - MFA: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials - MFA: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $global:Delegate.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate)
                    {
                        if ($null -eq $global:Delegate.Result.ExpiresOn.UtcDateTime)
                        {
                            Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials - MFA: Oauth token is basic authentication. Emptying Oauth variable and re-running function."
                        }
                        else
                        {
                            Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials - MFA: Oauth token expired. Emptying Oauth variable and re-running function."
                        }

                        $global:Delegate = $null
                        Get-MSGRAPHOauthToken `
                            -RedirectUri $global:RedirectUri `
                            -Tenant $global:Tenant `
                            -AppID $global:ApplicationID
                    }
                    else 
                    {
                        Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials - MFA: Oauth token from last run is still active."
                    }
                }
            }
            elseif ($userCredentials)
            {
                $global:Body = @{
                    grant_type = 'password';
                    resource   = $Resource;
                    username   = $($userCredentials.UserName)
                    password   = $($UserCredentials.Password)
                    client_id  = $AppID;
                    scope      = 'openid'
                }
                if (!($global:Delegate))
                {
                    $global:Delegate = Invoke-RestMethod -Method Post -Uri $loginURL/$Tenant/oauth2/token?api-version=1.0 -Body $Body -UseBasicParsing
                    if ($null -eq $global:Delegate.access_token)
                    {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                        break
                    }
                    else
                    {
                        $global:headerParameters = @{
                            Authorization = "$($global:Delegate.token_type) $($global:Delegate.access_token)"
                        }
                    }
                }
                else
                {
                    Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials - Basic: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials - Basic: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $UnixDateTime.AddSeconds($global:delegate.expires_on)
                    if ($OauthExpiryTime -le $UTCDate)
                    {
                        if ($null -eq $global:delegate.expires_on)
                        {
                            Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials - Basic: Oauth token is MFA authentication. Emptying Oauth variable and re-running function."
                        }
                        else
                        {
                            Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials - Basic: Oauth token expired. Emptying Oauth variable and re-running function."
                        }
                        $global:delegate = $null
                        Get-MSGRAPHOauthToken `
                            -UserCredentials $global:UserCredentials `
                            -Tenant $global:Tenant `
                            -AppID $global:ApplicationID
                    }
                    else 
                    {
                        Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials - Basic: Oauth token from last run is still active."
                    }
                }
            }
        }
        catch
        {
            throw $_.Exception.Message
            break
        }
    }
    end
    {
        if ($global:AppPass)
        {
            Write-Verbose "Get-MSGRAPHOauthToken: ApplicationSecret: We have successfully retrieved the Oauth access token. We will continue the script."
            $BSTR = $null
        } 
        elseif ($global:CertLogin)
        {
            Write-Verbose "Get-MSGRAPHOauthToken: Certificate: We have successfully retrieved the Oauth access token. We will continue the script."
        }
        elseif ($global:Delegate)
        {
            Write-Verbose "Get-MSGRAPHOauthToken: UserCredentials: We have successfully retrieved the Oauth access token. We will continue the script."
        }
        else 
        {
            Write-Verbose "There is no active Oauth token available or it expired. We will empty Oauth token variable and re-run the script."
        }
    }
}

function Format-MSGRAPHPreGetRequest 
{
    <#
    This is an internal function used in New-MSGRAPHPreGetRequest to format the queries.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("BETAURI")]
        [string]
        $BETAURL,
        [Parameter(Mandatory = $true)]
        [Alias("URI")]
        [string]
        $URL,
        [Parameter(Mandatory = $false)]
        [switch]
        $Script:Beta
    )
    if ($script:Beta)
    {
        if (!($Once))
        {
            Write-Verbose "New-MSGraphPreGetRequest: BETA: $BETAURL"
            New-MSGraphGetRequest -URL $BETAURL
        }
        else
        {
            Write-Verbose "New-MSGraphPreGetRequest: BETA: ONCE: $BETAURL"
            New-MSGraphGetRequest -URL $BETAURL -Once     
        }
    }
    Else
    {
        if (!($Once))
        {
            Write-Verbose "New-MSGraphPreGetRequest: v1.0: $URL"
            New-MSGraphGetRequest -URL $URL
        }
        else
        {
            Write-Verbose "New-MSGraphPreGetRequest: v1.0: $URL"
            New-MSGraphGetRequest -URL $URL -Once     
        }
    }
}
<# END INTERNAL FUNCTIONS #>