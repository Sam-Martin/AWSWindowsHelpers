function New-AWSTestAMI {
    Param(
        [Parameter(Mandatory=$true)]
        $ID,
        [Parameter(Mandatory=$true)]
		$Region,
		[Parameter(Mandatory=$true)]
        $SubnetId,
        [Parameter(Mandatory=$true)]
        $BootSnapshotId,
        [Parameter(Mandatory=$false)]
        $VolumeSnapshotIds,
        $InstanceType = "m4.large",
        $AMIFilter = "Windows_Server-2012-R2_RTM-English-64Bit-Base*"
     )
    
    $EC2Instance = Restore-AWSTestWindowsInstanceFromSnapshot -SubnetId $SubnetId -Region $Region -BootSnapshotId $BootSnapshotId -ID $ID
    New-EC2Image -Name "PowerShellAWSTestAMI-$ID-$($EC2Instance.InstanceID)-$(Get-Date -F "yyyy-MM-dd-HH-mm")" -InstanceId $EC2Instance.InstanceId -Region $Region
    Remove-EC2Instance $EC2Instance.InstanceId -Region $Region -Force | Out-Null
}
