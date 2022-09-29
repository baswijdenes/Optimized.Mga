function Group-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/

    .LINK 
    https://baswijdenes.com/c/microsoft/mga/

    .SYNOPSIS
    Group-Mga is for speed and bulk.
    See the related link for more.
    
    .DESCRIPTION
    Group-Mga will take care of the limitations (20 requests per batch) and will sleep for the amount of time a throttle limit is returned and then continue.

    .PARAMETER Body
    Body will accept an ArrayList.
    See the examples for more information.
    
    .PARAMETER Headers
    This not a not mandatory parameter, there is a default header containing application/json.
    You can manually change the header for the Batch, but this will change the header for all items in the ArrayList.
    
    .PARAMETER Beta
    Use this for when you want to use the beta Api. 
    By default it's v1.0.
    
    .EXAMPLE
    $Users = Get-Mga -URL 'https://graph.microsoft.com/v1.0/users?$top=999'
    $Batch = [System.Collections.Generic.List[Object]]::new()
    foreach ($User in $Users) {
        $Object = [PSCustomObject]@{
            url    = "/directory/deletedItems/$($User.id)"
            method = 'delete'
        }
        $Batch.Add($Object)
    }
    Group-Mga -Body $Batch

    .EXAMPLE
    $Batch = [System.Collections.Generic.List[Object]]::new()
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
    Group-Mga -Body $Batch
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('InputObject','Batch')]
        [object]
        $Body,
        [Parameter(Mandatory = $false)]
        [string]
        [Alias('CustomHeader')]
        $Headers,
        [Parameter(Mandatory = $false)]
        [switch]
        $Beta
    )
    begin {
        try {
            $ValidateJson = ConvertTo-MgaJson -Validate
            if ($Beta -eq $true) {
                $BatchUri = 'https://graph.microsoft.com/beta/$batch'
            }
            else {
                $BatchUri = 'https://graph.microsoft.com/v1.0/$batch'
            }
        }
        catch {
            throw $_
        }
    }
    process {
        try {
            if (($ValidateJson -eq $false) -and ($Body.count -gt 20)) {
                $ConvertedBody = [system.Collections.Generic.List[system.Object]]::new()
                foreach ($Line in $Body) {
                    $ConvertedBody.Add($Line)
                    if ($($ConvertedBody).count -eq 20) {
                        Write-Verbose "Batching $($ConvertedBody.count) requests"
                        $EndResult += Group-Mga -Body $ConvertedBody
                        $ConvertedBody = [system.Collections.Generic.List[system.Object]]::new()
                    }
                }
                if ($($ConvertedBody.count) -ge 1) {
                    $EndResult += Group-Mga -Body $ConvertedBody
                }
            }
            else {
                $i = 1
                $Batch = [System.Collections.Generic.List[System.Object]]::new()
                foreach ($Line in $Body) {
                    $Uri = $Line.Url -Replace 'https://graph.microsoft.com/' -Replace 'beta' -Replace 'v1.0'
                    if ($null -eq $Line.Header) {
                        $Header = @{
                            'Content-Type' = 'application/json'
                        }
                    }
                    else {
                        $Header = $Line.Header
                    }
                    $Hashtable = @{
                        id      = $i
                        Method  = ($Line.Method).ToUpper()
                        url     = $Uri
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
                    if ($i -eq $($Body.Count)) {
                        $EndBatch = [PSCustomObject]@{
                            Requests = $Batch
                        }
                    }
                    else {
                        $i++
                    }
                }
                $Results = Post-Mga -URL $BatchUri -Body $EndBatch
                $EndResult = [System.Collections.Generic.List[System.Object]]::new()
                :EndResults foreach ($result in $results.Responses) {
                    $Object = [PSCustomObject]@{
                        Id         = $Result.id
                        StatusCode = $Result.status
                        Body       = $Result.body
                    }
                    $EndResult.Add($Object)
                    if ($Object.body -like '*Your request is throttled temporarily.*') {
                        $ThrottleHit = $true
                        break :EndResults
                    }
                    if ([int]$Object.Status -match 429) {
                        $ThrottleHit = $true
                        break :EndResults
                    }
                }
                if ($ThrottleHit -eq $true) {
                    $ThrottleHit = $null
                    $ThrottleTime = $object.body -replace '[^0-9]' , ''
                    if ($null -eq $ThrottleTime) {
                        $ThrottleTime = 150
                    }
                    elseif ([string]::IsNullOrEmpty($ThrottleTime)) {
                        $ThrottleTime = 150
                    }
                    Write-Warning "Trace-MgaThrottle: Throttled for $ThrottleTime seconds"
                    Start-Sleep -Seconds ([int]$ThrottleTime + 1)
                    $Counter = $EndBatch.Requests.Count - $Object.id 
                    $RetryBatch = @{}
                    $RetryBatch.Add('Requests', ($endbatch.Requests | Sort-Object Id | Select-Object -Last $Counter)) 
                    $Results = Post-Mga -URL $URI -Body $RetryBatch
                    foreach ($result in $results.Responses) {
                        $Object = [PSCustomObject]@{
                            Id         = $Result.id
                            StatusCode = $Result.status
                            Body       = $Result.body
                        }
                        $EndResult.Add($Object)
                    }
                }
            }
        }
        catch {
            throw $_
        }
    }
    end {
        return $EndResult
    }
}