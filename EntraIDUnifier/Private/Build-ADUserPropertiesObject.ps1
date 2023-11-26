function Build-ADUserPropertiesObject {
    Param( 
        [Parameter(
            Mandatory=$true)]
        [Microsoft.Open.AzureAD.Model.User] $EntraIDUser,
        [Parameter(
            Mandatory=$false)]
        [Hashtable] $AttributeMappings
    )

    $ActiveDirectoryUserPropertiesObject = [PSCustomObject]@{}

    # If there isn't any Attribute mappings, lets default
    if (!($AttributeMappings)) {

        $AttributeMappings = @{
            # Identity
            'Enabled'           = 'AccountEnabled'
            'GivenName'         = 'GivenName'
            'Surname'           = 'Surname'
            'DisplayName'       = 'DisplayName'
            'Name'              = 'DisplayName'
            
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
            'Fax'           = 'FacsimileTelephoneNumber'
        }

    }

    # Loop through AttributeMappings and add to the $NewActiveDirectoryUser object
    foreach ($Attribute in $AttributeMappings.GetEnumerator()) {

        if ($null -ne $EntraIDUser."$($Attribute.Value)") {
            Write-Verbose "Adding '$($Attribute.Name)' property to Active Directory user object from Entra ID property '$($Attribute.Value)'"
            $ActiveDirectoryUserPropertiesObject | Add-Member -MemberType NoteProperty -Name $Attribute.Name -Value $EntraIDUser."$($Attribute.Value)"
        }

    }
    
    return $ActiveDirectoryUserPropertiesObject
}