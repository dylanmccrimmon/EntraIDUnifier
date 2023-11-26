function Convert-EntraIDUnifierUser
{
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$true)]
        [Microsoft.Open.AzureAD.Model.User] $EntraIDUser,
        [Parameter(
            Mandatory=$true)]
        [SecureString] $AccountPassword,
        [Parameter(
            Mandatory=$false)]
        [Switch] $ChangePasswordAtLogon,
        [Parameter(
            Mandatory=$false)]
        [System.String] $OUPath = 'CN=Users,' + (Get-ADRootDSE -Properties supportedExtension).defaultNamingContext,
        [Parameter(
            Mandatory=$false)]
        [Switch] $SkipAzureADModuleConnectionCheck,
        [Parameter(
            Mandatory=$false)]
        [Switch] $AllowsAMAccountNameTruncation,
        [Parameter(
            Mandatory=$false)]
        [Switch] $OnlyVerifyActions
    )

    # Check if AzureAD is connected
    if ($SkipAzureADModuleConnectionCheck.IsPresent) {
        Write-Verbose "Skipping AzureAD module connection check"
    } else {
        Test-AzureADModuleConnection
    }

    # Update the passed $EntraIDUser with data from EntraID
    try {
        Write-Verbose "Updating the EntraIDUser object with data from Entra ID"
        $EntraIDUser = Get-AzureADUser -ObjectId $EntraIDUser.ObjectId -ErrorAction Stop
        Write-Verbose "EntraIDUser object has been updated"
    }
    catch {
        Write-Verbose "Unable to update EntraIDUser object with data from Entra ID. Error $($Error[0])"
    }
    
    # Check that the account isn't a Directory Synchronization Service Account
    Write-Verbose "Checking if Microsoft Entra ID user is a On-Premises Directory Synchronization Service Account"
    if ($EntraIDUser.DisplayName -eq 'On-Premises Directory Synchronization Service Account') {
        Throw "The passed Microsoft Entra ID user looks to be a On-Premises Directory Synchronization Service Account."
    }
    
    # Check if the Microsoft Entra ID user directory synced 
    Write-Verbose "Checking if Microsoft Entra ID user is already directory synced"
    if ($EntraIDUser.DirSyncEnabled) {
        Throw "Microsoft Entra ID user already synced with Microsoft Entra Connect. This user looks to already be synced with Microsoft Entra Connect."
    }

    # Generating a sAMAccountName from the UserPrincipalName
    Write-Verbose "Generating sAMAccountName for the user"
    $GeneratedsAMAccountName = $EntraIDUser.UserPrincipalName.Split("@")[0]


    # Check the generated sAMAccountName length. Microsoft Active Directory has a max length of 15 characters of the sAMAccountName attribute
    Write-Verbose "Checking the generated sAMAccountName length"
    if ($GeneratedsAMAccountName.Length -gt 15) {

        $GeneratedsAMAccountName = $GeneratedsAMAccountName.substring(0,15)

        if ($AllowsAMAccountNameTruncation.IsPresent) {
            Write-Verbose "AllowsAMAccountNameTruncation switch is present. Automatically truncating the sAMAccountName"
        } else {
            Throw "The generated sAMAccountName is over the 15 character limit ('$($EntraIDUser.UserPrincipalName.Split("@")[0])')."
        }

    }

    Write-Verbose "Generated sAMAccountName is '$($GeneratedsAMAccountName)'"

    # Check if the UserPrincipalName & SamAccountName is already in use
    Write-Verbose "Checking if the sAMAccountName is available for use to use within Active Directory"
    $sAMAccountNameSearchCheck = Get-ADUser -Filter "sAMAccountName -like '$($GeneratedsAMAccountName)'"
    if ($sAMAccountNameSearchCheck) {
        Throw "The generated sAMAccountName ('$($GeneratedsAMAccountName)') is already in use within Active Directory"
    }
    
    Write-Verbose "Checking if the UserPrincipalName is available for use to use within Active Directory"
    $UserPrincipalNameSearchCheck = Get-ADUser -Filter "UserPrincipalName -like '$($EntraIDUser.UserPrincipalName)'"
    if ($UserPrincipalNameSearchCheck) {
        Throw "The generated UserPrincipalName is already in use within Active Directory"
    }

    # Check if the object name is already in use in the path 
    ## The display name is used as the cn by default in active directory
    if ($EntraIDUser.DisplayName -in (Get-ADObject -Filter * -SearchBase $OUPath).Name) {
        Throw "The proposed CN is already in use in the '$OUPath' OU"
    }

    # Building new user object
    Write-Verbose "Building Active Directory user object"
    $NewActiveDirectoryUser = Build-ADUserPropertiesObject -EntraIDUser $EntraIDUser

    # Add AccountPassword to the $NewActiveDirectoryUser object
    Write-Verbose "Adding 'AccountPassword' property to Active Directory user object from passed parameter"
    $NewActiveDirectoryUser | Add-Member -MemberType NoteProperty -Name 'AccountPassword' -Value $AccountPassword

    # Add ChangePasswordAtLogon if Present in the switch parameters 
    if ($ChangePasswordAtLogon.IsPresent) {
        Write-Verbose "Adding 'ChangePasswordAtLogon' property to Active Directory user object as -ChangePasswordAtLogon parameter switch is present"
        $NewActiveDirectoryUser | Add-Member -MemberType NoteProperty -Name 'ChangePasswordAtLogon' -Value $True
    }

    # Add UserPrincipalName to the $NewActiveDirectoryUser object
    Write-Verbose "Adding 'UserPrincipalName' property to Active Directory user object from generated value"
    $NewActiveDirectoryUser | Add-Member -MemberType NoteProperty -Name 'UserPrincipalName' -Value $EntraIDUser.UserPrincipalName

    # Add sAMAccountName to the $NewActiveDirectoryUser object
    Write-Verbose "Adding 'sAMAccountName' property to Active Directory user object from generated value"
    $NewActiveDirectoryUser | Add-Member -MemberType NoteProperty -Name 'sAMAccountName' -Value $GeneratedsAMAccountName
    
    # Add Path in the pass variables
    Write-Verbose "Adding 'Path' property to Active Directory user object."
    $NewActiveDirectoryUser | Add-Member -MemberType NoteProperty -Name 'Path' -Value $OUPath

    # Check if we can run create and update actions
    if (!$OnlyVerifyActions.IsPresent) {

        # Attempt to create active direcory user account with the the $NewActiveDirectoryUser object
        try {
            Write-Verbose "Attempting to create Active Directory user account"
            $NewActiveDirectoryUser | New-AdUser -ErrorAction Stop
            Write-Verbose "Active Directory user account has been created"
        } catch {
            Write-Error "Unable to create Active Directory user account. Error $($Error[0])" -ErrorAction Stop
        }
        
        # Attempt to get the newly created active directory user account
        try {
            Write-Verbose "Attempting to get the newly created Active Directory user account"
            $NewActiveDirectoryUser = Get-AdUser -Identity $GeneratedsAMAccountName
        } catch {
            Write-Error "Unable to get the newly Active Directory user account" -ErrorAction Stop
        }

        # Attempt to sync the newly created account with Entra ID
        try {
            Write-Verbose "Attempting to sync the Microsoft Entra ID user to the newly created Active Directory Account"
            Sync-EntraIDUnifierUser -EntraIDUser $EntraIDUser -ActiveDirectoryUser $NewActiveDirectoryUser -SkipAzureADModuleConnectionCheck:$true
            Write-Verbose "Microsoft Entra ID user has been updated to sync with the newly created Active Directory Account"
        }
        catch {
            Write-Error "Unable to sync the newly create Active Directory account with Entra ID. Error $($Error[0])"
        }

    } else {

        Write-Verbose "The OnlyVerifyActions switch parameter has been passed. Not adding or making changes to the account"

    }


}