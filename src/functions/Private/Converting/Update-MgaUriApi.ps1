function Update-MgaUriApi {
    param (
        $Uri,
        $Api
    )
    try {
        $Uri = Build-MgaUri -Uri $Uri
        if ($Api -eq 'beta') {
            $Uri = $Uri -Replace '/v1.0/', '/beta/'
        }
        elseif ($Api -eq 'v1.0') {
            $Uri = $Uri -Replace '/beta/', '/v1.0/'
        }
        return $Uri
    }
    catch {
        throw $_
    }
}