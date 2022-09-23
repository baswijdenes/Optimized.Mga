function ConvertTo-MgaJson {
    param (
        $Body,
        [switch]
        $Validate
    )
    try {
        try {
            $null = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
            $ValidateJson = $true
        }
        catch {
            if ($Validate -ne $true) {
                $Body = ConvertTo-Json -InputObject $Body -Depth 100
            }
            else {
                $ValidateJson = $false
            }
        }    
        if ($Validate -ne $true) {
            return $Body
        }
        else {
            return $ValidateJson
        }
    }
    catch {
        throw $_
    }
}