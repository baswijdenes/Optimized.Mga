# Optimized.Mga

Don't you wish you have a Microsoft Graph module which handles batching, the token and throttling for you, but where you can just enter your own URL so you aren't restricted to the limitations of the official Microsoft Module and even includes a way to speed up the process?

* [PowerShell Gallery](https://www.powershellgallery.com/packages/Optimized.Mga)
* [Submit an issue](https://github.com/baswijdenes/Optimized.Mga/issues)
* [My blog](https://bwit.blog/)

## Submodules dependent on Optimized.Mga:
- [Optimized.Mga.SharePoint](https://github.com/baswijdenes/Optimized.Mga.SharePoint)
- [Optimized.Mga.Mail](https://github.com/baswijdenes/Optimized.Mga.Mail)
- [Optimized.Mga.AzureAD](https://github.com/baswijdenes/Optimized.Mga.AzureAD)

## UPDATES VERSIONS
* [0.0.2.6.md](./.Versions/0.0.2.6.md)
* [0.0.2.5.md](./.Versions/0.0.2.5.md)
* [0.0.2.3.md](./.Versions/0.0.2.3.md)
* [0.0.2.2.md](./.Versions/0.0.2.2.md)
* [0.0.2.1.md](./.Versions/0.0.2.1.md)
* [0.0.2.0.md](./.Versions/0.0.2.0.md)

## Are you new with the Microsoft Graph API? 
* [Here is a link to the official Microsoft Graph API SDK for PowerShell](https://docs.microsoft.com/en-us/graph/powershell/get-started)
* [Here is a link to post on my blog about starting with Microsoft Graph API](https://bwit.blog/how-to-start-with-microsoft-graph-in-powershell/)

## What makes your module different from the official Microsoft Graph SDK for PowerShell?

* [Speed](#Speed)
* [Usability](#Usability)
* [Bulk](#Bulk)

### Speed
The main difference is **speed**.

Batch-Mga doesn't lie.
When I use Measure-Command while creating 10,000 users via the Post command it takes about 41 minutes:

```PowerShell
$CreatedUsers.count
10000
Measure-Command {
    foreach ($User in $CreatedUsers) {
        try {
            Post-Mga -URL 'https://graph.microsoft.com/v1.0/users' -InputObject $User
        }
        catch {
            continue
        }
    }
}

Minutes           : 41
Seconds           : 6
Milliseconds      : 717
```
When I create the same users via Batch-Mga, it's 10 minutes:
```PowerShell
$Batch = [System.Collections.Generic.List[Object]]::new()
foreach ($User in $CreatedUsers) {
    $Object = [PSCustomObject]@{
        Url    = "/users"
        method = 'post'
        body   = $User
    }
    $Batch.Add($Object)
}
Measure-Command {
    Batch-Mga -InputObject $Batch
}

Minutes           : 9
Seconds           : 43
Milliseconds      : 152
```

Batch-Mga will take care of the limitations (20 requests per batch) and will sleep for the amount of time a throttle limit is returned and then continue.

### Usability
The second difference is **usability**.
If you look at the official module you will see 33 dependencies.
I made my module so that you only need 8 cmdlets.

The main cmdlet is of course Batch-Mga, by using Fiddler, or the browser developer tools you can find the URL when navigating through AzureAD and use it in one of the cmdlets. 

For example the below URL is from the Intune Management GUI and found with Fiddler. It will get the Windows compliant devices and will only select the ComplianceState and UserPrincipalname.
```powershell
$URL = 'https://graph.microsoft.com/beta/deviceManagement/managedDevices?$filter={0}&$top=999&$select=userPrincipalName,complianceState' -f "complianceState%20eq%20'Compliant'%20and%20operatingSystem%20eq%20'Windows'"
Get-Mga -URL $URL
```

### Bulk
Patch-Mga with parameters -InputObject and -Batch and with the Property members@odata.bind will automatically be batched. So, in theory you can add 10000 users to a Group instantly. While throttling is handled for you.
```PowerShell
$CreatedUsers = Get-Mga -URL 'https://graph.microsoft.com/v1.0/users?$top=999'
$UserPostList = [System.Collections.Generic.List[Object]]::new() 
foreach ($User in $CreatedUsers)
{
    $DirectoryObject = 'https://graph.microsoft.com/v1.0/directoryObjects/{0}' -f $User.id
    $UserPostList.Add($DirectoryObject)
}
$PostBody = [PSCustomObject] @{
    "members@odata.bind" = $UserPostList
}

Patch-Mga -URL 'https://graph.microsoft.com/v1.0/groups/ac252320-4194-402f-8182-2d14e4a2db5c' -InputObject $PostBody -Verbose
```

Same goes for Delete-Mga. When parameter -URL is an Array, it will automatically batch your request:
```PowerShell
$Groupusers = Get-Mga -URL 'https://graph.microsoft.com/v1.0/groups/ac252320-4194-402f-8182-2d14e4a2db5c/members'
$UserList = @()
foreach ($User in $Groupusers) {
    $URL = 'https://graph.microsoft.com/v1.0/groups/ac252320-4194-402f-8182-2d14e4a2db5c/members/{0}/$ref' -f $User.Id
    $UserList += $URL
}
Delete-Mga -URL $UserList
```
---
# Optimized.Mga Cmdlets

* [Connect-Mga](#Connect-Mga)
* [Disconnect-Mga](#Disconnect-Mga)
* [Show-MgaAccessToken](#Show-MgaAccessToken)
* [Get-Mga](#Get-Mga)
* [Post-Mga](#Post-Mga)
* [Patch-Mga](#Patch-Mga)
* [Delete-Mga](#Delete-Mga)
* [Batch-Mga](#Batch-Mga)


---
## Connect-Mga
By selecting one of these parameters you log on with the following:
* **ClientSecret**: Will log you on with a ClientSecret.
* **Certificate**: Will log you on with a Certificate.
* **Thumbprint**: Will search for a Certificate under thumbprint on local device and log you on with a Certificate.
* **UserCredentials**: Will log you on with basic authentication.
* **RedirectUri**: Will log you on with MFA Authentication.
* * **RedirectUri**: Will log you on with a Managed Identity.

The OauthToken is automatically renewed when you use cmdlets.

If you want to know more about how to log in via MFA with a RedirectUri, follow this **[link](https://bwit.blog/how-to-start-with-microsoft-graph-in-powershell/#I_will_use_credentials)**.

### Examples 
````PowerShell
Connect-Mga -ClientSecret '1yD3h~.KgROPO.K1sbRF~XXXXXXXXXXXXX' -ApplicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -Tenant 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' 

$Cert = get-ChildItem 'Cert:\LocalMachine\My\XXXXXXXXXXXXXXXXXXX'
Connect-Mga -Certificate $Cert -ApplicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -Tenant 'XXXXXXXX.onmicrosoft.com'

Connect-Mga -Thumbprint '3A7328F1059E9802FAXXXXXXXXXXXXXX' -ApplicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -Tenant 'XXXXXXXX.onmicrosoft.com' 

Connect-Mga -UserCredentials $Cred -Tenant 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -ApplicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX'

Connect-Mga -redirectUri 'msalXXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX://auth' -Tenant 'XXXXXXXX.onmicrosoft.com'  -ApplicationID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX'

Connect-Mga -ManagedIdentity
````
---
## Disconnect-Mga
To update the OauthToken I fill the global scope with a number of properties. The properties are emptied by Disconnect-Mga.

### Examples 
````PowerShell
Disconnect-Mga
````
---
## Show-MgaAccessToken
With `Show-MgaAccessToken` you can request a decoded Token and see what is in their (normally you would paste it into (jwt.ms)[jwt.ms]).  
With the `-Roles` switch you can also only ask the roles you have assigned to the application registration.  

```PowerShell
Show-MgaAccessToken

Show-MgaAccessToken -Roles
```
---
## Get-Mga
Get-Mga speaks for itself. All you have to provide is the URL.

You can grab the URL via the browser developer tools, Fiddler, or from the [Microsoft Graph docs](https://docs.microsoft.com/en-us/graph/overview).
You can use all query parameters in the URL like some in the examples.

It will automatically use the Next Link when there is one in the returned request. 

If you only want to retrieve data once, you can use the -Once parameter.
For example, I used this in the beta version to get the latest login. Nowadays this property is a property under the user: signInActivity.

### Examples 
````PowerShell
Get-Mga -URL 'https://graph.microsoft.com/v1.0/users' -Once

Get-Mga -URL 'https://graph.microsoft.com/v1.0/users?$top=999'

$URL = 'https://graph.microsoft.com/v1.0/users?$select={0}' -f 'id,userPrincipalName,lastPasswordChangeDateTime,createdDateTime,PasswordPolicies' 
Get-Mga -URL $URL

$URL = 'https://graph.microsoft.com/beta/users?$filter=({0})&$select=displayName,userPrincipalName,createdDateTime,signInActivity' -f "UserType eq 'Guest'"
Get-Mga URL $URL
````
---
## Post-Mga
Post-Mga can be seen as the 'new' Verb.
With this cmdlet you create objects in AzureAD.

-InputObject will accept a PSObject or JSON. 

The example below creates a new user. 

### Examples 
````PowerShell
$InputObject = @{
    accountEnabled    = 'true'
    displayName       = "Test User Post MSGraph"
    mailNickname      = "TestUserPostMSGraph"
    userPrincipalName = "TestUserPostMSGraph@XXXXXXXXX.onmicrosoft.com"
    passwordProfile   = @{
        forceChangePasswordNextSignIn = 'true'
        password                      = 'XXXXXXXXXX'
    }
}
Post-Mga -URL 'https://graph.microsoft.com/v1.0/users' -InputObject $InputObject
````
---
## Patch-Mga
Patch-Mga can be seen as the 'Update' Verb.

-InputObject will accept a PSObject or JSON. 

InputObject with members@odata.bind property over 20+ users will automatically be handled for you.

-Batch is a switch to use Batch in the backend. -Batch only works with 'members@odata.bind' property.

In the below example I add users to a Group.

### Examples 
````PowerShell
$users = Get-Mga 'https://graph.microsoft.com/v1.0/users'
$UserPostList = [System.Collections.Generic.List[Object]]::new() 
foreach ($User in $users)
{
    $DirectoryObject = 'https://graph.microsoft.com/v1.0/directoryObjects/{0}' -f $User.id
    $UserPostList.Add($DirectoryObject)
}
$PostBody = [PSCustomObject] @{
    "members@odata.bind" = $UserPostList
}
Patch-Mga -URL 'https://graph.microsoft.com/v1.0/groups/4c9d31a2-c662-4f76-b3f8-52290d2aa788' -InputObject $PostBody 
````
---
## Delete-Mga
Delete speaks for itself. 
With this cmdlet you can remove objects from AzureAD. 

-URL accepts an array of URLS, it will use Batch-Mga in the backend.

-InputObject will accept a PSObject or JSON. 

### Examples 
```PowerShell
Delete-Mga -URL 'https://graph.microsoft.com/v1.0/users/TestUserPostMSGraph@XXXXXXXXXXX.onmicrosoft.com' 
```
```PowerShell
$GroupUsers = Get-Mga -URL 'https://graph.microsoft.com/v1.0/groups/ac252320-4194-402f-8182-2d14e4a2db5c/members'
$UserList = @()
foreach ($User in $GroupUsers) {
    $URL = 'https://graph.microsoft.com/v1.0/groups/ac252320-4194-402f-8182-2d14e4a2db5c/members/{0}/$ref' -f $User.Id
    $UserList += $URL
}
Delete-Mga -URL $UserList
```
---
## Batch-Mga
Batch-Mga is for speed and bulk.

Go to [Speed](#Speed) or [Bulk](#Bulk) for more. 

Batch-Mga will take care of the limitations(20 requests per batch) and will sleep for the amount of time a throttle limit is returned and then continue.

### Examples 
**Bulk delete users:**
```PowerShell
$DeletedObjects = Get-Mga -URL 'https://graph.microsoft.com/v1.0/directory/deletedItems/microsoft.graph.user?$top=999'
$Batch = [System.Collections.Generic.List[Object]]::new()
foreach ($User in $DeletedObjects) {
    $Object = [PSCustomObject]@{
        url    = "/directory/deletedItems/$($User.id)"
        method = 'delete'
    }
    $Batch.Add($object)
}
Batch-Mga -InputObject $batch
```
**Bulk update officeLocation for users:**
```PowerShell
$BatchDependsOn = [System.Collections.Generic.List[Object]]::new()
foreach ($User in $Response) {
    $Object = [PSCustomObject]@{
        Url       = "/users/$($User.UserPrincipalName)"
        method    = 'patch'
        body      = [PSCustomObject] @{
            officeLocation = "18/2111"
        }
        dependsOn = 2
    }
    $test.Add($object)
}
Batch-Mga -InputObject $BatchDependsOn
```
**Bulk create users:**  
$User Object is build like this: 

```PowerShell
$User = [PSCustomObject]@{
    userPrincipalName = 'Bas@bwit.blog'
    displayName       = 'Bas Wijdenes'
    accountEnabled    = 'true'
    mailNickname      = 'bas@bwit.blog'
    passwordProfile   = [PSCustomObject]@{
        password                      = 'H78302ehpib'
        forceChangePasswordNextSignIn = 'true'
    }
}
```

Script and response:
```PowerShell
$Batch = [System.Collections.Generic.List[Object]]::new()
foreach ($User in $CreatedUsers) {
    $Object = [PSCustomObject]@{
        Url    = "/users"
        method = 'post'
        body   = $User
    }
    $Batch.Add($object)
}

Batch-Mga -InputObject $batch

id status code body
-- ------ ---- ----
1     201
10    201
11    201
12    201
13    201
14    201
15    201
16    201
17    201
18    201
19    201
2     201
```