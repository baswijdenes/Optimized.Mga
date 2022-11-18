---
external help file: Optimized.Mga-help.xml
Module Name: Optimized.Mga
online version: https://github.com/baswijdenes/Optimized.Mga/
schema: 2.0.0
---

# Set-Mga

## SYNOPSIS
Set-Mga is an Alias for the method Patch.

## SYNTAX

```
Set-Mga [-Uri] <String> -Body <Object> [-Api <String>] [-Batch] [-CustomHeader <Object>] [-ReturnAsJson]
 [<CommonParameters>]
```

## DESCRIPTION
Updates an object in the Azure AD tenant with the Microsoft Graph API. 
Json, XML, and CSV is converted to a PSObject.

## EXAMPLES

### EXAMPLE 1
```
$users = Get-Mga 'https://graph.microsoft.com/v1.0/users'
$UserList = [System.Collections.Generic.List[Object]]::new() 
foreach ($User in $users)
{
    $DirectoryObject = "https://graph.microsoft.com/v1.0/directoryObjects/$($User.id)"
    $UserList.Add($DirectoryObject)
}
$Body = [PSCustomObject] @{
    "members@odata.bind" = $UserList
}
Set-Mga -Uri 'https://graph.microsoft.com/v1.0/groups/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -Body $Body
```

## PARAMETERS

### -Uri
Uri to the Microsoft Graph API.
You can also use the last part of an Uri and the rest will be automatically added.
Example: /users
Example: https://graph.microsoft.com/v1.0/users
Example: users?$filter=displayName eq 'Bas Wijdenes'
Example: beta/users

```yaml
Type: String
Parameter Sets: (All)
Aliases: URL

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body
Body will accept a PSObject or a Json string.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: InputObject

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Api
This is not a mandatory parameter. 
By using v1.0 or beta it will always overwrite the value given in the Uri.
By using All it will first try v1.0 in a try and catch. and when it jumps to the catch it will use the beta Api.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Reference

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Batch
By using Batch you can patch multiple objects at once by using Batch-Mga. 
This will only work for a body that has the members@odata.bind property.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomHeader
This not a not mandatory parameter, there is a default header containing application/json.
By using this parameter you can add a custom header.
The CustomHeader is reverted back to the original after the cmdlet has run.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReturnAsJson
This is not a mandatory parameter. 
By using, this the output will be returned as Json.
When it cannot be converted to json, it will be returned as is.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/baswijdenes/Optimized.Mga/](https://github.com/baswijdenes/Optimized.Mga/)

[https://baswijdenes.com/c/microsoft/mga/](https://baswijdenes.com/c/microsoft/mga/)

