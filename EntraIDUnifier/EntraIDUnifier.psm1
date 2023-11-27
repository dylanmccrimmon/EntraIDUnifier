#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach($import in @($Public + $Private))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Set variables visible to the module and its functions only
$PSModuleRoot = $PSScriptRoot

# Export Public functions ($Public.BaseName) for WIP modules
Export-ModuleMember -Function $Public.Basename

# Write warning message
Write-Output "Before continuing to use this module, please read the documentation first. The documentation can be found on GitHub: https://github.com/dylanmccrimmon/EntraIDUnifier" -ForegroundColor Yellow