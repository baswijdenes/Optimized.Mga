#region main
function Connect-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Connect-Mga will retreive a RefreshToken from Microsoft Graph.
    
    .DESCRIPTION
    By selecting one of these parameters you log on with the following:

    ClientSecret: Will log you on with a ClientSecret.
    Certificate: Will log you on with a Certificate.
    Thumbprint: Will search for a Certificate under thumbprint on local device and log you on with a Certificate.
    UserCredentials: Will log you on with basic authentication.
    RedirectUri: Will log you on with MFA Authentication.
    The OauthToken is automatically renewed when you use cmdlets.

    .PARAMETER Thumbprint
    Use a certificate thumbprint to log on with. Connec-Mga will search for the certificate in the cert store.
    
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

    .PARAMETER Tenant
    Tenant is the TenantID or onmicrosoft.com address. Don't confuse this with ApplicationID.

    I should look like this:
    'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX'
    Or
    XXXXXXX.onmicrosoft.com
    
    .PARAMETER LoginScope
    You can only use LoginScope with RedirectUri, but unfortunately the token will always include all permissions the app has.
    
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
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Thumbprint')]
        [ValidateScript( { $_.length -eq 40 })]
        [string]
        $Thumbprint, 
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        $Certificate,
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [string]
        $ClientSecret, 
        [Parameter(Mandatory = $true, ParameterSetName = 'RedirectUri')]
        [String]
        $RedirectUri,
        [Parameter(Mandatory = $true, ParameterSetName = 'Credentials')]
        [System.Net.ICredentials]
        $UserCredentials,
        [Parameter(Mandatory = $true)]
        [String]
        $ApplicationID,
        [Parameter(Mandatory = $true)]
        [String]
        $Tenant,
        <#[Parameter(Mandatory = $false, ParameterSetName = 'RedirectUri')]
        [AllowEmptyString()]  
        [Object]
        $LoginScope,#>
        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )
    begin {
        if ($Force) {
            Write-Verbose 'Connect-Mga: -Force parameter found. Running Disconnect-Mga to force a log on.'
            $null = Disconnect-Mga
        }
        else {
            Initialize-MgaConnect
        }
    }
    process {
        if ($Thumbprint) {
            Write-Verbose "Connect-Mga: Thumbprint: Logging in with Thumbprint."
            Receive-MgaOauthToken `
                -ApplicationID $ApplicationID `
                -Tenant $Tenant `
                -Thumbprint $Thumbprint 
        }
        elseif ($Certificate) {
            Write-Verbose "Connect-Mga: Certificate: Logging in with certificate."
            Receive-MgaOauthToken `
                -ApplicationID $ApplicationID `
                -Tenant $Tenant `
                -Certificate $Certificate 
        }
        elseif ($ClientSecret) {
            Write-Verbose "Connect-Mga: RedirectUri: Logging in with RedirectUri."
            Receive-MgaOauthToken `
                -ApplicationID $ApplicationID `
                -Tenant $Tenant `
                -ClientSecret $ClientSecret
        }
        elseif ($RedirectUri) {
            Write-Verbose "Connect-Mga: MFA UserCredentials: Logging in with MFA UserCredentials."
            Receive-MgaOauthToken `
                -ApplicationID $ApplicationID `
                -Tenant $Tenant `
                -RedirectUri $RedirectUri 
             #   -LoginScope $LoginScope
        }
        elseif ($UserCredentials) {
            Write-Verbose "Connect-Mga: Basic UserCredentials: Logging in with Basic UserCredentials."
            Receive-MgaOauthToken `
                -ApplicationID $ApplicationID `
                -Tenant $Tenant `
                -UserCredentials $UserCredentials 
        }
    }
    end {
        return "You've successfully logged in to Microsoft.Graph.API."
    }
}

function Disconnect-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Use this to log off Microsoft Graph.
    
    .DESCRIPTION
    To update the OauthToken I fill the global scope with a number of properties. 
    The properties are emptied by Disconnect-Mga.
    
    .EXAMPLE
    Disconnect-Mga
    #>
    [CmdletBinding()]
    param (
    )
    begin {
        if ($global:MgaLoginType.length -ge 1) {
            Write-Verbose "Disconnect-Mga: Disconnecting from Microsoft.Graph.API."
        }
    }
    process {
        try {
            $Null = Get-Variable -Name "Mga*" -Scope Global | Remove-Variable -Force -Scope Global
        }
        catch {
            throw $_.Exception.Message
        }
    }
    end {
        return "You've successfully logged out."
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
        $Once
    )
    begin {
        Update-MgaOauthToken
    }
    process {
        try {
            Write-Verbose "Get-Mga: Getting results from $URL."
            $Result = Invoke-WebRequest -UseBasicParsing -Headers $global:MgaHeaderParameters -Uri $URL -Method get
            if ($result.Headers.'Content-Type' -like "application/octet-stream*") {
                Write-Verbose "Get-Mga: Result is in Csv format. Converting to Csv and returning end result."
                $EndResult = ConvertFrom-Csv -InputObject $Result
            }
            if ($result.Headers.'Content-Type' -like "application/json*") {   
                Write-Verbose "Get-Mga: Result is in JSON format. Converting to JSON."
                $Result = ConvertFrom-Json -InputObject $Result
                if ($Result.'@odata.nextLink') {
                    if (!($Once)) {
                        Write-Verbose "Get-Mga: There is an @odata.nextLink for more output. We will run Get-Mga again with the next data link."
                        $EndResult = @()
                        foreach ($Line in ($Result).value) {
                            $EndResult += $Line
                        }
                        While ($Result.'@odata.nextLink') {
                            Write-Verbose "Get-Mga: There is another @odata.nextLink for more output. We will run Get-Mga again with the next data link."
                            Update-MgaOauthToken
                            $Result = (Invoke-WebRequest -UseBasicParsing -Headers $global:MgaHeaderParameters -Uri $Result.'@odata.nextLink' -Method Get).Content | ConvertFrom-Json
                            foreach ($Line in ($Result).value) {
                                $EndResult += $Line
                            }
                            Write-Verbose "Get-Mga: Count is: $($EndResult.count)."
                        }
                    }
                    else {
                        $EndResult = @()
                        foreach ($Line in ($Result).value) {
                            $EndResult += $Line
                        }
                        Write-Verbose 'Get-Mga: Parameter -Once found. Even if there is an @odata.nextLink for more output, we will not extract more data.'
                    }
                }
                elseif ($Result.value) {
                    Write-Verbose "Get-Mga: There is no @odata.nextLink. We will add the data to end result."
                    $EndResult = $Result.value
                }
                else {
                    Write-Verbose "Get-Mga: There is no @odata.nextLink. We will add the data to end result."
                    $EndResult = $Result
                }
            }
        }
        catch [System.Net.WebException] {
            Write-Warning "WebException Error message! This could be due to throttling limit."
            $WebResponse = $_.Exception.Response
            if ($WebResponse.StatusCode -eq 429) {
                if ($MgaThrottleHit) {
                    $MgaThrottleHit.add('15')
                }
                [int]$RetryValue = $WebResponse.Headers['Retry-After']
                Write-Warning "WebException Error message! Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
                Start-Sleep -Seconds $($RetryValue + 1) 
                if ($MgaThrottleHit) {
                    $MgaThrottleHit.add('False')
                }
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
        $InputObject
    )
    begin {
        Update-MgaOauthToken
        $InputObject = ConvertTo-MgaJson -InputObject $InputObject
    }
    process {
        try {
            if ($InputObject) {
                Write-Verbose "Post-Mga: Posting InputObject to Microsoft.Graph.API."
                $Result = Invoke-RestMethod -Uri $URL -Headers $global:MgaheaderParameters -Method post -Body $InputObject -ContentType application/json
            }
            else {
                $Result = Invoke-RestMethod -Uri $URL -Headers $global:MgaheaderParameters -Method post -ContentType application/json    
            }
        }
        catch [System.Net.WebException] {
            Write-Warning "WebException Error message! This could be due to throttling limit."
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
        Write-Verbose "Post-Mga: We've successfully Posted the data to Microsoft.Graph.API."
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
        $Batch
    )
    begin {
        Update-MgaOauthToken
        $ValidateJson = ConvertTo-MgaJson -InputObject $InputObject -Validate
        if ($Batch -eq $true) {
            Write-Warning 'Patch-Mga: begin: Parameter Batch will only work when the InputObject contains property: members@odata.bind. If this is not the case -Batch will be ignored.'
        }
    }
    process {
        try {
            if (($ValidateJson -eq $false) -and (($InputObject."members@odata.bind").count -gt 20)) {
                if ($Batch -eq $true) {
                    Optimize-Mga -InputObject $InputObject -URL $URL -Request 'Patch-Mga' -Batch
                }
                else {
                    Optimize-Mga -InputObject $InputObject -URL $URL -Request 'Patch-Mga'     
                }
            }
            else {
                $InputObject = ConvertTo-MgaJson -InputObject $InputObject
                Write-Verbose "Patch-Mga: Patching InputObject to Microsoft.Graph.API."
                $Result = Invoke-RestMethod -Uri $URL -Headers $global:MgaheaderParameters -Method Patch -Body $InputObject -ContentType application/json
            }
        }
        catch [System.Net.WebException] {
            Write-Warning "WebException Error message! This could be due to throttling limit."
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
        $InputObject
    )
    begin {
        Update-MgaOauthToken
        if ($InputObject) {
            $ValidateJson = ConvertTo-MgaJson -InputObject $InputObject -Validate
        }
    }
    process {
        try {
            if (($ValidateJson -eq $false) -and (($InputObject."members@odata.bind").count -gt 20)) {
                Optimize-Mga -InputObject $InputObject -URL $URL -Request 'Delete-Mga'
            }
            elseif ($URL.count -gt 1) {
                Optimize-Mga -URL $URL -Request 'Delete-Mga'
            }
            elseif ($InputObject) {
                Write-Verbose "Delete-Mga: Deleting InputObject on $URL to Microsoft.Graph.API."
                $InputObject = ConvertTo-MgaJson -InputObject $InputObject
                $Result = Invoke-RestMethod -Uri $URL -body $InputObject -Headers $global:MgaheaderParameters -Method Delete -ContentType application/json
            }
            else {
                Write-Verbose "Delete-Mga: Deleting conent on $URL to Microsoft.Graph.API."
                $Result = Invoke-RestMethod -Uri $URL -Headers $global:MgaheaderParameters -Method Delete -ContentType application/json
            }

        }
        catch [System.Net.WebException] {
            Write-Warning "WebException Error message! This could be due to throttling limit."
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
            Write-Verbose "Batch-Mga: Creating Batch request."
            foreach ($Line in $InputObject) {
                try {
                    if ($Line.Url -like "https://graph.microsoft.com/v1.0*") {
                        $URL = ($Line.Url).Replace('https://graph.microsoft.com/v1.0', '')
                    }
                    elseif ($Line.Url -like "https://graph.microsoft.com/beta*") {
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
            Write-Verbose "Batch-Mga: Patching Batch request."
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
                    if ($Object.body -like "*Your request is throttled temporarily.*") {
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
                $ThrottleTime = $object.body -replace "[^0-9]" , ''
                Write-Warning "WebException Error message! This could be due to throttling limit."
                Write-Warning "WebException Error message! Throttling error. Retry-After value: $($ThrottleTime) seconds. Sleeping for $($ThrottleTime)s."
                Start-Sleep -seconds ([int]$ThrottleTime + 1)
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

function Send-MgaMail {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/tree/main

    .SYNOPSIS
    Sends emails with Microsoft Graph.
    
    .DESCRIPTION
    Send-MgaMail uses the Microsoft Graph v1.0 REST API.
    You need Mail.Send permissions.

    .PARAMETER To
    To accepts an array of addresses.
    
    .PARAMETER Subject
    Is the email subject.
    
    .PARAMETER Body
    Is the email body.
    
    .PARAMETER From
    Add the From address when logged in with Application permissions.
    When logged in with user credentials the From address will automatically be the userLogon. This is also displayed in a warning message.
    
    .PARAMETER Attachments
    Attachments accepts an Array. Make sure to use the FullName (Including Path).
    Example:
    'C:\Temp\Attachment.txt','C:\Temp\Attachment2.txt'

    .EXAMPLE
    Send-MgaMail -From 'John.Doe@XXXXXXXXXXX.onmicrosoft.com' -To 'Jack.Doe@contoso.com' -Subject 'Test message' -Body 'This is a test message'

    .EXAMPLE
    Send-MgaMail -To 'Jack.Doe@contoso.com' -Subject 'Test message' -Body 'This is a test message'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_ -like "*@*" })]
        [string[]]
        $To,
        [Parameter(Mandatory = $true)]
        [string]
        $Subject,
        [Parameter(Mandatory = $true)]
        [string]
        $Body,
        [Parameter(Mandatory = $false)]
        [ValidateScript( { $_ -like "*@*" })]
        [string]
        $From,
        [Parameter(Mandatory = $false)]
        [object]
        $AttachmentPaths,
        [Parameter(Mandatory = $false)]
        [object]
        $AttachmentObjects
    )
    begin {
        try {
            $URL = 'https://graph.microsoft.com/v1.0/me/sendMail'
            $ToList = [System.Collections.Generic.List[System.Object]]::new()
            foreach ($Address in $To) {
                $Object = [PSCustomObject]@{
                    emailAddress = [PSCustomObject] @{
                        'address' = $Address
                    }
                }
                $ToList.Add($Object)
            }
            $Message = [PSCustomObject] @{
                message = [PSCustomObject] @{
                    subject      = $subject
                    body         = [PSCustomObject] @{
                        contentType = 'HTML'
                        content     = $body
                    }
                    ToRecipients = @($ToList)
                }
            }
            if (($AttachmentPaths) -or ($AttachmentObjects)) {
                Write-Verbose "Send-MgaMail: process: Attachment parameter found."
                $AttachmentsList = [System.Collections.Generic.List[System.Object]]::new()
                if ($AttachmentPaths) {
                    foreach ($Attachment in $AttachmentPaths) {
                        try {
                            Write-Verbose "Send-MgaMail: process: Testing path to $Attachment."
                            $FileBytes = Get-Content -Path $Attachment -Encoding Byte -ErrorAction stop
                            $AttachmentName = $Attachment.split('\') | Select-Object -Last 1
                            $Base64String = ([System.Convert]::ToBase64String($FileBytes))
                            $AttachmentsNode = [PSCustomObject]@{
                                "@odata.type"  = "#microsoft.graph.fileAttachment"
                                "name"         = $AttachmentName
                                "contentBytes" = $Base64String
                            }
                            $AttachmentsList.Add($AttachmentsNode)
                        }
                        catch {
                            Write-Warning "There is an error with $AttachmentPath. We will continue despite error."
                            continue
                        }
                    }
                }
                elseif ($AttachmentObjects) {
                    foreach ($AttachmentObject in $AttachmentObjects) {
                        try {
                            Write-Verbose "Send-MgaMail: process: Converting object to Base64String."
                            $Bytes = [System.Text.Encoding]::Unicode.GetBytes($AttachmentObject.Content)
                            $Base64String = [System.Convert]::ToBase64String($Bytes)
                            $AttachmentsNode = [PSCustomObject]@{
                                "@odata.type"  = "#microsoft.graph.fileAttachment"
                                "name"         = $AttachmentObject.Name
                                "contentBytes" = $Base64String
                            }
                            $AttachmentsList.Add($AttachmentsNode)
                        }
                        catch {
                            Write-Warning "There is an error with $AttachmentObject. We will continue despite error."
                            continue
                        }
                    }
                }
                $Message = [PSCustomObject] @{
                    message = [PSCustomObject] @{
                        subject      = $subject
                        body         = [PSCustomObject] @{
                            contentType = 'HTML'
                            content     = $body
                        }
                        toRecipients = @($ToList)
                        Attachments  = @($AttachmentsList)
                    }
                }
            }
            if ($From.length -gt 0) {
                if (($global:MgaRU.result.length -ge 1) -and ($global:MgaRU.result.account.Username -ne $From)) {
                    Write-Warning "You have logged in with Credentials. We cannot use a different Email Address than $From. We will use $From to send email from." 
                    $From = $global:MgaRU.result.account.Username
                }
                if (($global:MgaBasic.access_token.length -ge 1) -and ($global:MgaUserCredentials.UserName -ne $From)) {
                    Write-Warning "You have logged in with Credentials. We cannot use a different Email Address than $From. We will use $From to send email from." 
                    $From = $global:MgaUserCredentials.UserName 
                }
                Write-Verbose "Send-MgaMail: From address is $From."
                $FromNode = [PSCustomObject] @{
                    emailAddress = [PSCustomObject] @{
                        'address' = $From
                    }
                }
                $Message | Add-Member -MemberType NoteProperty -Name 'From' -Value $FromNode
                $URL = "https://graph.microsoft.com/v1.0/users/$($From)/sendMail"
            }
        }
        catch {
            throw $_.Exception.Message
        }
    }
    process {
        try {
            Write-Verbose 'Send-MgaMail: Sending email...'
            Post-Mga -URL $URL -InputObject $Message
        }
        catch {
            throw $_.Exception.Message
        }
    }
    end {
        return "Email to $To with subject $Subject has been sent succesfully."
    }
}
#endregion main
#region experimental
function Start-MgaRunspaces {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $MaxThreads,
        [parameter(mandatory = $true)]
        [MgaRunspaces]$InputObject
    )
    begin {
        if (!($global:MgaRunspacesResults)) {

        }
        if (!($global:MgaThrottleHit)) {
            $global:MgaThrottleHit = [System.Collections.Generic.List[Object]]::new()
        }
        else {
            if (($global:MgaThrottleHit | Select-Object -Last 1) -ne 'False') {
                Write-Warning "Throttlelimit hit! we will sleep for $($global:MgaThrottleHit | Select-Object -Last 1)"
                Start-Sleep -Seconds $($global:MgaThrottleHit | Select-Object -Last 1)
            }
        }
        $ParamsList = @{
            'MgaHeaderParameters' = $global:MgaHeaderParameters
            'MgaApplicationID'    = $global:MgaApplicationID
            'MgaTenant'           = $global:MgaTenant
        }       
        $ScriptTry = @'
        try {
            Import-Module "C:\OneDrive\Documents\Developer\Programming\PowerShell\Repositories\BWIT - Public Repository\Optimized.Mga\Optimized.Mga\Optimized.Mga.psd1"

'@
        $ScriptThrow = @'
        
    }
        catch {
            throw $_.Exception.Message
        }
'@
        if ($null -ne $global:MgaAppPass) {
            $ParamsList.Add('MgaAppPass', $global:MgaAppPass)
            $ParamsList.Add('MgaSecret', $global:MgaSecret)
            $ScriptStart = {
                param ($MgaHeaderParameters, $MgaApplicationID, $MgaTenant, $MgaAppPass, $MgaSecret, $MgaThrottleHit)
            }
        }
        elseif ($null -ne $global:MgaCert) {
            $ParamsList.Add('MgaCert', $global:MgaCert)
            $ParamsList.Add('MgaCertificate', $global:MgaCertificate)
            $ScriptStart = {
                param ($MgaHeaderParameters, $MgaApplicationID, $MgaTenant, $MgaAppPass, $MgaCertificate)
            }
        }
        elseif ($null -ne $global:MgaTPrint) {
            $ParamsList.Add('MgaTPrint', $global:MgaTPrint)
            $ParamsList.Add('MgaThumbprint', $global:MgaThumbprint)
            $ScriptStart = {
                param ($MgaHeaderParameters, $MgaApplicationID, $MgaTenant, $MgaAppPass, $MgaThumbprint)
            }         
        }
        elseif ($null -ne $global:MgaRU) {
            $ParamsList.Add('MgaRU', $global:MgaRU)
            $ParamsList.Add('MgaRedirectUri', $global:MgaRedirectUri)
            $ParamsList.Add('MgaLoginScope', $global:MgaLoginScope)
            $ScriptStart = {
                param ($MgaHeaderParameters, $MgaApplicationID, $MgaTenant, $MgaAppPass, $MgaRedirectUri, $MgaLoginScope)
            }
        }
        elseif ($null -ne $global:MgaBasic) {
            $ParamsList.Add('MgaBasic', $global:MgaBasic)
            $ParamsList.Add('MgaUserCredentials', $global:MgaUserCredentials)
            $ScriptStart = {
                param ($MgaHeaderParameters, $MgaApplicationID, $MgaTenant, $MgaAppPass, $MgaUserCredentials)
            }
        }
        else {
            Throw "You need to run Connect-Mga before you can continue. Exiting script..."
        }
        switch ($InputObject.Method) {
            ('Get') {
                $Script = @"
                    Get-Mga -URL $($InputObject.URL)
"@
            }
            ('Post') {
                if ($null -ne $InputObject.InputObject) {
                    $Script = {
                        Post-Mga -URL $InputObject.URL -InputObject $InputObject.InputObject
                    }
                }
                else {
                    $Script = {
                        Post-Mga -URL $InputObject.URL
                    }
                }
            }
            ('Put') {
                if ($null -ne $InputObject.InputObject) {
                    $Script = {
                        Put-Mga -URL $InputObject.URL -InputObject $InputObject.InputObject
                    }
                }
                else {
                    $Script = {
                        Put-Mga -URL $InputObject.URL
                    }
                }
            }
            ('Delete') {
                if ($null -ne $InputObject.InputObject) {
                    $Script = {
                        Delete-Mga -URL $InputObject.URL -InputObject $InputObject.InputObject
                    }
                }
                else {
                    $Script = {
                        Delete-Mga -URL $InputObject.URL
                    }
                }
            }
            ('Patch') {
                if ($null -ne $InputObject.InputObject) {
                    $Script = {
                        Patch-Mga -URL $InputObject.URL -InputObject $InputObject.InputObject
                    }
                }
                else {
                    $Script = {
                        Patch-Mga -URL $InputObject.URL
                    }
                }
            }
        }
        $ScriptBlock = [ScriptBlock]::Create($ScriptStart.ToString() + $ScriptTry + $Script + $ScriptThrow)
    }
    process {
        if ($null -eq $global:MgaJobs) {
            $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
            $RunspacePool.ApartmentState = [System.Threading.ApartmentState]::MTA  
            $RunspacePool.Open()
            $global:MgaJobs = [System.Collections.Generic.List[Object]]::new()
        }
        $PowerShell = [powershell]::Create()
        $PowerShell.RunspacePool = $RunspacePool
        [void]$PowerShell.AddScript($ScriptBlock)
        [void]$PowerShell.AddParameters($ParamsList)
        [void]$PowerShell.AddParameter('MgaThrottleHit', $global:MgaThrottleHit)
        $Job = $PowerShell.BeginInvoke()
        $Object = [PSCustomObject]@{
            Job        = $Job
            PowerShell = $PowerShell
        }
        $global:MgaJobs.Add($Object) 
    }   
    end {
        foreach ($Job in $global:MgaJobs | Where-Object { $_.Job.IsCompleted -eq 'True' }) {
            $Return = $Job.PowerShell.EndInvoke($Job.Job)
            [void]$Job.PowerShell.Dispose()
            return $Return
        }
    }
}
#endregion experimental
#region internal
function Initialize-MgaConnect {
    [CmdletBinding()]
    param (
    )
    if ($global:MgaLoginType.length -ge 1) {
        Write-Verbose "Initialize-MgaConnect: You're already logged on."
        $Confirmation = Read-Host 'You already logged on. Are you sure you want to proceed? Type (Y)es to continue.'
        if (($Confirmation -eq 'y') -or ($Confirmation -eq 'yes') -or ($Confirmation -eq 'true') -or ($Confirmation -eq '(Y)es')) {
            Write-Verbose "Initialize-MgaConnect: We will continue logging in."
            $null = Disconnect-Mga
        }
        else {
            Write-Verbose "Initialize-MgaConnect: Aborting log in."
            throw 'Login aborted.'
        }
    }
}

function Update-MgaOauthToken {  
    [CmdletBinding()]
    param (
    )
    if ($null -ne $global:MgaAppPass) {
        Receive-MgaOauthToken `
            -ApplicationID $global:MgaApplicationID `
            -Tenant $global:MgaTenant `
            -ClientSecret $global:MgaSecret
    }
    elseif ($null -ne $global:MgaCert) {
        Receive-MgaOauthToken `
            -ApplicationID $global:MgaApplicationID `
            -Tenant $global:MgaTenant `
            -Certificate $global:MgaCertificate
    }
    elseif ($null -ne $global:MgaTPrint) {
        Receive-MgaOauthToken `
            -ApplicationID $global:MgaApplicationID `
            -Tenant $global:MgaTenant `
            -Thumbprint $global:MgaThumbprint 
    }
    elseif ($null -ne $global:MgaRU) {
        Receive-MgaOauthToken `
            -ApplicationID $global:MgaApplicationID `
            -Tenant $global:MgaTenant `
            -RedirectUri $global:MgaRedirectUri 
           # -LoginScope $global:MgaLoginScope
    }
    elseif ($null -ne $global:MgaBasic) {
        Receive-MgaOauthToken `
            -ApplicationID $global:MgaApplicationID `
            -Tenant $global:MgaTenant `
            -UserCredentials $global:MgaUserCredentials 
    }
    else {
        Throw "You need to run Connect-Mga before you can continue. Exiting script..."
    }
}

function Receive-MgaOauthToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ApplicationID,
        [Parameter(Mandatory = $true)]
        [string]
        $Tenant,
        [Parameter(Mandatory = $true, ParameterSetName = 'Thumbprint')]
        [string]
        $Thumbprint, 
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        $Certificate, 
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        $ClientSecret, 
        [Parameter(Mandatory = $true, ParameterSetName = 'Redirecturi')]
        [string]
        $RedirectUri,
        [Parameter(Mandatory = $false, ParameterSetName = 'Redirecturi')]
        [AllowEmptyString()]  
        [Object]
        $LoginScope,
        [Parameter(Mandatory = $true, ParameterSetName = 'UserCredentials')]
        [System.Net.ICredentials]
        $UserCredentials
    )
    begin {
        try { 
            $global:MgaTenant = $Tenant
            $global:MgaApplicationID = $ApplicationID
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
                Write-Verbose "Receive-MgaOauthToken: Certificate: We will continue logging in with Certificate."
                if (($null -eq $global:MgaTPCertificate) -or ($Thumbprint -ne ($global:MgaTPCertificate).Thumbprint)) {
                    Write-Verbose "Receive-MgaOauthToken: Certificate: Starting search in CurrentUser\my."
                    $TPCertificate = Get-Item Cert:\CurrentUser\My\$Thumbprint -ErrorAction SilentlyContinue
                    if ($null -eq $TPCertificate) {
                        Write-Verbose "Receive-MgaOauthToken: Certificate not found in CurrentUser. Continuing in LocalMachine\my."
                        $TPCertificate = Get-Item Cert:\localMachine\My\$Thumbprint -ErrorAction SilentlyContinue
                    }
                    if ($null -eq $TPCertificate) {
                        throw "We did not find a certificate under: $Thumbprint. Exiting script..."
                    }
                }
                else {
                    $TPCertificate = $global:MgaTPCertificate
                    Write-Verbose "Receive-MgaOauthToken: Certificate: We already obtained a certificate from a previous login. We will continue logging in."
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
                $TempPass = [PSCredential]::new(".", $Secret).GetNetworkCredential().Password
                if (!($global:MgaAppPass)) {
                    Write-Verbose "Receive-MgaOauthToken: ApplicationSecret: This is the first time logging in with a ClientSecret."
                    $Builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($ApplicationID).WithTenantId($Tenant).WithClientSecret($TempPass).Build()
                    $global:MgaAppPass = $Builder.AcquireTokenForClient($LoginScope).ExecuteAsync()
                    if ($null -eq $global:MgaAppPass.result.AccessToken) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $global:MgaheaderParameters = @{
                            Authorization = $global:MgaAppPass.result.CreateAuthorizationHeader()
                        }
                        $global:MgaLoginType = 'ClientSecret'
                        $global:MgaSecret = $Secret
                    }
                }
                else {
                    Write-Verbose "Receive-MgaOauthToken: ApplicationSecret: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Receive-MgaOauthToken: ApplicationSecret: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $global:MgaAppPass.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose "Receive-MgaOauthToken: ApplicationSecret: Oauth token expired. Emptying Oauth variable and re-running function."
                        $global:MgaAppPass = $null
                        Receive-MgaOauthToken `
                            -ApplicationID $ApplicationID `
                            -Tenant $Tenant `
                            -ClientSecret $ClientSecret           
                    }
                    else {
                        Write-Verbose "Receive-MgaOauthToken: ApplicationSecret: Oauth token from last run is still active."
                    }
                }
            }
            elseif ($Certificate) {
                if (!($global:MgaCert)) {
                    Write-Verbose "Receive-MgaOauthToken: Certificate: This is the first time logging in with a Certificate."
                    $Builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($ApplicationID).WithTenantId($tenant).WithCertificate($Certificate).Build()  
                    $global:MgaCert = $Builder.AcquireTokenForClient($LoginScope).ExecuteAsync()
                    if ($null -eq $global:MgaCert.result.AccessToken) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $global:MgaheaderParameters = @{
                            Authorization = $global:MgaCert.result.CreateAuthorizationHeader()
                        }
                        $global:MgaLoginType = 'Certificate'
                        $global:MgaCertificate = $Certificate
                    }
                }
                else {
                    Write-Verbose "Receive-MgaOauthToken: Certificate: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Receive-MgaOauthToken: Certificate: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $global:MgaCert.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose "Receive-MgaOauthToken: Certificate: Oauth token expired. Emptying Oauth variable and re-running function."
                        $global:MgaCert = $null
                        Receive-MgaOauthToken `
                            -ApplicationID $ApplicationID `
                            -Certificate $Certificate `
                            -Tenant $Tenant
                    }
                    else {
                        Write-Verbose "Receive-MgaOauthToken: Certificate: Oauth token from last run is still active."
                    }
                }
            }
            elseif ($Thumbprint) {
                if (!($global:MgaTPrint)) {
                    Write-Verbose "Receive-MgaOauthToken: Certificate: This is the first time logging in with a Certificate."
                    $Builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($ApplicationID).WithTenantId($tenant).WithCertificate($TPCertificate).Build()  
                    $global:MgaTPrint = $Builder.AcquireTokenForClient($LoginScope).ExecuteAsync()
                    if ($null -eq $global:MgaTPrint.result.AccessToken) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $global:MgaheaderParameters = @{
                            Authorization = $global:MgaTPrint.result.CreateAuthorizationHeader()
                        }
                        $global:MgaLoginType = 'Thumbprint'
                        $global:MgaThumbprint = $Thumbprint
                        $global:MgaTPCertificate = $TPCertificate
                    }
                }
                else {
                    Write-Verbose "Receive-MgaOauthToken: Certificate: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Receive-MgaOauthToken: Certificate: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $global:MgaTPrint.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose "Receive-MgaOauthToken: Certificate: Oauth token expired. Emptying Oauth variable and re-running function."
                        $global:MgaTPrint = $null
                        Receive-MgaOauthToken `
                            -ApplicationID $ApplicationID `
                            -Thumbprint $Thumbprint `
                            -Tenant $Tenant
                    }
                    else {
                        Write-Verbose "Receive-MgaOauthToken: Certificate: Oauth token from last run is still active."
                    }
                }
            }
            elseif ($RedirectUri) { 
                if (!($global:MgaRU)) {
                    $Builder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ApplicationID).WithTenantId($Tenant).WithRedirectUri($RedirectUri).Build()
                    $global:MgaRU = $Builder.AcquireTokenInteractive($LoginScope).ExecuteAsync()
                    if ($null -eq $global:MgaRU.result.AccessToken) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $global:MgaheaderParameters = @{
                            Authorization = $global:MgaRU.Result.CreateAuthorizationHeader()
                        }
                        $global:MgaLoginType = 'RedirectUri'
                        $global:MgaRedirectUri = $RedirectUri
                        $global:MgaLoginScope = $LoginScope
                    }
                }
                else {
                    Write-Verbose "Receive-MgaOauthToken: MFA UserCredentials: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Receive-MgaOauthToken: MFA UserCredentials: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $global:MgaRU.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose "Receive-MgaOauthToken: MFA UserCredentials: Oauth token expired. Emptying Oauth variable and re-running function."
                        $global:MgaRU = $null
                        Receive-MgaOauthToken `
                            -ApplicationID $ApplicationID `
                            -Tenant $Tenant `
                            -RedirectUri $RedirectUri `
                            -LoginScope $LoginScope
                    }
                    else {
                        Write-Verbose "Receive-MgaOauthToken: MFA UserCredentials: Oauth token from last run is still active."
                    }
                }
            }
            elseif ($userCredentials) {
                $loginURI = "https://login.microsoft.com"
                $Resource = "https://graph.microsoft.com"
                $Body = @{
                    grant_type = 'password';
                    resource   = $Resource;
                    username   = $($userCredentials.UserName)
                    password   = $($UserCredentials.Password)
                    client_id  = $ApplicationID;
                    scope      = 'openid'
                }
                if (!($global:MgaBasic)) {
                    $global:MgaBasic = Invoke-RestMethod -Method Post -Uri $loginURI/$Tenant/oauth2/token?api-version=1.0 -Body $Body -UseBasicParsing
                    if ($null -eq $global:MgaBasic.access_token) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $global:MgaheaderParameters = @{
                            Authorization = "$($global:MgaBasic.token_type) $($global:MgaBasic.access_token)"
                        }
                        $global:MgaLoginType = 'UserCredentials'
                        $global:MgaUserCredentials = $UserCredentials
                    }
                }
                else {
                    Write-Verbose "Receive-MgaOauthToken: Basic UserCredentials: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Receive-MgaOauthToken: Basic UserCredentials: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $UnixDateTime.AddSeconds($global:MgaBasic.expires_on)
                    if ($null -ne $global:MgaBasic.refresh_token) {
                        Write-Verbose "Receive-MgaOauthToken: "
                        $Body = @{
                            refresh_token = $global:MgaBasic.refresh_token
                            grant_type    = 'refresh_token'
                        }
                        $global:MgaBasic = Invoke-RestMethod -Method Post -Uri $loginURI/$Tenant/oauth2/token?api-version=1.0 -Body $Body -UseBasicParsing
                        if ($null -eq $global:MgaBasic.access_token) {
                            Write-Warning 'We did not retrieve an Oauth access token from the refresh_token. Re-trying to log in with new token.'
                        }
                        else {
                            $global:MgaheaderParameters = @{
                                Authorization = "$($global:MgaBasic.token_type) $($global:MgaBasic.access_token)"
                            }
                            $global:MgaLoginType = 'UserCredentials'
                            $global:MgaUserCredentials = $UserCredentials
                        }
                    }
                    if ($OauthExpiryTime -le $UTCDate) {
                        $global:MgaBasic = $null
                        Receive-MgaOauthToken `
                            -UserCredentials $UserCredentials `
                            -Tenant $Tenant `
                            -ApplicationID $ApplicationID
                    }
                    else {
                        Write-Verbose "Receive-MgaOauthToken: Basic UserCredentials: Oauth token from last run is still active."
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
            foreach ($Line in $InputObject."members@odata.bind") {
                $GroupedInputObject.Add($Line)
                if ($($GroupedInputObject).count -eq 20) {
                    $GroupedInputObject = [PSCustomObject] @{
                        "members@odata.bind" = $GroupedInputObject
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
            if ($InputObject."members@odata.bind") {
                foreach ($Line in $InputObject."members@odata.bind") {
                    $GroupedInputObject.Add($Line)
                    if ($($GroupedInputObject).count -eq 20) {
                        $OdataBind = [PSCustomObject] @{
                            "members@odata.bind" = $GroupedInputObject
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
                        "members@odata.bind" = $GroupedInputObject
                    }
                }
                else {
                    $GroupedInputObject = [PSCustomObject] @{
                        "@odata.id" = $GroupedInputObject
                    }
                }
                Patch-Mga -InputObject $GroupedInputObject -URL $URL

            }
            if ($Request -eq 'Delete-Mga') {
                Write-Verbose 'Optimize-Mga: Batching last Delete-Mga.'
                if ($InputObject."members@odata.bind") {   
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
#endregion internal