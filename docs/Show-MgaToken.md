---
external help file: Optimized.Mga-help.xml
Module Name: Optimized.Mga
online version: https://github.com/baswijdenes/Optimized.Mga/
schema: 2.0.0
---

# Show-MgaToken

## SYNOPSIS
Use this cmdlet to retrieve the AccessToken decoded.

## SYNTAX

```
Show-MgaToken [[-AccessToken] <Object>] [-Roles] [<CommonParameters>]
```

## DESCRIPTION
Show-MgaToken is mainly used for troubleshooting permission errors to see which permissions are missing.

## EXAMPLES

### EXAMPLE 1
```
Show-MgaToken
```

### EXAMPLE 2
```
Show-MgaToken -Roles
```

## PARAMETERS

### -AccessToken
By leaving parameter AccessToken empty, it will use the AccessToken from the MgaSession variable.
You can also decode another AccessToken by using this parameter. 
For example from the official Microsoft SDK PowerShell module or webbrowser.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: ($Script:MgaSession.headerParameters).Authorization
Accept pipeline input: False
Accept wildcard characters: False
```

### -Roles
Use this Parameter to only see the roles in the AccessToken.

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

