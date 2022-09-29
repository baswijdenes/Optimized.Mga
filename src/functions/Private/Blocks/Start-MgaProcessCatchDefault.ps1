function Start-MgaProcessCatchDefault {
    param (
        $Api,
        $UpdateMgaUriApi,
        $Result,
        $Uri,
        $Throw
    )
    try {
        if ($Uri.count -eq 1) {        
            if (($Api -eq 'All') -and ($UpdateMgaUriApi.Api -eq 'v1.0')) {
                Write-Verbose "No results found for the v1.0 Api. Trying the beta Api..."
                #$Uri = Update-MgaUriApi -Uri $Uri -Api 'Beta'
                #Build-MgaUri -Uri $Uri -Api 'Beta'
            }
            else {
                if ($Result.'@odata.nextLink') {
                    $Uri = $Result.'@odata.nextLink'
                }
                Trace-MgaCatch -Throw $Throw
            }
        }
        else {
            Trace-MgaCatch -Throw $Throw
        }
        return [PSCustomObject]@{
            Uri = $Uri
        }
    }
    catch {
        throw $_
    }
}