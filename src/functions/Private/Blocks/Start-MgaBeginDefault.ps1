function Start-MgaBeginDefault {
    param (
        $CustomHeader,
        $Reference,
        $Uri
    )
    try {
        $UpdateMgaUriReferenceSplat = @{
            Uri       = $Uri
            Reference = 'v1.0'
        }
        if ($Uri.Count -eq 1) {
            Update-MgaOauthToken
            if ($CustomHeader) {
                Enable-MgaCustomHeader -CustomHeader $CustomHeader
            }
            if ($Reference -eq 'All') {
                $Uri = Update-MgaUriReference @UpdateMgaUriReferenceSplat
            }
            elseif ($Reference) {
                $Uri = Update-MgaUriReference -Uri $Uri -Reference $Reference
            }
            else {
                $Uri = Build-MgaUri -Uri $Uri
            }

        } else {
            $UriResult = @()
            foreach ($Url in $Uri) {
                $UriResult += Build-MgaUri -Uri $Url
            }
            $Uri = $UriResult
        }
        return [PSCustomObject]@{
            Uri                   = $Uri
            UpdateMgaUriReference = $UpdateMgaUriReferenceSplat.Refence
        }
    }
    catch {
        throw $_
    }
}