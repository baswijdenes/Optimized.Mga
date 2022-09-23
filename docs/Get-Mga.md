---
external help file: Optimized.Mga-help.xml
Module Name: Optimized.Mga
online version: https://github.com/baswijdenes/Optimized.Mga/
schema: 2.0.0
---

# Get-Mga

## SYNOPSIS
Get-Mga is an Alias for the method Get.

## SYNTAX

```
Get-Mga [-Uri] <String> [-SkipNextLink] [-Reference <String>] [-CustomHeader <Object>] [<CommonParameters>]
```

## DESCRIPTION
Gets an object in the Azure AD tenant with the Microsoft Graph API. 
Json, XML, and CSV is converted to a PSObject.

## EXAMPLES

### EXAMPLE 1
```
Get-Mga -Uri 'v1.0/users' -SkipNextLink
```

### EXAMPLE 2
```
Get-Mga -Uri 'users?$top=999'
```

### EXAMPLE 3
```
Get-Mga -Uri 'https://graph.microsoft.com/v1.0/users/Testuser@baswijdenes.com'
```

### EXAMPLE 4
```
$Uri = 'https://graph.microsoft.com/v1.0/users?$select=id,userPrincipalName,lastPasswordChangeDateTime,createdDateTime,PasswordPolicies'
Get-Mga -Uri $Uri -Reference 'All'
```

### EXAMPLE 5
```
$Uri = '/beta/users?$filter=(UserType eq 'Guest')&$select=displayName,userPrincipalName,createdDateTime,signInActivity'
Get-Mga -Uri $Uri -Reference 'v1.0'
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

### -SkipNextLink
When you use this switch it will only return the first data result of the response without checking the NextDataLink URL.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: Once

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Reference
This is not a mandatory parameter. 
By using v1.0 or beta it will always overwrite the value given in the Uri.
By using All it will first try v1.0 in a try and catch.
and when it jumps to the catch it will use the beta reference.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/baswijdenes/Optimized.Mga/](https://github.com/baswijdenes/Optimized.Mga/)

[https://baswijdenes.com/c/microsoft/mga/](https://baswijdenes.com/c/microsoft/mga/)

