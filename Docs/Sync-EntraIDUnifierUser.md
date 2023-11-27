# Sync-EntraIDUnifierUser

## Description
The `Sync-EntraIDUnifierUser` cmdlet will hard match a Active Directory and a Entra ID user account.

## Cmdlet Processing
The cmdlet processes the following actions in order:

1. Verifies that the Entra ID user account isn't already directory sync'ed.
2. Generates an Immutable ID
3. Verifies that the Immutable ID isn't already in use within Entra ID.
4. Checks if the UserPrincipalName is the same between both accounts.
5. Adds any proxyAddresses stored in the Entra ID user properties to the Active Directory account.
6. Adds the Immutable ID to the Entra ID user account

## Examples
``` powershell
$EntraIDUser = Get-AzureADUser -ObjectID "user@example.com"
$ActiveDirectoryUser = Get-ADUser -Identity "user"

Sync-EntraIDUnifierUser -EntraIDUser $EntraIDUser -ActiveDirectoryUser $ActiveDirectoryUser
```

## Syntax

``` powershell
Sync-EntraIDUnifierUser
    [[-EntraIDUser] [Microsoft.Open.AzureAD.Model.User]]
    [[-ActiveDirectoryUser] [Microsoft.ActiveDirectory.Management.ADUser]]
    [-SkipEntraIDdirectorySyncedCheck]
    [-DontAddProxyAddresses]
    [-SkipAzureADModuleConnectionCheck]
    [-OnlyVerifyActions]
    [<CommonParameters>]
```

## Parameters

### -EntraIDUser 
Specifies the Entra ID user account object.

```yaml
Type: [Microsoft.Open.AzureAD.Model.User]
Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ActiveDirectoryUser 
Specifies the Active Directory user account object.

```yaml
Type: [Microsoft.ActiveDirectory.Management.ADUser]
Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipEntraIDDirectorySyncedCheck 
Specifies if the cmdlet should skip the test to see if the Entra ID user account is already directory synced.

> This paramater is useful when changing swapping the Active Directory account from one to another. Using this paramater will overwrite the Immutable ID that is set in Entra ID.

```yaml
Type: Switch
Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DontAddProxyAddresses 
Specifies if the cmdlet should skip adding proxy addresses to the Active Directory account.

```yaml
Type: Switch
Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipAzureADModuleConnectionCheck 
Specifies if the cmdlet should skip the test to see if the AzureAD module is connected.

```yaml
Type: Switch
Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnlyVerifyActions 
Specifies if the cmdlet should only verify inputs. This will not make any account updates or creations.

```yaml
Type: Switch
Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```