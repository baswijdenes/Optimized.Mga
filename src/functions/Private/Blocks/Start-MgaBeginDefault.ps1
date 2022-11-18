function Start-MgaBeginDefault {
    param (
        $CustomHeader,
        $Api,
        $Uri
    )
    try {
        if ($Uri.Count -eq 1) {
            Update-MgaOauthToken
            if ($CustomHeader) {
                Enable-MgaCustomHeader -CustomHeader $CustomHeader
            }
            if ($Api -eq 'All') {
                $Api = 'v1.0'
                $Uri = Build-MgaUri -Uri $Uri -Api 'v1.0'
            }
            elseif ($Api) {
                $Uri = Build-MgaUri -Uri $Uri -Api $Api
            }
            else {
                $Uri = Build-MgaUri -Uri $Uri
            }
        }
        else {
            $UriResult = @()
            foreach ($Url in $Uri) {
                $UriResult += Build-MgaUri -Uri $Url
            }
            $Uri = $UriResult
        }
        return [PSCustomObject]@{
            Uri = $Uri
            Api = $Api
        }
    }
    catch {
        throw $_
    }
}