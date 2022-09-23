function Enable-MgaCustomHeader {
    param (
        $CustomHeader
    )
    try {
        Write-Verbose 'Saving original header to custom variable'
        $Script:MgaSession.OriginalHeader = @{}
        foreach ($Header in $Script:MgaSession.HeaderParameters.GetEnumerator()) {
            $Script:MgaSession.OriginalHeader.Add($Header.Key, $Header.Value)
        }
        Write-Verbose 'Merging headers'
        foreach ($Header in $CustomHeader.GetEnumerator()) {
            if ($null -ne $Script:MgaSession.HeaderParameters[$Header.Key]) {
                $Script:MgaSession.HeaderParameters[$Header.Key] = $Header.Value
            }
            else {
                $Script:MgaSession.HeaderParameters.Add($Header.key, $Header.Value)
            }
        }  
    }
    catch {
        throw $_
    } 
}