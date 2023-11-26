# Convert-EntraIDUnifierUser

## Description
The `Convert-EntraIDUnifierUser` cmdlet will convert a Entra ID user account from a 'Cloud' account to a 'On-premises synced' account. This cmdlet will automaticly create the user account in Active Directory based on properties stored in the Entra ID user.

## Cmdlet Processing
The cmdlet processes the following actions in order:

1. Verifies that the Entra ID account isn't a Directory Synchronization Service Account.
2. Verifies that the Entra ID account isn't already directory sync'ed.
3. Generates a sAMAccountName from the Entra ID user UserPrincipalName property .
4. Checks the generated sAMAccountName length.
    - If the sAMAccountName length is over 15 characters the cmdlet will throw an error.
    - You may specify the `-AllowsAMAccountNameTruncation` switch to allow for automatic truncation of the sAMAccountName.
5. Verifies that the generated sAMAccountName and UserPrincipalName is available for use within Active Directory.
6. Verifies that the generated CN of the user is unqiue within the OU.
7. Builds an object containing user properties based on values within the Entra ID user account.
8. Attempts to create the Active Directory account.
9. Searches and retrieves the newly created Active Directory account.
10. Calls the `Sync-EntraIdInifierUser` cmdlet to hard match the newly created Active Directory account.

## Examples
``` powershell
$EntraIDUser = Get-AzureADUser -ObjectID "user@example.com"
$AccountPassword = Read-Host "New password" -AsSecureString

Convert-EntraIDUnifierUser -EntraIDUser $EntraIDUser -AccountPassword $AccountPassword
```

## Syntax

``` powershell
Convert-EntraIDUnifierUser
    [[-EntraIDUser] [Microsoft.Open.AzureAD.Model.User]]
    [[-AccountPassword] <SecureString>]
    [[-OUPath] <String>]
    [-ChangePasswordAtLogon]
    [-SkipAzureADModuleConnectionCheck]
    [-AllowsAMAccountNameTruncation]
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

### -AccountPassword 
Specifies a new password value for an account.

This value is stored as an encrypted string.

```yaml
Type: SecureString
Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ChangePasswordAtLogon
Indicates whether a password must be changed during the next logon attempt.

```yaml
Type: Switch
Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OUPath 
Specifies specifies the container or organizational unit (OU) for the user. When you do not specify the Path parameter, the cmdlet creates a user object in the default container for user objects in the domain.

```yaml
Type: String
Required: False
Position: Named
Default value: 
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

### -AllowsAMAccountNameTruncation 
Specifies if the cmdlet should automaticly truncate the sAMAccountName if the generated value is over 15 charaters.

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