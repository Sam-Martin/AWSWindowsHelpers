<#
.Synopsis
   Returns the type of the supplied resource value
.DESCRIPTION
   Returns the type of the supplied resource value
.EXAMPLE
   Get-AWSWindowsHelpersARNResourceType -arnResourceValue "2017_wild_example_com"
.INPUTS
   arnResourceValue - The resource value to retrieve the type
.OUTPUTS
   Returns a object with the following properties

.FUNCTIONALITY
   Retrieves the type of the ARN resource value
#>
Function Get-AWSWindowsHelpersARNResourceType
{
    Param(
        [Parameter(Mandatory=$true)]
        $arnResourceValue      
    )

    $digitCount = Select-string "(\d){1}" -input $arnResourceValue -AllMatches
    $digitCount = $digitCount.Matches.Count

    if ($arnResourceValue -match "(^[a-zA-Z]{1,3}-\d{2}[\w\-]{3,})|([\d\-]{4,})" -or $digitCount -gt 7 )
    {
        $resourceType = "id"
        Write-Verbose "Resource value [$arnResourceValue] is a id"
    }
    elseif($arnResourceValue -match "(^app$|^net$)")
    {
        $resourceType = "type"
        Write-Verbose "Resource value [$arnResourceValue] is a type"
    }
    else
    {
        $resourceType = "name"
        Write-Verbose "Resource value [$arnResourceValue] is a name"
    }

    $resourceType
}
