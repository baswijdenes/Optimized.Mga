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
    New-Alias -Name 'Connect-Mga' -Value 'Get-MgaToken'
    New-Alias -Name 'Disconnect-Mga' -Value 'Remove-MgaToken'
    New-Alias -Name 'Show-MgaAccessToken' -Value 'Show-MgaToken'
    New-Alias -Name 'Patch-Mga' -Value 'Set-Mga'
    New-Alias -Name 'Put-Mga' -Value 'Add-Mga'
    New-Alias -Name 'Post-Mga' -Value 'New-Mga'
    New-Alias -Name 'Delete-Mga' -Value 'Remove-Mga'
    New-Alias -Name 'Batch-Mga' -Value 'Group-Mga'
    New-Alias -Name 'Get-MgaVariable' -Value 'Get-MgaHashTable'
    New-Alias -Name 'Update-MgaVariable' -Value 'Update-MgaHashTable'
}
catch {
    Write-Verbose 'Aliases already exists'
}
#endregion Support old functions
#region Export module
Export-ModuleMember -Function $Public.Basename -Alias *
#endregion Export module