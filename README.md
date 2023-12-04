# EntraIDUnifier
![GitHub License](https://img.shields.io/github/license/dylanmccrimmon/EntraIDUnifier) ![GitHub release (with filter)](https://img.shields.io/github/v/release/dylanmccrimmon/EntraIDUnifier) ![PowerShell Gallery Version (including pre-releases)](https://img.shields.io/powershellgallery/v/EntraIDUnifier)


EntraIDUnifier is a small PowerShell module that helps hard match and convert Entra ID cloud accounts to on-premises / hybrid accounts. It can create accounts in Active Directory based on properties set on the Entra ID account. It can also hard match the Entra ID account to an existing Active Directory account.

Before using this module, it's important to note that the module assumes the following:

- The Entra ID account uses the UserPrincipalName as the on-premises attribute to use as the Entra ID account username
- The source anchor configured in Entra ID Connect is configured as `ObjectGUID` or `mS-DS-ConsistencyGuid`

## Documentation
The module exports the following cmdlets. Documentation for each cmdlet can be found in the docs folder or by clicking below.

[Convert-EntraIDUnifierUser](Docs/Convert-EntraIDUnifierUser.md)

[Sync-EntraIDUnifierUser](Docs/Sync-EntraIDUnifierUser.md)

> When using either cmdlet, if you want to test if there will be any error before making changes, you may use the `-OnlyVerifyActions` switch. You can also specify the `-Verbose` switch to show logs & current actions being performed.

## Installation
### From the PowerShell Gallery

Installing items from the Gallery requires the latest version of the PowerShellGet module, which is available in Windows 10, in Windows Management Framework (WMF) 5.0, or in the MSI-based installer (for PowerShell 3 and 4).

Open Powershell and run the following command:

```PowerShell
Install-Module -Name EntraIDUnifier
```
### Directly Download Github and import on the fly
```PowerShell
Invoke-WebRequest -Uri 'https://github.com/dylanmccrimmon/EntraIDUnifier/archive/refs/heads/main.zip' -OutFile "$($env:TEMP)\EntraIDUnifier-main.zip"; `
Expand-Archive -LiteralPath "$($env:TEMP)\EntraIDUnifier-main.zip" -DestinationPath "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules" -Force; `
Import-Module "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules\EntraIDUnifier-main\EntraIDUnifier\EntraIDUnifier.psd1" -Force
```

## Support
Need support or found a bug? No problem, just [raise an issue](https://github.com/dylanmccrimmon/EntraIDUnifier/issues). When creating a support issue, please add as much information as possible (code snippets, error messages, etc).


## Authors and acknowledgement
This module depends on the [AzureAD](https://www.powershellgallery.com/packages/AzureAD) and the [ActiveDirectory](https://learn.microsoft.com/en-us/powershell/module/activedirectory) modules that are authored and managed by Microsoft Corporation.

## License
This project is licensed under the GNU AGPLv3. For more information on the GNU AGPLv3, please read the [LICENSE](LICENSE) file.