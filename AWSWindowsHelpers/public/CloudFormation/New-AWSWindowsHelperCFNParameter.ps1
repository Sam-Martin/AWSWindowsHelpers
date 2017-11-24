function New-AWSWindowsHelperCFNParameter
{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$True)]        
        [string]$key,
        [parameter(Mandatory=$True)]        
        [string]$value,
        [boolean]$usePreviousValue=$true
    )
    $cfnParameter = @{
        Key = $key
        Value = $value
        UsePreviousValue = $usePreviousValue
    }
    Return $cfnParameter
}