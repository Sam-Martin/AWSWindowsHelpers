Function Wait-AWSWindowsHelperInstanceToStop {
    Param(
        [Parameter(Mandatory=$true)]
        $Region,
        [Parameter(Mandatory=$true)]
        $InstanceID
    )

    While((Get-EC2Instance -InstanceId $InstanceID -Region $Region).Instances[0].State.Name -ne 'stopped'){
        Write-Verbose "Waiting for instance to stop"
        Start-Sleep -s 10
    }

}