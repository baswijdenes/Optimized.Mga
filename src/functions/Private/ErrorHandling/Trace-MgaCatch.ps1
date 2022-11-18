function Trace-MgaCatch {
    param (
        $Throw
    )
    try {
        $WebResponse = $Throw.Exception.Response
        if ($WebResponse.StatusCode -eq 'TooManyRequests') {
            Trace-MgaThrottle -Seconds $WebResponse.Headers.retryafter.delta.Seconds
        }
        elseif ($WebResponse.StatusCode -eq 429) {
            Trace-MgaThrottle -Seconds $WebResponse.Headers['Retry-After']
        }
        else {
            throw $Throw
        }
    }
    catch {
        throw $_
    }
}