function Edit-MgaHashTable {
    <#
    .LINK
    https://github.com/baswijdenes/Optimized.Mga/

    .LINK 
    https://baswijdenes.com/c/microsoft/mga/

    .SYNOPSIS
    Edits properties in the MgaSession HashTable in the script scope.
    
    .DESCRIPTION
    This will mostly be for testing purposes, but you can also remove the Content-Type from the headerParameters properties.

    Not all properties will be overwritten since some are ReadOnly by default. 
    Keep in mind that by editing these properties the module can stop functioning.
    
    .PARAMETER Property
    This Parameter is mandatory & is the PropertyName.
    You can add several subproperties by using 'property1.subproperty.subproperty'
    
    .PARAMETER Body
    The body includes the content to overwrite the property with.
    
    .EXAMPLE
    Edit-MgaHashTable -Property 'HeaderParameters.Content-Type' -Body '(Get-Date).AddHours(-2)'
    #>
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        [Alias('Variable')]
        $Property,
        [parameter(mandatory = $true)]
        $Body
    )   
    begin {
    }
    process {
        $ObjectToTest = '$Script:MgaSession'
        if ($Property -like '*.*') {
            $Property = $Property.Split('.')
        } 
        $SB = [System.Text.StringBuilder]::new()
        foreach ($Prop in $Property) {
            if ($Prop -like '*-*') {
                $Prop = "'{0}'" -f $Prop
            }
            [void]$SB.Append($Prop + '.')
        }
        $commandParameter = $SB.ToString().TrimEnd('.')
        $Command = [string]::Format('{0}.{1} = "{2}"', $ObjectToTest, $commandParameter, $Body)
        $scriptBlock = [scriptblock]::Create($Command)
        $null = $scriptBlock.Invoke()
    }
    end {
        return "Updated $Property"
    }
} 