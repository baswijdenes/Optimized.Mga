function Invoke-Mga {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/

    .LINK 
    https://baswijdenes.com/c/microsoft/mga/

    .SYNOPSIS
    Invoke-Mga is a wrapper around the default Method cmdlets in the Mga module.
    
    .DESCRIPTION
    By using Invoke-Mga you do not have to change the way you use the default Method cmdlets in the Mga module.
    
    .PARAMETER Uri
    Uri to the Microsoft Graph API.
    You can also use the last part of an Uri and the rest will be automatically added.
    Example: /users
    Example: https://graph.microsoft.com/v1.0/users
    Example: users?$filter=displayName eq 'Bas Wijdenes'
    Example: beta/users
    
    .PARAMETER Body
    Body will accept a PSObject, or a Json string for Post, Patch, Put, and Delete.
    Body will accept an ArrayList for Batch.
    
    .PARAMETER Method
    Type of Method to the Microsoft Graph Endpoint.
    Methods are: Get, Post, Patch, Put, Delete, Batch.
    
    .PARAMETER Api
    This is not a mandatory parameter. 
    By using v1.0 or beta it will always overwrite the value given in the Uri.
    By using All it will first try v1.0 in a try and catch. and when it jumps to the catch it will use the beta Api.

    .EXAMPLE
    Invoke-Mga -Uri 'https://graph.microsoft.com/v1.0/users' -Method 'GET'

    .EXAMPLE 
    Invoke-Mga -Uri '/users' -Method 'Post' -Api 'beta' -Body $Body

    .EXAMPLE
    Invoke-Mga -Uri 'https://graph.microsoft.com/beta/groups' -Method 'Patch' -Api 'v1.0' -Body $Body

    .EXAMPLE
    Invoke-Mga -Uri 'beta/groups' -Method 'Delete' -Api 'All'

    .EXAMPLE
    Invoke-Mga -Method 'Batch' -Body $Body

    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Batch')]
        $Uri,
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Batch')]
        $Body,
        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Batch')]
        [ValidateSet('GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'BATCH')]
        $Method,
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [ValidateSet('All', 'v1.0', 'beta')]
        [Alias('Reference')]
        [string]$Api
    )
    begin {
        if ($Uri) {
            $InvokeSplat = @{
                Uri = $Uri  
            }
            if ($Body) {
                $InvokeSplat.Body = $Body
            }
            if ($Api) {
                $InvokeSplat.Api = $Api
            }
        }
    }
    process {
        try {
            switch ($Method) {
                'GET' {
                    $EndResult = Get-Mga @InvokeSplat
                }
                'POST' {
                    $EndResult = Post-Mga @InvokeSplat
                }
                'PATCH' {
                    $EndResult = Patch-Mga @InvokeSplat
                }
                'PUT' {
                    $EndResult = Put-Mga @InvokeSplat
                }
                'DELETE' {
                    $EndResult = Delete-Mga @InvokeSplat 
                } 
                'BATCH' {
                    $EndResult = Batch-Mga -Body $Body
                }
                default {
                    throw "Invalid method: $Method"
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