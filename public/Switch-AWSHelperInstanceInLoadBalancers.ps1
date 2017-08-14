<#
    .EXAMPLE
        Switch-AWSHelperInstanceInLoadBalancerss -CurrentInstanceID i-0210e383e3d655d40 -ReplacementInstanceID i-0085c230708198b6f -Region $Region -confirm:$false -verbose
        Switch-AWSHelperInstanceInLoadBalancers -CurrentInstanceID i-0085c230708198b6f -ReplacementInstanceID i-0210e383e3d655d40 -Region $Region -confirm:$false -verbose
#>
function Switch-AWSHelperInstanceInLoadBalancers{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CurrentInstanceID,
        [Parameter(Mandatory=$true)]
        [string]$ReplacementInstanceID,
        [Parameter(Mandatory=$true)]
        [string]$Region
    )
    $ELB2TargetGroups = Get-ELB2TargetGroup -Region $Region | select *, @{L="Targets";E={Get-ELB2TargetHealth -TargetGroupArn $_.TargetGroupArn -region $Region}}
    $ELB2TargetGroupsWithCurrentInstance = $ELB2TargetGroups | ?{$_.targets.Target.id -contains $CurrentInstanceID}

    foreach($ELB2TargetGroup in $ELB2TargetGroupsWithCurrentInstance){
        $CurrentInstanceTarget = $ELB2TargetGroup.targets.target | ?{$_.id -eq $CurrentInstanceID}
        Write-Verbose "Deregistering $CurrentInstanceID from $($ELB2TargetGroup.TargetGroupName)"
        Unregister-ELB2Target -TargetGroupArn $ELB2TargetGroup.TargetGroupArn -Target $CurrentInstanceTarget -region $Region

        Write-Verbose "Registering $ReplacementInstanceID from $($ELB2TargetGroup.TargetGroupName)"
        Register-ELB2Target -TargetGroupArn $ELB2TargetGroup.TargetGroupArn -Target @{Id=$ReplacementInstanceID;Port=$CurrentInstanceTarget.port} -region $Region
    }
    
    $ELBsWithCurrentInstance = Get-ELBLoadBalancer -Region $Region | ?{$_.Instances.instanceid -contains $CurrentInstanceID}
    
    foreach($ELB in $ELBsWithCurrentInstance){
        Write-Verbose "Deregistering $CurrentInstanceID from $($ELB.LoadBalancerName)"
        Remove-ELBInstanceFromLoadBalancer -Instance $CurrentInstanceID -LoadBalancerName $ELB.LoadBalancerName -region $Region
        Write-Verbose "Registering $ReplacementInstanceID with $($ELB.LoadBalancerName)"
        Register-ELBInstanceWithLoadBalancer -Instance $ReplacementInstanceID -LoadBalancerName $ELB.LoadBalancerName -region $Region | Out-Null
    }
}

