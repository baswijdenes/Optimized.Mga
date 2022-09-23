function Start-MgaProcessCatchDefault {
    param (
        $Reference,
        $UpdateMgaUriReference,
        $Result,
        $Uri,
        $Throw
    )
    try {
        if ($Uri.count -eq 1) {        
            if (($Reference -eq 'All') -and ($UpdateMgaUriReference.Reference -eq 'v1.0')) {
                $UpdateMgaUriReference.Reference = 'beta'
                $Uri = Update-MgaUriReference @UpdateMgaUriReference
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