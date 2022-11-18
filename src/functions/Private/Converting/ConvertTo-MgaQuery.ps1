function ConvertTo-MgaQuery {
    param (
        $Uri,
        $Top,
        $Skip,
        $Count,
        $OrderBy,
        $Expand,
        $Select
    )
    function Update-Query {
        param (
            $Query,
            $Uri,
            [bool]$QueryEnabled
        )
        if ($QueryEnabled -eq $true) {
            $Query = "&$Query"
        }
        else {
            $Query = "?$Query"           
        }
        $Uri = "$Uri$Query"
        return $Uri, $true
    }
    $QueryEnabled = $false
    if ($Top) {
        $Query = "`$top=$Top"
        $Result = Update-Query -Query $Query -Uri $Uri -QueryEnabled $QueryEnabled
        $Uri = $Result[0]
        $QueryEnabled = $Result[1]
    } 
    if ($Skip) {
        $Query = "`$Skip=$Skip"
        $Result = Update-Query -Query $Query -Uri $Uri -QueryEnabled $QueryEnabled
        $Uri = $Result[0]
        $QueryEnabled = $Result[1]
    } 
    if ($Count) {
        $Query = "`$Count=$Count"
        $Result = Update-Query -Query $Query -Uri $Uri -QueryEnabled $QueryEnabled
        $Uri = $Result[0]
        $QueryEnabled = $Result[1]
    }
    if ($OrderBy) {
        $Query = "`$OrderBy=$OrderBy"
        $Result = Update-Query -Query $Query -Uri $Uri -QueryEnabled $QueryEnabled
        $Uri = $Result[0]
        $QueryEnabled = $Result[1]
    }
    if ($Expand) {
        $Query = "`$Expand=$Expand"
        $Result = Update-Query -Query $Query -Uri $Uri -QueryEnabled $QueryEnabled
        $Uri = $Result[0]
        $QueryEnabled = $Result[1]
    }
    if ($Select) {
        $i = 1
        foreach ($Property in $Select) {
            if ($i -eq $Select.Count) {
                $SelectString += $Property
            }
            else {
                $i++
                $SelectString += "$Property,"
            }   
        }
        $Query = "`$Select=$SelectString"
        $Result = Update-Query -Query $Query -Uri $Uri -QueryEnabled $QueryEnabled
        $Uri = $Result[0]
        $QueryEnabled = $Result[1]
    }
    if ($QueryEnabled -eq $true) {
        Write-Verbose "Added Query Parameters: $Uri"
    }
    return $Uri
}