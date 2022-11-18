function Complete-MgaResult {
    param (
        $Result,
        $CustomHeader,
        $ReturnVerbose,
        [bool]$ReturnAsJson
    )
    try {
        if ($CustomHeader) {
            Disable-MgaCustomHeader
        }
        if ($Result) {
            $EndResult = $Result
            if ($ReturnAsJson -eq $true) {
                try {
                    $EndResult = $Result | ConvertTo-Json -Depth 100
                }
                catch {
                    $EndResult = $Result
                }
            }
            return $EndResult
        }
        else {
            if ($ReturnVerbose -ne $false) {
                Write-Verbose 'No result returned'
            }
        }
    }
    catch {
        throw $_
    }
}