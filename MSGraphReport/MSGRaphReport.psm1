<#
.SYNOPSIS
Function is still under construction.

.DESCRIPTION
With this function you will only have to use add the following parameters to get your Microsoft Graph report:
-TenantDomain
-ClientID
-ClientSecret
-URI
-Output

I only use the GET method.

.PARAMETER ClientID
AzureAD App registration ClientID

.PARAMETER ClientSecret
AzureAD App registration Client Secret

.PARAMETER TenantDomain
Tenant Domain
baswijdenesoutlook.onmicrosoft.com

.PARAMETER URI
The Report URI
https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageDetail(period='D7')

.PARAMETER Output
Use JSON or CSV. Check on graph.microsoft.com what if the respsone will be JSON or CSV.

.EXAMPLE
Get-MSGraphReport `
-TenantDomain 'baswijdenesoutlook.onmicrosoft.com' `
-ClientID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXX' `
-ClientSecret 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXX' `
-URI "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageDetail(period='D7')" `
-Output CSV

.NOTES
Email me @ baswijdenes@gmail.com for help or find me @ my blog https://bwit.blog/
#>
function Get-MSGraphReport
{
    [CmdletBinding(HelpURI = 'https://bwit.blog')]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("ID", "AppID", "ClientID", "App")]
        [string]
        $ApplicationID,
        [Parameter(Mandatory = $true)]
        [Alias("Password", "PW", "AppSecret", "Pass")]
        [string]
        $ApplicationSecret, 
        [Parameter(Mandatory = $true)]
        [Alias("TenantName", "Tenant")]
        [string]
        $TenantID,
        [Parameter(Mandatory = $true)]
        [Alias("URI")]
        [string]
        $URL
    )
    begin
    {
        $global:ErrorsList = [system.Collections.Generic.List[system.Object]]::new()
        try
        {
            $loginURL = "https://login.microsoft.com"
            $Resource = "https://graph.microsoft.com"
            Write-Verbose "Get-MSGRaphReport: Login URL is: $LoginUrl."
            Write-Verbose "Get-MSGRaphReport: Resource is: $Resource."
            $Body = @{
                grant_type    = "client_credentials";
                resource      = $Resource;
                client_id     = $ApplicationID;
                client_secret = $ApplicationSecret
            }
            Write-Verbose "Get-MSGRaphReport: Body has formed to retrieve Oauth access token from $Resource."
            $Oauth = Invoke-RestMethod -Method Post -Uri $loginURL/$TenantID/oauth2/token?api-version=1.0 -Body $Body 
            if ($null -eq $oauth.access_token)
            {
                throw 'We did not retrieve an Oauth access token to continue script. Exiting script...'
                break
            }
            else
            {
                Write-Verbose "Get-MSGRaphReport: We have succesfully retrieved the Oauth access token. We will continue the script."
                $global:headerParameters = @{
                    Authorization = "$($Oauth.token_type) $($Oauth.access_token)"
                }
            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "Get-MSGRaphReport: Error in begin of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorsList.Add($Object) 
            Write-Warning 'Get-MSGRaphReport: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message
            break
        }
    }
    process
    {
        try
        {
            Write-Verbose "Get-MSGRaphReport: Getting results from $URL."
            $Result = Invoke-WebRequest -UseBasicParsing -Headers $global:HeaderParameters -Uri $URL -Method get
            if ($result.Headers.'Content-Type' -like "application/octet-stream*")
            {
                Write-Verbose "Get-MSGRaphReport: Result is in CSV format. Converting to CSV."
                Write-Verbose "Get-MSGRaphReport: We will add the data to endresult."
                $EndResult = ConvertFrom-Csv -InputObject $Result
            }
            if ($result.Headers.'Content-Type' -like "application/json*")
            {   
                Write-Verbose "Get-MSGRaphReport: Result is in JSON format. Converting to JSON."
                $JSON = ConvertFrom-Json -InputObject $Result
                if ($JSON.'@odata.nextLink')
                {
                    Write-Verbose "Get-MSGRaphReport: Data output is more than 100 results. We will run script again with next data link."
                    $EndResult = @()
                    foreach ($Line in ($JSON).value)
                    {
                        $EndResult += $Line
                    }
                    While ($JSON.'@odata.nextLink')
                    {
                        Write-Verbose "Get-MSGRaphReport: Data output is still more than 100 results. We will run script again with next data link."
                        $JSON = (Invoke-WebRequest -UseBasicParsing -Headers $HeaderParameters -Uri $JSON.'@odata.nextLink' -Method Get).Content | ConvertFrom-Json
                        foreach ($Line in ($JSON).value)
                        {
                            $EndResult += $Line
                        }
                        Write-Verbose "Get-MSGRaphReport: Count is: $($EndResult.count)"
                    }
                }
                elseif ($JSON.value)
                {
                    Write-Verbose "Get-MSGRaphReport: Data output is less than 100 results. We will add the data to end result."
                    $EndResult = $JSON.value
                }
                else
                {
                    Write-Verbose "Get-MSGRaphReport: Data output is less than 100 results. We will add the data to end result."
                    $EndResult = $JSON
                }
            }
        }
        catch
        {
            $Object = [PSCustomObject] @{
                Information  = "Get-MSGRaphReport: Error in process of function."
                ErrorMessage = "$($_.Exception.Message)"
            }
            $global:ErrorsList.Add($Object) 
            Write-Warning 'Get-MSGRaphReport: To see if there are more errors please run: $global:ErrorList.'
            throw $_.Exception.Message       
            break
        }
    }
    end
    {
        Write-Verbose "Get-MSGRaphReport: We've succesfully retrieved the end result. The end result will be returned."
        return $EndResult
    }
}