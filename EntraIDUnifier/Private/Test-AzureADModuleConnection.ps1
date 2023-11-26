function Test-AzureADModuleConnection {

    Write-Verbose "Checking AzureAD module connection"

    try {
        Get-AzureADTenantDetail | Out-Null
        Write-Verbose "Azure AD module connected"
    } 
    catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] { 
        Throw "AzureAD needs to be connected before running functions with this module. Run Connect-AzureAD and try again."
    }

}
