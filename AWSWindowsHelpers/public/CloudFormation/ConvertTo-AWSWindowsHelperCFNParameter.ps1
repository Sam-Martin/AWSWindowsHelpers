function ConvertTo-AWSWindowsHelperCFNParameter
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [hashtable]$cfnParamHashTable,
        [boolean]$usePreviousValue=$true
    )
    $cfnParameterArray = @()

    foreach($item in $cfnParamHashTable.GetEnumerator())
    {
        $cfnParameterArray += @{
            Key = $item.Name
            Value = $item.Value
            UsePreviousValue = $usePreviousValue
        }
    }
   Return $cfnParameterArray
}
