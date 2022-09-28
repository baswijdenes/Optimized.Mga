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

    .PARAMETER Reference
    This is not a mandatory parameter. 
    By using v1.0 or beta it will always overwrite the value given in the Uri.
    By using All it will first try v1.0 in a try and catch. and when it jumps to the catch it will use the beta reference.

    .PARAMETER CustomHeader
    This not a not mandatory parameter, there is a default header containing application/json.
    By using this parameter you can add a custom header. The CustomHeader is reverted back to the original after the cmdlet has run.

    .NOTES
    The method Put is currently only used for uploading files to Sharepoint.
    Examples: https://baswijdenes.com/how-to-upload-files-to-sharepoint-with-ms-graph-api-and-powershell/
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('URL')]
        [string]
        $Uri,
        [Parameter(Mandatory = $false)]
        [Alias('InputObject')]
        [object]
        $Body,
        [Parameter(Mandatory = $false)]      
        [string]
        [ValidateSet('All', 'v1.0', 'beta')]
        $Reference,
        [Parameter(Mandatory = $false)]
        [object]
        $CustomHeader
    )
    begin {
        try {
            $StartMgaBeginDefault = Start-MgaBeginDefault -CustomHeader $CustomHeader -Reference $Reference -Uri $Uri
            $Uri = $StartMgaBeginDefault.Uri
            $UpdateMgaUriReference = $StartMgaBeginDefault.UpdateMgaUriReference
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
            if ((-not($EndResult)) -and ($Reference -eq 'All') -and ($UpdateMgaUriReference.Reference -eq 'v1.0')) {
                Write-Warning 'No data found, trying again with -Reference beta'
                throw $_
            }
        }
        catch {
            $StartMgaProcessCatchDefaultSplat = @{
                Uri                   = $Uri
                Reference             = $Reference
                UpdateMgaUriReference = $UpdateMgaUriReference
                Result                = $Result
                Throw                 = $_
            }
            $Uri = (Start-MgaProcessCatchDefault @StartMgaProcessCatchDefaultSplat).Uri
            $MgaSplat = @{
                Uri = $Uri
            }
            if ($Body) {
                $MgaSplat.Body = $Body
            }
            $EndResult += Add-Mga @MgaSplat
            $ReturnVerbose = $False
        }
    }
    end {
        Complete-MgaResult -Result $EndResult -CustomHeader $CustomHeader -ReturnVerbose $ReturnVerbose
    }
}