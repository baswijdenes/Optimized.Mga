function Get-MgaHashTable {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/

    .LINK 
    https://baswijdenes.com/c/microsoft/mga/

    .SYNOPSIS
    Get the MgaSession HashTable in the script scope.
    
    .DESCRIPTION
    With this cmdlet you can check if the Mga HashTable contains the information that it should contain.

    .PARAMETER Property
    Leave empty to see all Propertys, or name the Property you'd like to see.
    
    .EXAMPLE
    Get-MgaHashTable

    .EXAMPLE
    Get-MgaHashTable -Property HeaderParameter
    #>
    [CmdletBinding()]
    param (
        [parameter(mandatory = $false)]
        [Alias('Variable')]
        [string]
        $Property = 'All' 
    )
    begin {
    } 
    process {
        try {
            if ($Property -ne 'All') {
                $ReturnResult = $Script:MgaSession.$($Property)
            }
            else {
                $ReturnResult = $Script:MgaSession
            }
        }
        catch {
            throw $_
        }
    }
    end {
        return $ReturnResult
    }
}
