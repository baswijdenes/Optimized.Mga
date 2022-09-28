function Set-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/

    .LINK 
    https://baswijdenes.com/c/microsoft/mga/

    .SYNOPSIS
    Set-Mga is an Alias for the method Patch.

    .DESCRIPTION
    Updates an object in the Azure AD tenant with the Microsoft Graph API. 
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

    .PARAMETER Reference
    This is not a mandatory parameter. 
    By using v1.0 or beta it will always overwrite the value given in the Uri.
    By using All it will first try v1.0 in a try and catch. and when it jumps to the catch it will use the beta reference.

    .PARAMETER CustomHeader
    This not a not mandatory parameter, there is a default header containing application/json.
    By using this parameter you can add a custom header. The CustomHeader is reverted back to the original after the cmdlet has run.

    .PARAMETER Batch
    By using Batch you can patch multiple objects at once by using Batch-Mga. 
    This will only work for a body that has the members@odata.bind property.

    .EXAMPLE
    $users = Get-Mga 'https://graph.microsoft.com/v1.0/users'
    $UserList = [System.Collections.Generic.List[Object]]::new() 
    foreach ($User in $users)
    {
        $DirectoryObject = "https://graph.microsoft.com/v1.0/directoryObjects/$($User.id)"
        $UserList.Add($DirectoryObject)
    }
    $Body = [PSCustomObject] @{
        "members@odata.bind" = $UserList
    }
    Set-Mga -Uri 'https://graph.microsoft.com/v1.0/groups/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -Body $Body                                                      
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('URL')]
        [string]
        $Uri,
        [Parameter(Mandatory = $true)]
        [Alias('InputObject')]
        [object]
        $Body,
        [Parameter(Mandatory = $false)]
        [switch]
        $Batch,
        [Parameter(Mandatory = $false)]
        [object]
        $CustomHeader
    )
    begin {
        try {
            $StartMgaBeginDefault = Start-MgaBeginDefault -CustomHeader $CustomHeader -Reference $Reference -Uri $Uri
            $Uri = $StartMgaBeginDefault.Uri
            $UpdateMgaUriReference = $StartMgaBeginDefault.UpdateMgaUriReference
            $ValidateJson = ConvertTo-MgaJson -Body $Body -Validate
        }
        catch {
            throw $_
        }
    }
    process {
        try {

            if (($ValidateJson -eq $false) -and (($Body.'members@odata.bind').count -gt 20)) {
                $GroupedInputObject = [system.Collections.Generic.List[system.Object]]::new()
                foreach ($Line in $Body.'members@odata.bind') {
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
                                Url    = $Uri
                                Body   = $GroupedInputObject
                            }
                            $PatchToBatch.Add($ToBatch)
                        }
                        else {
                            $EndResult += Set-Mga -Body $GroupedInputObject -URL $Uri
                        }
                        $GroupedInputObject = [system.Collections.Generic.List[system.Object]]::new()
                    }
                }
                if (($Batch -eq $true)) {
                    $EndResult = Batch-Mga -Body $PatchToBatch
                }
                elseif (-not([string]::IsNullOrEmpty($GroupedInputObject))) {
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
                    $EndResult += Set-Mga -Body $GroupedInputObject -URL $Uri
                }
            }
            else {
                $InvokeWebRequestSplat = @{
                    Headers         = $Script:MgaSession.HeaderParameters
                    Uri             = $Uri
                    Method          = 'Patch'
                    UseBasicParsing = $true
                }
                $Body = ConvertTo-MgaJson -Body $Body
                if ($Body) {
                    $InvokeWebRequestSplat.Body = $Body
                }
                $Result = Invoke-WebRequest @InvokeWebRequestSplat
                $EndResult = ConvertTo-MgaResult -Response $Result
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
            $EndResult += Set-Mga @MgaSplat
            $ReturnVerbose = $False
        }
    }
    end {
        Complete-MgaResult -Result $EndResult -CustomHeader $CustomHeader -ReturnVerbose $ReturnVerbose
    }
}