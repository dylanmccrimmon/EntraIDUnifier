function Sync-EntraIDUnifierUser
{
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$true)]
        [Microsoft.Open.AzureAD.Model.User] $EntraIDUser,
        [Parameter(
            Mandatory=$true)]
        [Microsoft.ActiveDirectory.Management.ADUser] $ActiveDirectoryUser,
        [Parameter(
            Mandatory=$false)]
        [Switch] $SkipAzureADModuleConnectionCheck,
        [Parameter(
            Mandatory=$false)]
        [Switch] $SkipEntraIDDirectorySyncedCheck
    )

    # Check if AzureAD is connected
    if ($SkipAzureADModuleConnectionCheck.IsPresent) {
        Write-Verbose "Skipping AzureAD module connection check"
    } else {
        Test-AzureADModuleConnection
    }

    try {
        Write-Verbose "Updating the EntraIDUser object with data from Entra ID"
        $EntraIDUser = Get-AzureADUser -ObjectId $EntraIDUser.ObjectId -ErrorAction Stop
        Write-Verbose "EntraIDUser object has been updated"
    }
    catch {
        Write-Verbose "Unable to update EntraIDUser object with data from Entra ID. Error $($Error[0])"
    }
    
    # Check if the Microsoft Entra ID user directory synced 
    if ($SkipEntraIDDirectorySyncedCheck.IsPresent) {
        Write-Verbose "Skipping Microsoft Entra ID user directory synced check"
    } else {
        Write-Verbose "Checking if Microsoft Entra ID user is already directory synced"
        if ($EntraIDUser.DirSyncEnabled) {
            Throw "Microsoft Entra ID user already synced with Microsoft Entra Connect. This user looks to already be synced with Microsoft Entra Connect."
        }
    }

    # Generate Immutable ID
    $ImmutableID = Get-ImmutableID $ActiveDirectoryUser.ObjectGuid
    Write-Verbose "Generated a Immutable ID of '$ImmutableID' from active directory object guid"

    # Check if the Active Directory account is already synced with Entra ID
    Write-Verbose "Checking if the Active Directory account is already synced with Entra ID"
    if ($null -ne (Get-AzureADUser -Filter "ImmutableID eq '$($ImmutableID)'")) {
        Throw "The Active Directory account is already synced with Entra ID"
    }

    # Check UserPrincipalName - If using the onmicrosoft address then check the part before @ otherwise check full UserPrincipalName
    Write-Verbose "Checking if the UserPrincipalName matches between the two accounts"
    if (($EntraIDUser.UserPrincipalName.Split("@")[1] -like '*.onmicrosoft.com')) {
        if (($EntraIDUser.UserPrincipalName.Split("@")[0] -ne $ActiveDirectoryUser.UserPrincipalName.Split("@")[0])) {
            $DifferentUserPrincipalName = $true
        }
    } elseif ($ActiveDirectoryUser.UserPrincipalName -ne $EntraIDUser.UserPrincipalName) {
        $DifferentUserPrincipalName = $true
    }

    if ($DifferentUserPrincipalName) {
        Write-Warning "The accounts different UserPrincipalName that will likely change once Microsoft Entra Connect syncs, should we continue?" -WarningAction Inquire
    }

    # Create array of proxy address to add to the user later
    Write-Verbose "Creating ProxyAddress array to add to user"
    $ProxyAddresses = @()
    foreach ($ProxyAddress in $EntraIDUSer.ProxyAddresses) {

        # Ignore the primary proxyaddress as this should match the UserPrincipalName
        if (($ProxyAddress -clike 'SMTP:*') -and ($ProxyAddress -like "*:$($EntraIDUser.UserPrincipalName)")) {
            Write-Verbose "The proxy address '$($ProxyAddress)' matches the UserPrincipalName. This proxy address will not be added to the array"
        } else {
            Write-Verbose "Adding proxy address '$($ProxyAddress)' to the array"
            $ProxyAddresses += $ProxyAddress
        }

    }

    # Add proxy addresses
    Write-Verbose "Checking if proxy address need to be added to the user"
    if ($ProxyAddresses.Count -ge 1) {
        Write-Verbose "One or more proxy address need to be added"
        try {
            Write-Verbose "Attempting to add proxy addresses to the Active Directory user account"
            Set-ADUser $ActiveDirectoryUser -Add @{proxyAddresses=$ProxyAddresses}
        } catch {
            Throw "Unable to add proxy addresses to the Active Directory user account"
        }
    }

    # Run Main
    try {
        Write-Verbose "Attempting to update Microsoft Entra ID user's Immutable ID"
        Set-AzureADUser -ObjectId $EntraIDUser.ObjectId -ImmutableId $ImmutableId
        Write-Verbose "Microsoft Entra ID user's Immutable ID has been updated"
    }
    catch {
        Throw "Unable to update Immutable ID. Error $($Error[0])"
    }

}

