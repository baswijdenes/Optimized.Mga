function ConvertTo-MgaResult {
    param (
        $Response
    )
    try {
        $Return = @()
        if ($Response.StatusCode -eq 204) {
            $Return = $Null
        }
        else {
            if ($Result.Value) {
                foreach ($Line in ($Result).value) {
                    $Return += $Line
                }
            }
            elseif ((($Response | Get-Member -MemberType NoteProperty).Name -contains 'Value') -and ([string]::IsNullOrEmpty($Response.Value))) {
                $Return = $null
            }
            elseif ($Response.Content) {
                try {
                    $Return = $Response.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
                }
                catch {
                    $Return = $Response.Content
                }
            }
            else {
                $Return = $Response
            }
        }
        return $Return
    }
    catch {
        throw $_
    }
}