---
external help file: Optimized.Mga-help.xml
Module Name: Optimized.Mga
online version: https://github.com/baswijdenes/Optimized.Mga/
schema: 2.0.0
---

# Invoke-Mga

## SYNOPSIS
Invoke-Mga is a wrapper around the default Method cmdlets in the Mga module.

## SYNTAX

### Default (Default)
```
Invoke-Mga -Uri <Object> [-Body <Object>] -Method <Object> [-Api <Object>] [<CommonParameters>]
```

### Batch
```
Invoke-Mga [-Uri <Object>] -Body <Object> -Method <Object> [<CommonParameters>]
```

## DESCRIPTION
By using Invoke-Mga you do not have to change the way you use the default Method cmdlets in the Mga module.

## EXAMPLES

### EXAMPLE 1
```
Invoke-Mga -Uri 'https://graph.microsoft.com/v1.0/users' -Method 'GET'
```

### EXAMPLE 2
```
Invoke-Mga -Uri '/users' -Method 'Post' -Api 'beta' -Body $Body
```

### EXAMPLE 3
```
Invoke-Mga -Uri 'https://graph.microsoft.com/beta/groups' -Method 'Patch' -Api 'v1.0' -Body $Body
```

### EXAMPLE 4
```
Invoke-Mga -Uri 'beta/groups' -Method 'Delete' -Api 'All'
```

### EXAMPLE 5
```
Invoke-Mga -Method 'Batch' -Body $Body
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
Type: Object
Parameter Sets: Default
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Object
Parameter Sets: Batch
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body
Body will accept a PSObject, or a Json string for Post, Patch, Put, and Delete.
Body will accept an ArrayList for Batch.

```yaml
Type: Object
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Object
Parameter Sets: Batch
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Method
Type of Method to the Microsoft Graph Endpoint.
Methods are: Get, Post, Patch, Put, Delete, Batch.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Api
This is not a mandatory parameter. 
By using v1.0 or beta it will always overwrite the value given in the Uri.
By using All it will first try v1.0 in a try and catch.
and when it jumps to the catch it will use the beta Api.

```yaml
Type: Object
Parameter Sets: Default
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

