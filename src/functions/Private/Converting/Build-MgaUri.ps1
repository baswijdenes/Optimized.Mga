function Build-MgaUri {
    param (
        $Uri
    )
    try {
        if ($Uri -like 'https://graph.microsoft.com/*') {
            $Uri = $Uri
        }
        else {
            $Verbose = 'Formatted Uri to: ' 
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
            Write-Verbose "$Verbose$Uri"
        }
        return $Uri
    }
    catch {
        throw $_
    }
}