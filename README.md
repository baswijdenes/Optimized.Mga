# Optimized.Mga
!!! IMPORTANT UPDATES! PLEASE SEE RELEASE NOTES [3.0.3.md](./CHANGELOG.md) !!!

Don't you wish you have a Microsoft Graph module which handles batching, the token and throttling for you, but where you can just enter your own URL, so you aren't restricted to the limitations of the official Microsoft Module and even includes a way to speed up the process?

* [PowerShell Gallery](https://www.powershellgallery.com/packages/Optimized.Mga)
* [Submit an issue](https://github.com/baswijdenes/Optimized.Mga/issues)
* [My blog](https://baswijdenes.com/)

---
## CHANGELOG
* [CHANGELOG](./CHANGELOG.md)

---
## Submodules dependent on Optimized.Mga:
- [Optimized.Mga.Report](https://github.com/baswijdenes/Optimized.Mga.Report)
- [Optimized.Mga.SharePoint](https://github.com/baswijdenes/Optimized.Mga.SharePoint)
- [Optimized.Mga.Mail](https://github.com/baswijdenes/Optimized.Mga.Mail)
- [Optimized.Mga.AzureAD](https://github.com/baswijdenes/Optimized.Mga.AzureAD)

---
## Optimized.Mga Cmdlets

* [Get-MgaToken](./docs/Get-MgaToken.md)
* [Remove-MgaToken](./docs/Remove-MgaToken.md)
* [Show-MgaToken](./docs/Show-MgaToken.md)
  
* [Get-Mga](./docs/Get-Mga.md)
* [New-Mga](./docs/New-Mga.md)
* [Add-Mga](./docs/Add-Mga.md)
* [Set-Mga](./docs/Set-Mga.md)
* [Remove-Mga](./docs/Remove-Mga.md)

* [Group-Mga](./docs/Group-Mga.md)
* [Invoke-Mga](./docs/Invoke-Mga.md)

* [Get-MgaHashTable](./docs/Get-MgaHashTable.md)
* [Edit-MgaHashTable](./docs/Edit-MgaHashTable.md)

---
## Are you new with the Microsoft Graph API? 
* [Here is a link to the official Microsoft Graph API SDK for PowerShell](https://docs.microsoft.com/en-us/graph/powershell/get-started)
* [Here is a link to post on my blog about starting with Microsoft Graph API](https://bwit.blog/how-to-start-with-microsoft-graph-in-powershell/)

---
## What makes your module different from the official Microsoft Graph SDK for PowerShell?
* [Speed](#Speed)
* [Usability](#Usability)
* [Bulk](#Bulk)

---
### Speed
The main difference is **speed**.

`Group-Mga` doesn't lie.
When I use Measure-Command while creating 10,000 users via the Post command it takes about 41 minutes:

```PowerShell
$CreatedUsers.count
10000
Measure-Command {
    foreach ($User in $CreatedUsers) {
        try {
            New-Mga -URL 'https://graph.microsoft.com/v1.0/users' -Body $User
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
When I create the same users via `Group-Mga`, it's 10 minutes:
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
    Group-Mga -Body $Batch
}

Minutes           : 9
Seconds           : 43
Milliseconds      : 152
```

`Group-Mga` will take care of the limitations (20 requests per batch) and will sleep for the amount of time a throttle limit is returned and then continue.

### Usability
The second difference is **usability**.
If you look at the official module you will see 33 dependencies.
I made my module so that you only need 8 cmdlets.

The main cmdlet is of course `Group-Mga`, by using Fiddler, or the browser developer tools you can find the URL when navigating through AzureAD and use it in one of the cmdlets. 

For example the below URL is from the Intune Management GUI and found with Fiddler. It will get the Windows compliant devices and will only select the ComplianceState and UserPrincipalname.
```powershell
$URL = 'https://graph.microsoft.com/beta/deviceManagement/managedDevices?$filter={0}&$top=999&$select=userPrincipalName,complianceState' -f "complianceState%20eq%20'Compliant'%20and%20operatingSystem%20eq%20'Windows'"
Get-Mga -URL $URL
```

### Bulk
`Set-Mga` with parameters `-Body` and `-Batch` and with the Property `members@odata.bind` will automatically be batched. So, in theory you can add 10000 users to a Group instantly. While throttling is handled for you.
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

Set-Mga -URL 'https://graph.microsoft.com/v1.0/groups/ac252320-4194-402f-8182-2d14e4a2db5c' -Body $PostBody -Verbose
```

Same goes for `Remove-Mga`. When parameter `-URL` is an Array, it will automatically batch your request:
```PowerShell
$Groupusers = Get-Mga -URL 'https://graph.microsoft.com/v1.0/groups/ac252320-4194-402f-8182-2d14e4a2db5c/members'
$UserList = @()
foreach ($User in $Groupusers) {
    $URL = 'https://graph.microsoft.com/v1.0/groups/ac252320-4194-402f-8182-2d14e4a2db5c/members/{0}/$ref' -f $User.Id
    $UserList += $URL
}
Remove-Mga -URL $UserList
```