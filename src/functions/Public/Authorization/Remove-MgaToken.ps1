function Remove-MgaToken {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/

    .LINK 
    https://baswijdenes.com/c/microsoft/mga/

    .SYNOPSIS
    Use Remove-MgaToken to remove the MgaSession HashTable from the Script scope.
    
    .DESCRIPTION
    To refresh the AccessToken, I use a Hashtable in the script scope with a number of properties. 
    The properties are emptied by Remove-MgaToken.
    
    .EXAMPLE
    Remove-MgaToken
    #>
    [CmdletBinding()]
    param (
    )
    begin {
        Write-Verbose 'Removing MgaSession Variable in Scope script'
    }
    process {
        try {
            $Null = Get-Variable -Name 'Mga*' -Scope Script | Remove-Variable -Force -Scope Script
        }
        catch {
            throw $_.Exception.Message
        }
    }
    end {
        return "MgaSession is removed"
    }
}