function Build-MgaUri {
    param (
        $Uri,
        $Api
    )
    try {
        $Verbose = 'Formatted Uri to: ' 
        if ($Uri -like 'https://graph.microsoft.com/*') {
            $Uri = $Uri
        }
        else {
            if ($Uri -like '/v1.0/*') {
                $Uri = "https://graph.microsoft.com$Uri"
            }
            elseif ($Uri -like 'v1.0/*') {
                $Uri = "https://graph.microsoft.com/$Uri"
            }
            elseif ($Uri -like '/beta/*') {
                $Uri = "https://graph.microsoft.com$Uri"
            }
            elseif ($Uri -like 'beta/*') {
                $Uri = "https://graph.microsoft.com/$Uri"
            }
            elseif ($Uri -like '/*') {
                $Uri = "https://graph.microsoft.com/v1.0$Uri"
            }
            else {
                $Uri = "https://graph.microsoft.com/v1.0/$Uri"
            }
        }
        if ($Api -eq 'beta') {
            $Uri = $Uri -Replace '/v1.0/', '/beta/'
        }
        elseif ($Api -eq 'v1.0') {
            $Uri = $Uri -Replace '/beta/', '/v1.0/'
        }
        Write-Verbose "$Verbose$Uri"
        return $Uri
    }
    catch {
        throw $_
    }
}