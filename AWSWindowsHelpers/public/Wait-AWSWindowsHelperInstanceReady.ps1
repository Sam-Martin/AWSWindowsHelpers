function Wait-AWSWindowsHelperInstanceReady{
    param(
        [string]$InstanceID,
        [string]$Region
    )
    while(
        ((Get-EC2InstanceStatus -InstanceId $instanceid -Region $region).status | ?{$_.Details.name -eq 'reachability'}).Status.Value -ne 'ok'
    ){
        Write-Verbose "Waiting for $InstanceID's reachability checks to be Okay"
        Start-Sleep -Seconds 10
    }
}