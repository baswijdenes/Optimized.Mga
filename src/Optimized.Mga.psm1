#region Import module
$Public = @( Get-ChildItem -Path $PSScriptRoot\functions\Public\*.ps1 -Recurse)
$Private = @( Get-ChildItem -Path $PSScriptRoot\functions\Private\*.ps1 -Recurse)
Foreach ($import in @($Public + $Private)) {
    Try {
        Write-Verbose "Importing $($Import.BaseName)"
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.BaseName): $_"
    }
}

#endregion Import module
#region Support old functions
try {
    Write-Verbose 'Writing older cmdlet names to alias list'
    New-Alias -Name 'Connect-Mga' -Value 'Get-MgaToken' -ErrorAction SilentlyContinue
    New-Alias -Name 'Disconnect-Mga' -Value 'Remove-MgaToken' -ErrorAction SilentlyContinue
    New-Alias -Name 'Show-MgaAccessToken' -Value 'Show-MgaToken' -ErrorAction SilentlyContinue
    New-Alias -Name 'Patch-Mga' -Value 'Set-Mga' -ErrorAction SilentlyContinue
    New-Alias -Name 'Put-Mga' -Value 'Add-Mga' -ErrorAction SilentlyContinue
    New-Alias -Name 'Post-Mga' -Value 'New-Mga' -ErrorAction SilentlyContinue
    New-Alias -Name 'Delete-Mga' -Value 'Remove-Mga' -ErrorAction SilentlyContinue
    New-Alias -Name 'Batch-Mga' -Value 'Group-Mga' -ErrorAction SilentlyContinue
    New-Alias -Name 'Get-MgaVariable' -Value 'Get-MgaHashTable' -ErrorAction SilentlyContinue
    New-Alias -Name 'Update-MgaVariable' -Value 'Update-MgaHashTable' -ErrorAction SilentlyContinue
}
catch {
    Write-Verbose 'Aliases already exists'
}
#endregion Support old functions
#region Export module
Export-ModuleMember -Function $Public.Basename -Alias *
#endregion Export module