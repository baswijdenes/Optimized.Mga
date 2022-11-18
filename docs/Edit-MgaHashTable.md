---
external help file: Optimized.Mga-help.xml
Module Name: Optimized.Mga
online version: https://github.com/baswijdenes/Optimized.Mga/
schema: 2.0.0
---

# Edit-MgaHashTable

## SYNOPSIS
Edits properties in the MgaSession HashTable in the script scope.

## SYNTAX

```
Edit-MgaHashTable [-Property] <Object> [-Body] <Object> [<CommonParameters>]
```

## DESCRIPTION
This will mostly be for testing purposes, but you can also remove the Content-Type from the headerParameters properties.

Not all properties will be overwritten since some are ReadOnly by default. 
Keep in mind that by editing these properties the module can stop functioning.

## EXAMPLES

### EXAMPLE 1
```
Edit-MgaHashTable -Property 'HeaderParameters.Content-Type' -Body '(Get-Date).AddHours(-2)'
```

## PARAMETERS

### -Property
This Parameter is mandatory & is the PropertyName.
You can add several subproperties by using 'property1.subproperty.subproperty'

```yaml
Type: Object
Parameter Sets: (All)
Aliases: Variable

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body
The body includes the content to overwrite the property with.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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

