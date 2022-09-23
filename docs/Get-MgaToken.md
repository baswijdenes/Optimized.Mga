---
external help file: Optimized.Mga-help.xml
Module Name: Optimized.Mga
online version: https://github.com/baswijdenes/Optimized.Mga/
schema: 2.0.0
---

# Get-MgaToken

## SYNOPSIS
Get-MgaToken will retreive a RefreshToken for the Microsoft Graph API.

## SYNTAX

### Certificate
```
Get-MgaToken -Certificate <Object> -ClientId <String> -TenantId <String> [-Force] [<CommonParameters>]
```

### ClientSecret
```
Get-MgaToken -Secret <String> -ClientId <String> -TenantId <String> [-Force] [<CommonParameters>]
```

### ManagedIdentity
```
Get-MgaToken [-Identity] [-ClientId <String>] [-TenantId <String>] [-Force] [<CommonParameters>]
```

### DeviceCode
```
Get-MgaToken [-DeviceCode] [-ClientId <String>] [-Force] [<CommonParameters>]
```

## DESCRIPTION
The AccessToken is automatically renewed when you use cmdlets.

## EXAMPLES

### EXAMPLE 1
```
Get-MgaToken -ClientSecret '1yD3h~.KgROPO.K1sbRF~XXXXXXXXXXXXX' -CliendId 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -TenantId 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX'
```

### EXAMPLE 2
```
$Cert = get-ChildItem 'Cert:\LocalMachine\My\XXXXXXXXXXXXXXXXXXX'
Get-MgaToken -Certificate $Cert -CliendId 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -TenantId 'XXXXXXXX.onmicrosoft.com'
```

### EXAMPLE 3
```
Get-MgaToken -Certificate '3A7328F1059E9802FAXXXXXXXXXXXXXX' -CliendId 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -TenantId 'XXXXXXXX.onmicrosoft.com'
```

### EXAMPLE 4
```
Get-MgaToken -Credential $Cred -TenantId 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX' -CliendId 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX'
```

### EXAMPLE 5
```
Get-MgaToken -Identity
```

### EXAMPLE 6
```
Get-MgaToken -DeviceCode
```

## PARAMETERS

### -Certificate
Use Certificate to get an AccessToken with a Certificate.
You can also use a Certificate thumbprint.

```yaml
Type: Object
Parameter Sets: Certificate
Aliases: Thumbprint

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Secret
Use a ClientSecret to get an AccessToken.

```yaml
Type: String
Parameter Sets: ClientSecret
Aliases: ClientSecret, AppSecret, AppPass

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Identity
Parameter is a switch, it can be used for when it's a Managed Identity authenticating to Microsoft Graph API.
Examples are: Azure Automation, Azure Functions, & Azure Virtual Machines.

```yaml
Type: SwitchParameter
Parameter Sets: ManagedIdentity
Aliases: ManagedIdentity, ManagedSPN

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceCode
Parameter is a switch and it will let you log in with a DeviceCode. 
It will open a browser window and you will have to log in with your credentials. 
You have 15 minutes before it cancels the request.

```yaml
Type: SwitchParameter
Parameter Sets: DeviceCode
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientId
CliendId is the AzureAD Application registration ObjectId.

```yaml
Type: String
Parameter Sets: Certificate, ClientSecret
Aliases: ApplicationID, AppID, App, Application

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: ManagedIdentity, DeviceCode
Aliases: ApplicationID, AppID, App, Application

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TenantId
TenantId is the TenantId or XXX.onmicrosoft.com address.

```yaml
Type: String
Parameter Sets: Certificate, ClientSecret
Aliases: Tenant

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: ManagedIdentity
Aliases: Tenant

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Use -Force when you want to overwrite the AccessToken with a new one.

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

