<# START USER FUNCTIONS #>
function Connect-Mga {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Thumbprint')]
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
        [Parameter(Mandatory = $false, ParameterSetName = 'RedirectUri')]
        [AllowEmptyString()]  
        [Object]
        $LoginScope,
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
                -AppID $ApplicationID `
                -Tenant $Tenant `
                -Thumbprint $Thumbprint 
        }
        elseif ($Certificate) {
            Write-Verbose "Connect-Mga: Certificate: Logging in with certificate."
            Receive-MgaOauthToken `
                -AppID $ApplicationID `
                -Tenant $Tenant `
                -Certificate $Certificate 
        }
        elseif ($ClientSecret) {
            Write-Verbose "Connect-Mga: RedirectUri: Logging in with RedirectUri."
            Receive-MgaOauthToken `
                -AppID $ApplicationID `
                -Tenant $Tenant `
                -ClientSecret $ClientSecret
        }
        elseif ($RedirectUri) {
            Write-Verbose "Connect-Mga: MFA UserCredentials: Logging in with MFA UserCredentials."
            Receive-MgaOauthToken `
                -AppID $ApplicationID `
                -Tenant $Tenant `
                -RedirectUri $RedirectUri `
                -LoginScope $LoginScope
        }
        elseif ($UserCredentials) {
            Write-Verbose "Connect-Mga: Basic UserCredentials: Logging in with Basic UserCredentials."
            Receive-MgaOauthToken `
                -AppID $ApplicationID `
                -Tenant $Tenant `
                -UserCredentials $UserCredentials 
        }
    }
    end {
        return "You've successfully logged in to Microsoft.Graph.API."
    }
}

function Disconnect-Mga {
    [CmdletBinding()]
    param (
    )
    begin {
        Write-Verbose "Disconnect-Mga: Disconnecting from Microsoft.Graph.API."
    }
    process {
        try {
            $global:GLTenant = $null
            $global:GLApplicationID = $null
            $global:GLheaderParameters = $null
            $Global:LoginType = $null
            $global:GLAppPass = $null
            $global:GLTPrint = $null
            $global:GLRU = $null
            $global:GLBasic = $null
            $global:GLTPCertificate = $null
            $global:GLCertificate = $null
            $global:GLCert = $null
            $global:GLSecret = $null
            $global:GLThumbprint = $null
            $global:GLRedirectUri = $null
            $global:GLLoginScope = $null
            $global:GLUserCredentials = $null
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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
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
            $Result = Invoke-WebRequest -UseBasicParsing -Headers $global:GLHeaderParameters -Uri $URL -Method get
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
                            $Result = (Invoke-WebRequest -UseBasicParsing -Headers $HeaderParameters -Uri $Result.'@odata.nextLink' -Method Get).Content | ConvertFrom-Json
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
        return $EndResult
    }
}

function Post-Mga {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
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
                $Result = Invoke-RestMethod -Uri $URL -Headers $global:GLheaderParameters -Method post -Body $InputObject -ContentType application/json
            }
            else {
                $Result = Invoke-RestMethod -Uri $URL -Headers $global:GLheaderParameters -Method post -ContentType application/json    
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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
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
                $Result = Invoke-RestMethod -Uri $URL -Headers $global:GLheaderParameters -Method Patch -Body $InputObject -ContentType application/json
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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
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
                $Result = Invoke-RestMethod -Uri $URL -body $InputObject -Headers $global:GLheaderParameters -Method Delete -ContentType application/json
            }
            else {
                Write-Verbose "Delete-Mga: Deleting conent on $URL to Microsoft.Graph.API."
                $Result = Invoke-RestMethod -Uri $URL -Headers $global:GLheaderParameters -Method Delete -ContentType application/json
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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $To,
        [Parameter(Mandatory = $true)]
        [string]
        $Subject,
        [Parameter(Mandatory = $true)]
        [string]
        $Body,
        [Parameter(Mandatory = $false)]
        [string]
        $From
    )
    begin {
        try {
            Write-Verbose "Send-MgaMail: To address is $To."
            Write-Verbose "Send-MgaMail: Subject is $Subject."
            $Message = [PSCustomObject] @{
                message = [PSCustomObject] @{
                    subject      = $subject
                    body         = [PSCustomObject] @{
                        contentType = 'HTML'
                        content     = $body
                    }
                    toRecipients = @([PSCustomObject] @{
                            emailAddress = [PSCustomObject] @{
                                'address' = $To
                            }
                        })
                }
            }
            if ($null -ne $From) {
                Write-Verbose "Send-MgaMail: From address is $From."
                $FromNode = [PSCustomObject] @{
                    emailAddress = [PSCustomObject] @{
                        'address' = $From
                    }
                }
                $Message | Add-Member -MemberType NoteProperty -Name From -Value $FromNode
            }
            $URL = 'https://graph.microsoft.com/v1.0/me/sendMail'
            if ($null -ne $From) {
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
<# END USER FUNCTIONS #>
<# START INTERNAL FUNCTIONS #>
function Initialize-MgaConnect {
    [CmdletBinding()]
    param (
    )
    if ($Global:LoginType) {
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
    if ($null -ne $global:GLAppPass) {
        Receive-MgaOauthToken `
            -AppID $global:GLApplicationID `
            -Tenant $global:GLTenant `
            -ClientSecret $global:GLSecret
    }
    elseif ($null -ne $global:GLCert) {
        Receive-MgaOauthToken `
            -AppID $global:GLApplicationID `
            -Tenant $global:GLTenant `
            -Certificate $global:GLCertificate
    }
    elseif ($null -ne $global:GLTPrint) {
        Receive-MgaOauthToken `
            -AppID $global:GLApplicationID `
            -Tenant $global:GLTenant `
            -Thumbprint $global:GLThumbprint 
    }
    elseif ($null -ne $global:GLRU) {
        Receive-MgaOauthToken `
            -AppID $global:GLApplicationID `
            -Tenant $global:GLTenant `
            -RedirectUri $global:GLRedirectUri `
            -LoginScope $global:GLLoginScope
    }
    elseif ($null -ne $global:GLBasic) {
        Receive-MgaOauthToken `
            -AppID $global:GLApplicationID `
            -Tenant $global:GLTenant `
            -UserCredentials $global:GLUserCredentials 
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
        $AppID,
        [Parameter(Mandatory = $true)]
        [string]
        $Tenant,
        [Parameter(Mandatory = $true, ParameterSetName = 'Thumbprint')]
        [string]
        $Thumbprint, 
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        $Certificate, 
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [string]
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
            $global:GLTenant = $Tenant
            $global:GLApplicationID = $AppID
            if ($null -eq $LoginScope) {
                [System.Collections.Generic.List[String]]$LoginScope = @('https://graph.microsoft.com/.default')
            }
            else {
                $Data = @('https://graph.microsoft.com/')
                foreach ($Scp in $LoginScope) {
                    $Data += $Scp
                }
                [System.Collections.Generic.List[String]]$LoginScope = ([string]$Data).replace('/ ', '/')
            }
            [datetime]$UnixDateTime = '1970-01-01 00:00:00'
            $Date = Get-Date
            $UTCDate = [System.TimeZoneInfo]::ConvertTimeToUtc($Date)
            if ($thumbprint.length -gt 5) { 
                Write-Verbose "Receive-MgaOauthToken: Certificate: We will continue logging in with Certificate."
                if (($null -eq $global:GLTPCertificate) -or ($Thumbprint -ne ($global:GLTPCertificate).Thumbprint)) {
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
                    $TPCertificate = $global:GLTPCertificate
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
                if ($ClientSecret -ne 'System.Security.SecureString') {
                    $Secret = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force
                }
                $TempPass = [PSCredential]::new(".", $Secret).GetNetworkCredential().Password
                if (!($global:GLAppPass)) {
                    Write-Verbose "Receive-MgaOauthToken: ApplicationSecret: This is the first time logging in with a ClientSecret."
                    $Builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($ApplicationID).WithTenantId($Tenant).WithClientSecret($TempPass).Build()
                    $global:GLAppPass = $Builder.AcquireTokenForClient($LoginScope).ExecuteAsync()
                    if ($null -eq $global:GLAppPass.result.AccessToken) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $global:GLheaderParameters = @{
                            Authorization = "Bearer $($global:GLAppPass.result.AccessToken)"
                        }
                        $Global:LoginType = 'ClientSecret'
                        $global:GLSecret = $Secret
                    }
                }
                else {
                    Write-Verbose "Receive-MgaOauthToken: ApplicationSecret: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Receive-MgaOauthToken: ApplicationSecret: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $global:GLAppPass.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose "Receive-MgaOauthToken: ApplicationSecret: Oauth token expired. Emptying Oauth variable and re-running function."
                        $global:GLAppPass = $null
                        Receive-MgaOauthToken `
                            -AppID $ApplicationID `
                            -Tenant $Tenant `
                            -ClientSecret $ClientSecret           
                    }
                    else {
                        Write-Verbose "Receive-MgaOauthToken: ApplicationSecret: Oauth token from last run is still active."
                    }
                }
            }
            elseif ($Certificate) {
                if (!($global:GLCert)) {
                    Write-Verbose "Receive-MgaOauthToken: Certificate: This is the first time logging in with a Certificate."
                    $Builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($AppID).WithTenantId($tenant).WithCertificate($Certificate).Build()  
                    $global:GLCert = $Builder.AcquireTokenForClient($LoginScope).ExecuteAsync()
                    if ($null -eq $global:GLCert.result.AccessToken) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $global:GLheaderParameters = @{
                            Authorization = "Bearer $($global:GLCert.result.AccessToken)"
                        }
                        $Global:LoginType = 'Certificate'
                        $global:GLCertificate = $Certificate
                    }
                }
                else {
                    Write-Verbose "Receive-MgaOauthToken: Certificate: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Receive-MgaOauthToken: Certificate: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $global:GLCert.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose "Receive-MgaOauthToken: Certificate: Oauth token expired. Emptying Oauth variable and re-running function."
                        $global:GLCert = $null
                        Receive-MgaOauthToken `
                            -AppID $ApplicationID `
                            -Certificate $Certificate `
                            -Tenant $Tenant
                    }
                    else {
                        Write-Verbose "Receive-MgaOauthToken: Certificate: Oauth token from last run is still active."
                    }
                }
            }
            elseif ($Thumbprint) {
                if (!($global:GLTPrint)) {
                    Write-Verbose "Receive-MgaOauthToken: Certificate: This is the first time logging in with a Certificate."
                    $Builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($AppID).WithTenantId($tenant).WithCertificate($TPCertificate).Build()  
                    $global:GLTPrint = $Builder.AcquireTokenForClient($LoginScope).ExecuteAsync()
                    if ($null -eq $global:GLTPrint.result.AccessToken) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $global:GLheaderParameters = @{
                            Authorization = "Bearer $($global:GLTPrint.result.AccessToken)"
                        }
                        $Global:LoginType = 'Thumbprint'
                        $global:GLThumbprint = $Thumbprint
                        $global:GLTPCertificate = $TPCertificate
                    }
                }
                else {
                    Write-Verbose "Receive-MgaOauthToken: Certificate: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Receive-MgaOauthToken: Certificate: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $global:GLTPrint.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose "Receive-MgaOauthToken: Certificate: Oauth token expired. Emptying Oauth variable and re-running function."
                        $global:GLTPrint = $null
                        Receive-MgaOauthToken `
                            -AppID $ApplicationID `
                            -Thumbprint $Thumbprint `
                            -Tenant $Tenant
                    }
                    else {
                        Write-Verbose "Receive-MgaOauthToken: Certificate: Oauth token from last run is still active."
                    }
                }
            }
            elseif ($RedirectUri) { 
                if (!($global:GLRU)) {
                    $Builder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ApplicationID).WithTenantId($Tenant).WithRedirectUri($RedirectUri).Build()
                    $global:GLRU = $Builder.AcquireTokenInteractive($LoginScope).ExecuteAsync()
                    if ($null -eq $global:GLRU.result.AccessToken) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $global:GLheaderParameters = @{
                            Authorization = "Bearer $($global:GLRU.result.AccessToken)"
                        }
                        $global:GLLoginType = 'RedirectUri'
                        $global:GLRedirectUri = $RedirectUri
                        $global:GLLoginScope = $LoginScope
                    }
                }
                else {
                    Write-Verbose "Receive-MgaOauthToken: MFA UserCredentials: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Receive-MgaOauthToken: MFA UserCredentials: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $global:GLRU.Result.ExpiresOn.UtcDateTime
                    if ($OauthExpiryTime -le $UTCDate) {
                        Write-Verbose "Receive-MgaOauthToken: MFA UserCredentials: Oauth token expired. Emptying Oauth variable and re-running function."
                        $global:GLRU = $null
                        Receive-MgaOauthToken `
                            -AppID $ApplicationID `
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
                    client_id  = $AppID;
                    scope      = 'openid'
                }
                if (!($global:GLBasic)) {
                    $global:GLBasic = Invoke-RestMethod -Method Post -Uri $loginURI/$Tenant/oauth2/token?api-version=1.0 -Body $Body -UseBasicParsing
                    if ($null -eq $global:GLBasic.access_token) {
                        throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                    }
                    else {
                        $global:GLheaderParameters = @{
                            Authorization = "$($global:GLBasic.token_type) $($global:GLBasic.access_token)"
                        }
                        $global:GLLoginType = 'UserCredentials'
                        $global:GLUserCredentials = $UserCredentials
                    }
                }
                else {
                    Write-Verbose "Receive-MgaOauthToken: Basic UserCredentials: Oauth token already exists from previously running cmdlets."
                    Write-Verbose "Receive-MgaOauthToken: Basic UserCredentials: Running test to see if Oauth token expired."
                    $OauthExpiryTime = $UnixDateTime.AddSeconds($global:GLBasic.expires_on)
                    if ($OauthExpiryTime -le $UTCDate) {
                        $global:GLBasic = $null
                        Receive-MgaOauthToken `
                            -UserCredentials $UserCredentials `
                            -Tenant $Tenant `
                            -AppID $ApplicationID
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
<# END INTERNAL FUNCTIONS #>