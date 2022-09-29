function Get-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/

    .LINK 
    https://baswijdenes.com/c/microsoft/mga/

    .SYNOPSIS
    Get-Mga is an Alias for the method Get.
    
    .DESCRIPTION
    Gets an object in the Azure AD tenant with the Microsoft Graph API. 
    Json, XML, and CSV is converted to a PSObject.    

    .PARAMETER Uri
    Uri to the Microsoft Graph API.
    You can also use the last part of an Uri and the rest will be automatically added.
    Example: /users
    Example: https://graph.microsoft.com/v1.0/users
    Example: users?$filter=displayName eq 'Bas Wijdenes'
    Example: beta/users

    .PARAMETER SkipNextLink
    When you use this switch it will only return the first data result of the response without checking the NextDataLink URL.

    .PARAMETER Api
    This is not a mandatory parameter. 
    By using v1.0 or beta it will always overwrite the value given in the Uri.
    By using All it will first try v1.0 in a try and catch. and when it jumps to the catch it will use the beta Api.

    .PARAMETER CustomHeader
    This not a not mandatory parameter, there is a default header containing application/json.
    By using this parameter you can add a custom header. The CustomHeader is reverted back to the original after the cmdlet has run.
    
    .EXAMPLE
    Get-Mga -Uri 'v1.0/users' -SkipNextLink

    .EXAMPLE
    Get-Mga -Uri 'users?$top=999'

    .EXAMPLE
    Get-Mga -Uri 'https://graph.microsoft.com/v1.0/users/Testuser@baswijdenes.com'

    .EXAMPLE
    $Uri = 'https://graph.microsoft.com/v1.0/users?$select=id,userPrincipalName,lastPasswordChangeDateTime,createdDateTime,PasswordPolicies'
    Get-Mga -Uri $Uri -Api 'All'

    .EXAMPLE
    $Uri = '/beta/users?$filter=(UserType eq 'Guest')&$select=displayName,userPrincipalName,createdDateTime,signInActivity'
    Get-Mga -Uri $Uri -Api 'v1.0'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('URL')]
        [string]
        $Uri,
        [Parameter(Mandatory = $false)]      
        [switch]
        [Alias('Once')]
        $SkipNextLink,
        [Parameter(Mandatory = $false)]      
        [ValidateSet('All', 'v1.0', 'beta')]
        [Alias('Reference')]
        [string]$Api,
        [Parameter(Mandatory = $false)]
        [object]
        $CustomHeader
    )
    begin {
        try {
            $StartMgaBeginDefault = Start-MgaBeginDefault -CustomHeader $CustomHeader -Api $Api -Uri $Uri
            $Uri = $StartMgaBeginDefault.Uri
            $UpdateMgaUriApi = $StartMgaBeginDefault
            $InvokeWebRequestSplat = @{
                Headers         = $Script:MgaSession.HeaderParameters
                Uri             = $Uri
                Method          = 'Get'
                UseBasicParsing = $true
            }
        }
        catch {
            throw $_
        }
    }
    process {
        try {
            $Result = Invoke-WebRequest @InvokeWebRequestSplat
            if ($result.Headers.'Content-Type' -like 'application/octet-stream;*') {
                Write-Verbose 'Converting response from CSV to PSObject'
                $EndResult = ConvertFrom-Csv -Body $Result
            }
            if ($result.Headers.'Content-Type' -like 'application/json;*') {   
                Write-Verbose 'Converting response from JSON to PSObject'
                $Result = ConvertFrom-Json -InputObject $Result
                $EndResult = @()
                $EndResult += ConvertTo-MgaResult -Response $Result
                if (-not($SkipNextLink)) {
                    While ($Result.'@odata.nextLink') {
                        Write-Verbose '@odata.nextLink property found, invoking again for more data'
                        Update-MgaOauthToken
                        $InvokeWebRequestSplat.Uri = $Result.'@odata.nextLink'
                        $Result = (Invoke-WebRequest @InvokeWebRequestSplat).Content | ConvertFrom-Json
                        $EndResult += ConvertTo-MgaResult -Response $Result
                    }
                }
            }
            if ((-not($EndResult)) -and ($Api -eq 'All') -and ($UpdateMgaUriApi.Api -eq 'v1.0')) {
                Write-Warning 'No data found, trying again with -Api beta'
                throw $_
            }
        }
        catch {
            $StartMgaProcessCatchDefaultSplat = @{
                Uri             = $Uri
                Api             = $Api
                UpdateMgaUriApi = $UpdateMgaUriApi
                Result          = $Result
                Throw           = $_
            }
            $Uri = (Start-MgaProcessCatchDefault @StartMgaProcessCatchDefaultSplat).Uri 
            $MgaSplat = @{
                Uri = $Uri
                Api = 'Beta'
            }
            if ($SkipNextLink) {
                $MgaSplat.SkipNextLink = $true
            }
            $EndResult += Get-Mga @MgaSplat
            $ReturnVerbose = $false
        }
    }
    end {
        Complete-MgaResult -Result $EndResult -CustomHeader $CustomHeader -ReturnVerbose $ReturnVerbose
    }
}