function Trace-MgaThrottle {
    param (
        $Seconds
    )
    try {
        $RetryValue = 0
        [int]$RetryValue = $Seconds
        if ($RetryValue -eq 0) {
            $RetryValue = 15  
        }
        elseif ($RetryValue -eq 1) {
            $RetryValue = 15  
        }
        elseif ([string]::IsNullOrEmpty($RetryValue)) {
            $RetryValue = 15 
        }
        Write-Warning "Trace-MgaThrottle: Throttled for $RetryValue seconds"
        Start-Sleep -Seconds $($RetryValue + 1)
    }
    catch {
        throw $_
    }
}