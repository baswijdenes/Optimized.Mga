function Remove-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/

    .LINK 
    https://baswijdenes.com/c/microsoft/mga/

    .SYNOPSIS
    Remove-Mga is an Alias for the method Delete.

    .DESCRIPTION
    Removes an object in the Azure AD tenant with the Microsoft Graph API. 
    Json, XML, and CSV is converted to a PSObject.    

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
    
    .EXAMPLE
    Remove-Mga -Uri '/v1.0/users/12345678-1234-1234-1234-123456789012'

    $GroupMembers = Get-Mga -URL 'https://graph.microsoft.com/v1.0/groups/ac252320-4194-402f-8182-2d14e4a2db5c/members'
    $UserList = @()
    foreach ($Member in $GroupMembers) {
        $Uri = "https://graph.microsoft.com/v1.0/groups/ac252320-4194-402f-8182-2d14e4a2db5c/members/$($Member.Id)/`$ref"
        $UserList += $Uri
    }
    
    .EXAMPLE
    Remove-Mga -Uri $UserList

    .EXAMPLE
    Remove-Mga -Uri '/v1.0/users/12345678-1234-1234-1234-123456789012' -Api 'All'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('URL')]
        [object]
        $Uri,
        [Parameter(Mandatory = $false)]
        [string]
        $Body,
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
            $UpdateMgaUriApi =  $StartMgaBeginDefault
            if ($Body) {
                $ValidateJson = ConvertTo-MgaJson -Body $Body -Validate
            }
            $InvokeWebRequestSplat = @{
                Headers         = $Script:MgaSession.HeaderParameters
                Method          = 'Delete'
                Uri             = $Uri
                UseBasicParsing = $true
            }
        }
        catch {
            throw $_
        }
    }
    process {
        try {
            $GroupedInputObject = [system.Collections.Generic.List[system.Object]]::new()
            if (($ValidateJson -eq $false) -and (($Body.'members@odata.bind').count -gt 20)) {
                foreach ($Line in $Body.'members@odata.bind') {
                    $GroupedInputObject.Add($Line)
                    if ($($GroupedInputObject).count -eq 20) {
                        $OdataBind = [PSCustomObject] @{
                            'members@odata.bind' = $GroupedInputObject
                        }
                        $EndResult += Remove-Mga -Body $OdataBind -URL $Uri 
                        $GroupedInputObject = [system.Collections.Generic.List[system.Object]]::new()
                    }
                }
            }
            elseif ($Uri.count -gt 1) {
                foreach ($Line in $Uri) {
                    $Object = [PSCustomObject]@{
                        url    = [string]$Line
                        method = 'Delete'
                    }
                    $GroupedInputObject.Add($Object)
                    if ($($GroupedInputObject).count -eq 20) {
                        $EndResult += Batch-Mga -Body $GroupedInputObject
                        $GroupedInputObject = [system.Collections.Generic.List[system.Object]]::new()
                    }
                }
            }
            else {
                if ($Body) {
                    $Body = ConvertTo-MgaJson -Body $Body
                    $InvokeWebRequestSplat.Body = $Body
                    $Result = Invoke-WebRequest @InvokeWebRequestSplat
                }
                else {
                    $Result = Invoke-WebRequest @InvokeWebRequestSplat
                }
                $EndResult = ConvertTo-MgaResult -Response $Result
            }
            if (-not([string]::IsNullOrEmpty($GroupedInputObject))) {
                if ($Body.'members@odata.bind') {   
                    $EndResult += -Body $OdataBind -URL $Uri 
                }
                else {
                    $EndResult += Batch-Mga -Body $GroupedInputObject
                }
            }
        }
        catch {
            $Uri = (Start-MgaProcessCatchDefault -Uri $Uri -Api $Api -UpdateMgaUriApi $UpdateMgaUriApi -Result $Result -Throw $_).Uri
            $MgaSplat = @{
                Uri = $Uri
                Api = 'Beta'
            }
            if ($Body) {
                $MgaSplat.Body = $Body
            }
            $EndResult += Remove-Mga @MgaSplat
            $ReturnVerbose = $False
        }
    }
    end {
        Complete-MgaResult -Result $EndResult -CustomHeader $CustomHeader -ReturnVerbose $ReturnVerbose
    }
}
