function Show-MgaToken {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/

    .LINK 
    https://baswijdenes.com/c/microsoft/mga/

    .SYNOPSIS
    Use this cmdlet to retrieve the AccessToken decoded.
    
    .DESCRIPTION
    Show-MgaToken is mainly used for troubleshooting permission errors to see which permissions are missing.
    
    .PARAMETER AccessToken
    By leaving parameter AccessToken empty, it will use the AccessToken from the MgaSession variable.
    You can also decode another AccessToken by using this parameter. 
    For example from the official Microsoft SDK PowerShell module or webbrowser.

    .PARAMETER Roles
    Use this Parameter to only see the roles in the AccessToken.
    
    .EXAMPLE
    Show-MgaToken 

    .EXAMPLE
    Show-MgaToken -Roles
    #>
    [CmdletBinding()]
    param (
        [parameter(mandatory = $false, Position = 0)]
        $AccessToken = ($Script:MgaSession.headerParameters).Authorization,
        [parameter(mandatory = $false)]
        [switch]
        $Roles
    )  
    begin {
        try {
            if ($AccessToken -like 'Bearer *') {
                Write-Verbose "Removing 'Bearer ' from token for formatting"
            }
            $AccessToken = ($AccessToken).Replace('Bearer ', '')
            $AccessTokenSplitted = $AccessToken.Split('.')
            $AccessTokenHeader = $AccessTokenSplitted[0].Replace('-', '+').Replace('_', '/')
            While ($AccessTokenHeader.Length % 4) {
                $AccessTokenHeader += '='
            }      
            $AccessTokenPayLoad = $AccessTokenSplitted.Split('.')[1].Replace('-', '+').Replace('_', '/')
            While ($AccessTokenPayLoad.Length % 4) {
                $AccessTokenPayLoad += '='
            }
        }
        catch {
            throw $_
        }
    }
    process {
        try {
            Write-Verbose 'Decoding Header to JSON'
            $AccessTokenHeaderJSON = [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($AccessTokenHeader))
            Write-Verbose 'Decoding PayLoad to JSON'
            $AccessTokenPayLoadJSON = [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($AccessTokenPayLoad))
            $AccessTokenHeaderUpdated = $AccessTokenHeaderJSON -replace '.$'
            $AccessTokenPayLoadUpdated = $AccessTokenPayLoadJSON -Replace '^.', ','
            $AccessTokenJson = $AccessTokenHeaderUpdated + $AccessTokenPayLoadUpdated
            Write-Verbose 'Converting from Json to EndResult'
            $AccessTokenEndResult = $AccessTokenJson | ConvertFrom-Json  
        }
        catch {
            throw $_
        }
    }  
    end {
        if ($Roles -eq $true) {
            return $AccessTokenEndResult.Roles
        }
        else {
            return $AccessTokenEndResult
        }
    }
}
