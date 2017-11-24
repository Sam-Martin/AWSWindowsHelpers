function ConvertTo-AWSWindowsHelperCFNParameter
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [hashtable]$cfnParamHashTable
    )
    $cfnParameterArray = @()

    foreach($item in $cfnParamHashTable.GetEnumerator())
    {
        $cfnParameterArray += New-AWSWindowsHelperCFNParameter -key $item.Name -value $item.Value
    }
   Return $cfnParameterArray
}