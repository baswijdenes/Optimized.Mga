function Disable-MgaCustomHeader {
    try {
        if ($Script:MgaSession.HeaderParameters -ne $Script:MgaSession.OriginalHeader) {
            Write-Verbose 'Reverting header'
            $Script:MgaSession.remove('HeaderParameters')
            $Script:MgaSession.HeaderParameters = $Script:MgaSession.OriginalHeader
            $Script:MgaSession.remove('OriginalHeader')
        }
    }
    catch {
        throw "Something went wrong reverting back header... Re-login with Connect-Mga to continue... Error: $_"
    }
}