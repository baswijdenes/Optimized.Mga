---
external help file: Optimized.Mga-help.xml
Module Name: Optimized.Mga
online version: https://github.com/baswijdenes/Optimized.Mga/
schema: 2.0.0
---

# Group-Mga

## SYNOPSIS
Group-Mga is for speed and bulk.
See the related link for more.

## SYNTAX

```
Group-Mga [-Body] <Object> [[-Headers] <String>] [-Beta] [<CommonParameters>]
```

## DESCRIPTION
Group-Mga will take care of the limitations (20 requests per batch) and will sleep for the amount of time a throttle limit is returned and then continue.

## EXAMPLES

### EXAMPLE 1
```
$Users = Get-Mga -URL 'https://graph.microsoft.com/v1.0/users?$top=999'
$Batch = [System.Collections.Generic.List[Object]]::new()
foreach ($User in $Users) {
    $Object = [PSCustomObject]@{
        url    = "/directory/deletedItems/$($User.id)"
        method = 'delete'
    }
    $Batch.Add($Object)
}
Group-Mga -Body $Batch
```

### EXAMPLE 2
```
$Batch = [System.Collections.Generic.List[Object]]::new()
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
Group-Mga -Body $Batch
```

## PARAMETERS

### -Body
Body will accept an ArrayList.
See the examples for more information.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: InputObject, Batch

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Headers
This not a not mandatory parameter, there is a default header containing application/json.
You can manually change the header for the Batch, but this will change the header for all items in the ArrayList.

```yaml
Type: String
Parameter Sets: (All)
Aliases: CustomHeader

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Beta
Use this for when you want to use the beta reference. 
By default it's v1.0.

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

