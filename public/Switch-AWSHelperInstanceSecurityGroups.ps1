<#
    .EXAMPLE
        Switch-AWSHelperInstanceSecurityGroups -CurrentInstanceID 'i-0210e383e3d655d40' -ReplacementInstanceID 'i-0085c230708198b6f' -Region eu-west-1
#>
function Switch-AWSHelperInstanceSecurityGroups{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CurrentInstanceID,
        [Parameter(Mandatory=$true)]
        [string]$ReplacementInstanceID,
        [Parameter(Mandatory=$true)]
        [string]$Region
    )
    $CurrentInstance = Get-EC2Instance -InstanceId $CurrentInstanceID -Region $Region | Select -ExpandProperty Instances
    $CurrentInstanceSGs = $CurrentInstance.SecurityGroups.groupid
    $ReplacementInstance = Get-EC2Instance -InstanceId $ReplacementInstanceID -Region $Region | Select -ExpandProperty Instances
    $ReplacementInstanceSGs = $ReplacementInstance.SecurityGroups.groupid

    Write-Verbose "Replacing $CurrentInstanceID security groups with those from $ReplacementInstanceID"
    Edit-EC2InstanceAttribute -InstanceId $CurrentInstanceID -Group $ReplacementInstanceSGs -Region $Region

    Write-Verbose "Replacing $ReplacementInstanceID security groups with those from $CurrentInstanceID"
    Edit-EC2InstanceAttribute -InstanceId $ReplacementInstanceID -Group $CurrentInstanceSGs -Region $Region

}

