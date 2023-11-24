# EntraIDUnifier


## Installation
<!-- ### From the PowerShell Gallery

Installing items from the Gallery requires the latest version of the PowerShellGet module, which is available in Windows 10, in Windows Management Framework (WMF) 5.0, or in the MSI-based installer (for PowerShell 3 and 4).

Open Powershell and run the following command:

```PowerShell tab=
Install-Module -Name EntraIDUnifier
``` -->

### Directly Download Github & Import on the fly
```PowerShell tab=
Invoke-WebRequest -Uri 'https://github.com/dylanmccrimmon/EntraIDUnifier/archive/refs/heads/main.zip' -OutFile "$($env:TEMP)\EntraIDUnifier-main.zip"; `
Expand-Archive -LiteralPath "$($env:TEMP)\EntraIDUnifier-main.zip" -DestinationPath "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules"; `
Import-Module "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules\EntraIDUnifier-main\EntraIDUnifier\EntraIDUnifier.psm1"
```