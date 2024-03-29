# 4.0.0
## New features
### Query parameters for the `Get-Mga` cmdlet!
You can now use query parameters to filter the results of the `Get-Mga` cmdlet. For example, to get all the users in your tenant, you can use the following command:
```powershell
Get-Mga -Uri users -Top 999 -Select Id, displayName, userPrincipalName -OrderBy DisplayName

0f050b84-cce2-4b15-bbf9-c133e3cf3c64 ZzFOAlKcWf                ZzFOAlKcWf@M365x37707772.onmicrosoft.com
53e2aa0f-3891-46c4-8419-637368ed1d32 ZzhQJKNcOs                ZzhQJKNcOs@M365x37707772.onmicrosoft.com
f4272b98-8b8f-4c21-b19e-aa5a31dc2fb0 ZzRKbqGgkd                ZzRKbqGgkd@M365x37707772.onmicrosoft.com
```
Current supported query parameters are:
- Top
- Skip
- Select
- OrderBy
- Expand
- Count

There is no filter or such yet for queries not supported by specific endpoints (yet).

### Return as Json for `Get-Mga`, `Add-Mga`, `New-Mga`, `Set-Mga`! 
You can now use the -ReturnAsJson parameter to return the results of the `Get-Mga`, `Add-Mga`, `New-Mga`, `Set-Mga` cmdlets as a Json string.  
For example, to get all the users in your tenant, you can use the following command:
```powershell
Get-Mga -Uri users -Top 999 -Skip 900 -Select Id, displayName, userPrincipalName -OrderBy DisplayName -ReturnAsJson
  {
    "id": "53e2aa0f-3891-46c4-8419-637368ed1d32",
    "displayName": "ZzhQJKNcOs",
    "userPrincipalName": "ZzhQJKNcOs@M365x37707772.onmicrosoft.com"
  },
  {
    "id": "f4272b98-8b8f-4c21-b19e-aa5a31dc2fb0",
    "displayName": "ZzRKbqGgkd",
    "userPrincipalName": "ZzRKbqGgkd@M365x37707772.onmicrosoft.com"
  }
```
### `Get-MgaToken` (Old `Connect-Mga`) now logs in by DeviceCode by default
`Get-MgaToken` will now use `-DeviceCode $true` when there is no login type specified.  
This will also automatically load [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin) in the browser.

# 3.0.3.3
- Updated bug fix for errorhandling in importing module
  
# 3.0.3.2
- Updated the Reference parameter to Api

# 3.0.3.1
- Small bugfixes
---
# 3.0.3
## New features
### Reference Parameter!
  There are endpoints that are only available in the beta version of the Microsoft Graph API.  
  How annoying is it that you need to update this manually when it changes to v1.0?  
  You can now use the Reference parameter that will try both. First v1.0 and when it jumps to the catch block it will try it with the beta version.

### No more URL formatting!
You do not need to add the url anymore. It will auto add the rest for you.  
  Examples:
  - /users                                  > https://graph.microsoft.com/v1.0/users
  - users                                   > https://graph.microsoft.com/v1.0/users
  - beta/users                              > https://graph.microsoft.com/beta/users
  - v1.0/users                              > https://graph.microsoft.com/v1.0/users
  - /beta/users                             > https://graph.microsoft.com/beta/users
  - /v1.0/users                             > https://graph.microsoft.com/v1.0/users
  - https://graph.microsoft.com/v1.0/users  > https://graph.microsoft.com/v1.0/users
  - https://graph.microsoft.com/beta/users  > https://graph.microsoft.com/beta/users

### New cmdlet!
Invoke-Mga:  
By using Invoke-Mga you do not have to change the way you use the default Method cmdlets in the Mga module.  
Invoke-Mga is a wrapper around the default Method cmdlets in the Mga module.

### Better documentation!
- Documentation changes from versions to changelog
- cmdlets have their own markdown files in ./docs

### Backend
  - Module is split into single function files with a private / public folder.
  - I tried to build micro functions that can be re-used a lot. 

### Resolved bugs 
  - The throttle is now working again as expected! 

## Changes in cmdlet names! 
The module contained cmdlets that had unapproved verbs.  
This was easy because the default method was the verb, but this also gave you a warning, and your editor doesn't see if it's a cmdlet (and so is shown in a different color). Because of this, I decided to rename the cmdlets to match the methods.  
The cmdlets can still be used with the original names.  
The aliases are automatically created when the module is imported.

* Connect-Mga > Get-MgaToken
* Disconnect-Mga > Remove-MgaToken
* Show-MgaAccessToken > Show-MgaToken
* Get-MgaVariable > Get-MgaHashTable
* Update-MgaVariable > Edit-MgaHashTable
* Batch-Mga > Group-Mga
* Put-Mga > Add-Mga
* New-Mga > Post-Mga
* Delete-Mga > Remove-Mga
* Set-Mga > Patch-Mga

## General changes
- For all cmdlets using InputObject: Changed parameter name 'InputObject' to 'Body' and added InputObject as alias to Body.
- For all cmdlets using Variable: Changed parameter name 'Variable' to 'Property' and added Variable as alias to Property
- Added -Reference parameter to all Method cmdlets
- -Uri parameter will automatically try to convert the Uri to a full Uri

### Changes in Get-MgaToken / Connect-Mga
- RedirectUri and Credential (basic) are removed parameters. 

### Changes in Get-Mga
- Changed parameter name 'Once' to 'SkipNextLink' and added Once as alias to SkipNextLink.

---
# 3.0.2
## General
- I've updated several cmdlets because the Retry function didn't work in PS7  
  I've updated this with a quick fix & a better fix will be implemented soon
- Removed Get-MgaPreview as it didn't work as expected
- New features / optimized cmdlets will be implemented soon

---
# 3.0.1
## General
- Update .dll to netstandard

---
# 3.0.0
## General
- There are no new features right now, but from now on we will follow the semantic Versioning. 

### Connect-Mga
- There is a minor bug fix with -Devicecode and -Basic refreshing the oauth token with every call to MS Graph.

---
# 0.0.2.8
## Connect-Mga
- `Connect-Mga` is updated to DeviceCode only 
- Removed a wrong Parameter bug (was a visible bug only)
- Updated ParameterSets from internal functions due to issue with RedirectUri

---
# 0.0.2.7
## General
- **Devicecode Login** available now! (See [Connect-Mga](#Connect-Mga) for more)
- No more variables in the Global scope!  
  From now on variables needed by the module are saved to the script scope in 1 variable: `$script:MgaSession`  
  See [Get-MgaVariable](#Get-MgaVariable) for more

## Get-MgaVariable
- Since the global scope dissapeared you're unable to see the variables in the script scope. I've created the `Get-MgaVariable` for you to see the AccessToken etc
- See main README.md for more information

## Update-MgaVariable
- This cmdlet will be mostly used for testing purposes 
- With `Update-MgaVariable` you can update Variables to test several settings
- See main README.md for more information

## Get-MgaPreview
- This is a Preview version for `Get-Mga`
- Updated `Invoke-WebRequest` to `Invoke-Restmethod` for more optimization (he he)
- If all works well this will eventually become `Get-Mga`
- See main README.md for more information
---

## Connect-Mga
- `Connect-Mga` includes a new type of Login: DeviceCode & DeviceCodePreview
- DeviceCode uses MSAL where DeviceCodePreview will retrieve a token from the Microsoft EndPoint 
- Use DeviceCodePreview when you need an automatic refresh (RefreshToken)
- See main README.md for more information

## Disconnect-Mga 
- Disconnect-Mga got updated to remove the `$script:MgaSession` from the script scope

---
# 0.0.2.6
## Connect-Mga
- `Connect-Mga` from now on also accepts ManagedIdentities with the `-ManagedIdentity` parameter
- Updated the cmdlet to use try and catch for better error handling

## Show-MgaAccessToken
- Updated the synopsis

---
# 0.0.2.5
## Intro
From 0.0.2.3 to 0.0.2.5. Somewhere I went wrong and I have no idea where! 
## new cmdlet
- Show-MgaAccessToken

With this cmdlet you can check the AccessToken without leaving your IDE. You can also specifically ask the Roles to see if the Roles match with the Graph API.

## New Submodule
- Optimized.Mga.Report

I added all the Report Graph API in their own cmdlet.  
I've created the Optimized.Mga.Report module for this

For more information:
- [PowerShell Gallery](https://www.powershellgallery.com/packages/Optimized.Mga.Report)
- [Github](https://github.com/baswijdenes/Optimized.Mga.Report)

---
# 0.0.2.4
* Made a mistake in version numbers, so 0.0.2.4 does not exist

---
# 0.0.2.3
* This version only contains a few small updates

---
# 0.0.2.2
## General
* All cmdlets received a new parameter: -CustomHeader. With this function you can now upload with a CustomHeader this is for example for uploading items to sharepoint or onedrive
* Improved ErrorHandling: Updated a few functions for better Error messages
* Improved Cmdlet Parameters: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

## Connect-Mga
* The Thumbprint parameter is now an ALIAS under Certificate with a validatescript:  
  `[ValidateScript( { ($_.length -eq 40) -or ([System.Security.Cryptography.X509Certificates.X509Certificate2]$_) })]`

## Put-Mga
* New cmdlet for Method Put

## Send-MgaMail
* Send-MgaMail has been removed from the main module: Optimized.Mga and moved to: Optimized.Mga.Mail

---
# 0.0.2.1
## General
* Added a classes ps1 for future experimental cmdlets
* Testing will come soon to github

## Connect-Mga
* Connecting with Basic UserCredentials will now use the refreshtoken after it expired

## Send-MgaMail
Send-MgaMail will now accept an Array instead of a file (Also multiple Arrays)
```PowerShell
$Object = [PSCustomObject] @{
    Name = 'Testfile.csv'
    Content = (Get-Service | ConvertTo-Csv -NoTypeInformation)
}
Send-MgaMail -To XX -Subject XX -Body XX -AttachmentObjects $Object
```

---
# 0.0.2.0
## General
* Global Scope Parameters names changed From GL... to Mga...: $global:GLCertificate to $global:MgaCertificate
* Updated synopsis for cmdlets

## Send-MgaMail
* To can now contain multiple addresses
* Added support for (multiple) Attachments
* When logged in with user credentials the From address will automatically be the userLogon. This is also displayed in a warning message.

## Connect-Mga
* Connecting with a Redirecturi will now create Authorization with: Result.[CreateAuthorizationHeader()](https://docs.microsoft.com/en-us/dotnet/api/microsoft.identity.client.authenticationresult.createauthorizationheader?view=azure-dotnet) method

## Disconnect-Mga 
Disconnecting from Microsoft.Graph.API will now remove variables starting with Mga