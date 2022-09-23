function Update-MgaUriReference {
    param (
        $Uri,
        $Reference
    )
    try {
        $Uri = Build-MgaUri -Uri $Uri
        if ($Reference -eq 'beta') {
            $Uri = $Uri -Replace '/v1.0/', '/beta/'
        }
        elseif ($Reference -eq 'v1.0') {
            $Uri = $Uri -Replace '/beta/', '/v1.0/'
        }
        return $Uri
    }
    catch {
        throw $_
    }
}