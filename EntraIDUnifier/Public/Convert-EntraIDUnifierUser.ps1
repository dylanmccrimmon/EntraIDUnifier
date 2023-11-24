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
        Test-AzureADConnect
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
        Write-Error "The passed Microsoft Entra ID user looks to be a On-Premises Directory Synchronization Service Account." -ErrorAction Stop
    }
    
    # Check if Entra ID User already has a immutable id 
    Write-Verbose "Checking if Microsoft Entra ID user already has a Immutable ID"
    if ($null -ne $EntraIDUser.ImmutableId) {
        Write-Error "Microsoft Entra ID user already has a Immutable ID. This user looks to already be synced with Microsoft Entra Connect." -ErrorAction Stop
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
            Write-Warning "The generated sAMAccountName is over the 15 character limit. The sAMAccountName will be truncated to '$GeneratedsAMAccountName', should we continue?" -WarningAction Inquire
        }

    }

    Write-Verbose "Generated sAMAccountName is '$($GeneratedsAMAccountName)'"

    # Check if the UserPrincipalName & SamAccountName is already in use
    Write-Verbose "Checking if the sAMAccountName is available for use to use within Active Directory"
    $sAMAccountNameSearchCheck = Get-ADUser -Filter "sAMAccountName -like '$($GeneratedsAMAccountName)'"
    if ($sAMAccountNameSearchCheck) {
        Write-Error "The generated sAMAccountName is already in use within Active Directory" -ErrorAction Stop
    }
    
    Write-Verbose "Checking if the UserPrincipalName is available for use to use within Active Directory"
    $UserPrincipalNameSearchCheck = Get-ADUser -Filter "UserPrincipalName -like '$($EntraIDUser.UserPrincipalName)'"
    if ($UserPrincipalNameSearchCheck) {
        Write-Error "The generated UserPrincipalName is already in use within Active Directory" -ErrorAction Stop
    }

    # Check if the object name is already in use in the path 
    ## The display name is used as the cn by default in active directory
    if ($EntraIDUser.DisplayName -in (Get-ADObject -Filter * -SearchBase $OUPath).Name) {
        Write-Error "The proposed CN is already in use in the '$OUPath' OU" -ErrorAction Stop
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

    # Building new user object
    Write-Verbose "Building Active Directory user object"
    $NewActiveDirectoryUser = [PSCustomObject]@{}

    ## To Do - Add employee id and employee type
    $AttributeMappings = @{
        # Identity
        'Enabled'           = 'AccountEnabled'
        'GivenName'         = 'GivenName'
        'Surname'           = 'Surname'
        'DisplayName'       = 'DisplayName'
        'Name'              = 'DisplayName'
        'UserPrincipalName' = 'UserPrincipalName'
        
        # Job Infomation
        'Title'         = 'JobTitle'
        'Department'    = 'Department'
        'Company'       = 'Company'
        'Office'        = 'PhysicalDeliveryOfficeName'

        # Contact Infomation
        'StreetAddress' = 'StreetAddress'
        'City'          = 'City'
        'State'         = 'State'
        'PostalCode'    = 'PostalCode'
        #'Country'       = 'Country'
        'OfficePhone'   = 'TelephoneNumber'
        'MobilePhone'   = 'Mobile'
        'Fax'           =  'FacsimileTelephoneNumber'
    }

    # Loop through AttributeMappings and add to the $NewActiveDirectoryUser object
    foreach ($Attribute in $AttributeMappings.GetEnumerator()) {

        if ($null -ne $EntraIDUser."$($Attribute.Value)") {
            Write-Verbose "Adding '$($Attribute.Name)' property to Active Directory user object from Entra ID property '$($Attribute.Value)'"
            $NewActiveDirectoryUser | Add-Member -MemberType NoteProperty -Name $Attribute.Name -Value $EntraIDUser."$($Attribute.Value)"
        }

    }

    # Add AccountPassword to the $NewActiveDirectoryUser object
    Write-Verbose "Adding 'AccountPassword' property to Active Directory user object from passed parameter"
    $NewActiveDirectoryUser | Add-Member -MemberType NoteProperty -Name 'AccountPassword' -Value $AccountPassword

    # Add ChangePasswordAtLogon if Present in the switch parameters 
    if ($ChangePasswordAtLogon.IsPresent) {
        Write-Verbose "Adding 'ChangePasswordAtLogon' property to Active Directory user object as -ChangePasswordAtLogon parameter switch is present"
        $NewActiveDirectoryUser | Add-Member -MemberType NoteProperty -Name 'ChangePasswordAtLogon' -Value $True
    }

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

        # Add proxy addresses
        Write-Verbose "Checking if proxy address need to be added to the user"
        if ($ProxyAddresses.Count -ge 1) {
            Write-Verbose "One or more proxy address need to be added"
            try {
                Write-Verbose "Attempting to add proxy addresses to the Active Directory user account"
                Set-ADUser $NewActiveDirectoryUser -Add @{proxyAddresses=$ProxyAddresses}
            } catch {
                Write-Error "Unable to add proxy addresses to the Active Directory user account"
            }
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