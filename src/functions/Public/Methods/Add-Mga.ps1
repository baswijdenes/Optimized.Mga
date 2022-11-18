function Add-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/

    .LINK 
    https://baswijdenes.com/c/microsoft/mga/

    .SYNOPSIS
    Add-Mga is an Alias for the method Put.

    .DESCRIPTION
    Creates a new object in the Azure AD tenant with the Microsoft Graph API.

    .PARAMETER Uri
    Uri to the Microsoft Graph API.
    You can also use the last part of an Uri and the rest will be automatically added.
    Example: /users
    Example: https://graph.microsoft.com/v1.0/users
    Example: users?$filter=displayName eq 'Bas Wijdenes'
    Example: beta/users

    .PARAMETER Body
    Body will accept a PSObject or a Json string.

    .PARAMETER Api
    This is not a mandatory parameter. 
    By using v1.0 or beta it will always overwrite the value given in the Uri.
    By using All it will first try v1.0 in a try and catch. and when it jumps to the catch it will use the beta Api.

    .PARAMETER CustomHeader
    This not a not mandatory parameter, there is a default header containing application/json.
    By using this parameter you can add a custom header. The CustomHeader is reverted back to the original after the cmdlet has run.

    .PARAMETER ReturnAsJson
    This is not a mandatory parameter. 
    By using, this the output will be returned as Json.
    When it cannot be converted to json, it will be returned as is.

    .NOTES
    The method Put is currently only used for uploading files to Sharepoint.
    Examples: https://baswijdenes.com/how-to-upload-files-to-sharepoint-with-ms-graph-api-and-powershell/
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('URL')]
        [string]$Uri,
        [Parameter(Mandatory = $false)]
        [Alias('InputObject')]
        [object]$Body,
        [Parameter(Mandatory = $false)]      
        [ValidateSet('All', 'v1.0', 'beta')]
        [Alias('Reference')]
        [string]$Api,
        [Parameter(Mandatory = $false)]
        [object]$CustomHeader,
        [Parameter(Mandatory = $false)]
        [switch]$ReturnAsJson
    )
    begin {
        try {
            $StartMgaBeginDefault = Start-MgaBeginDefault -CustomHeader $CustomHeader -Api $Api -Uri $Uri
            $Uri = $StartMgaBeginDefault.Uri
            $UpdateMgaUriApi =  $StartMgaBeginDefault
            elseif ($Uri -notlike '*/uploadSession*') {
                $Body = ConvertTo-MgaJson -Body $Body
            }
            $InvokeWebRequestSplat = @{
                Headers         = $Script:MgaSession.HeaderParameters
                Uri             = $Uri
                Method          = 'Put'
                UseBasicParsing = $true
            }
            if ($Body) {
                $InvokeWebRequestSplat.Body = $Body
            }
        }
        catch {
            throw $_
        }
    }
    process {
        try {
            $Result = Invoke-WebRequest @InvokeWebRequestSplat
            $EndResult = ConvertTo-MgaResult -Response $Result
            if ((-not($EndResult)) -and ($Api -eq 'All') -and ($UpdateMgaUriApi.Api -eq 'v1.0')) {
                Write-Warning 'No data found, trying again with -Api beta'
                throw $_
            }
        }
        catch {
            $StartMgaProcessCatchDefaultSplat = @{
                Uri                   = $Uri
                Api             = $Api
                UpdateMgaUriApi = $UpdateMgaUriApi
                Result                = $Result
                Throw                 = $_
            }
            $Uri = (Start-MgaProcessCatchDefault @StartMgaProcessCatchDefaultSplat).Uri
            $MgaSplat = @{
                Uri = $Uri
                Api = 'Beta'
            }
            if ($Body) {
                $MgaSplat.Body = $Body
            }
            $EndResult += Add-Mga @MgaSplat
            $ReturnVerbose = $False
        }
    }
    end {
        Complete-MgaResult -Result $EndResult -CustomHeader $CustomHeader -ReturnVerbose $ReturnVerbose -ReturnAsJson $ReturnAsJson
    }
}