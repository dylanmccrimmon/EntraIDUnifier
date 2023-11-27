# EntraIDUnifier

EntraIDUnifier is a small powershell modules that helps hard match and convert Entra ID cloud accounts to on-premises / hybrid accounts. It is able to create the accounts in Active Directory based on properties set on the Entra ID account. It can also hard match the Entra ID account to an exisiting Active Directory account.

Before using this module, its importent to note that the module assumes the following:

- The Entra ID account uses the UserPrincipalName as the on-premises attribute to use as the Entra ID account username
- The source anchor configured in Entra ID Connect is configured as `ObjectGUID` or `mS-DS-ConsistencyGuid`

## Documentation
The module exports the following cmdlets. Documentation for each cmdlet can be found in the docs folder or by clicking below.

[Convert-EntraIDUnifierUser](Docs/Convert-EntraIDUnifierUser.md)

[Sync-EntraIDUnifierUser](Docs/Sync-EntraIDUnifierUser.md)

## Installation
### Directly Download Github & Import on the fly
```PowerShell tab=
Invoke-WebRequest -Uri 'https://github.com/dylanmccrimmon/EntraIDUnifier/archive/refs/heads/main.zip' -OutFile "$($env:TEMP)\EntraIDUnifier-main.zip"; `
Expand-Archive -LiteralPath "$($env:TEMP)\EntraIDUnifier-main.zip" -DestinationPath "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules" -Force; `
Import-Module "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules\EntraIDUnifier-main\EntraIDUnifier\EntraIDUnifier.psd1" -Force
```

## Authors and acknowledgment
This module depends on the [AzureAD](https://www.powershellgallery.com/packages/AzureAD) that is authored and managed by Microsoft Corporation.

## License
This project is licensed under the GNU AGPLv3. For more information on the GNU AGPLv3, please read the [LICENSE](LICENSE) file.