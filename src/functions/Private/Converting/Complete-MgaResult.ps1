function Complete-MgaResult {
    param (
        $Result,
        $CustomHeader,
        $ReturnVerbose
    )
    try {
        if ($CustomHeader) {
            Disable-MgaCustomHeader
        }
        if ($Result) {
            return $Result
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