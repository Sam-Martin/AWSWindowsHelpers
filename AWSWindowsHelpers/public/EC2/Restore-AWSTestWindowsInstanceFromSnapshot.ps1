function Restore-AWSTestWindowsInstanceFromSnapshot {
    [CmdletBinding()]
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
        $AMIFilter = "Windows_Server-2012-R2_RTM-English-64Bit-Base*",
        [scriptblock]$UserData
     )
     	
    $GetAMIIDParams = @{
	    Region = $Region 
	    Filters = @{Name = "name"; Values = $AMIFilter}
	    Owners = 801119661308
    }
	
    $AvailabilityZone = (Get-EC2Subnet -SubnetId $SubnetId -Region $Region).AvailabilityZone
	$AMIImageId = (Get-EC2Image @GetAMIIDParams).ImageId | select -first 1
    
	$EC2Reservation = New-EC2Instance -InstanceType $InstanceType -ImageId $AMIImageId -SubnetId $SubnetId -Region $Region
    $ReservationFilter = @{"name"="reservation-id";"values"=$EC2Reservation.ReservationID}
	$EC2Instance = (Get-EC2Instance -Filter $ReservationFilter -Region $Region)
    $EC2Instance = $EC2Instance.Instances[0]
    Write-Verbose "Created New Instance $($EC2Instance.InstanceId)"

    New-EC2Tag -Resource $EC2Instance.InstanceId -Tag @{Key="Name";Value="PowerShellAWSTestInstance-$ID-$(Get-Date -F "yyyy-MM-dd-HH-mm")"} -Region $Region
    New-EC2Tag -Resource $EC2Instance.InstanceId -Tag @{Key="PowerShellAWSTestHelperID";Value=$ID} -Region $Region
	

	While( (Get-EC2Instance -Filter $ReservationFilter -Region $Region).Instances.State.name.value -ne "running"){
		Write-Verbose "Waiting for instance to start"
		Start-Sleep -Seconds 10
	}

	Write-Verbose "Stopping Instance $($EC2Instance.InstanceID)"
	Stop-EC2Instance -InstanceId $EC2Instance.InstanceID -Region $Region  | Out-Null

	While( (Get-EC2Instance -InstanceID $EC2instance.InstanceID -Region $Region).Instances.State.name.value -ne "stopped"){
		Write-Verbose "Waiting for instance to stop"
		start-sleep -Seconds 10
	}
    
    if($VolumeSnapshotIds){
        $VolumeIds = @() 
	    Foreach ($SnapshotId in $VolumeSnapshotIds){
		    $VolumeIds += (New-EC2Volume -AvailabilityZone $AvailabilityZone -SnapshotId $SnapshotId -VolumeType gp2 -Region $Region).VolumeId
	    }
	    Write-Verbose "Created Volumes $VolumeIds"
    }

	$BootVolumeId = (New-EC2Volume -AvailabilityZone $AvailabilityZone -SnapshotId $BootSnapshotId -VolumeType gp2 -Region $Region).VolumeId
	Write-Verbose "Created BootVolume $BootVolumeId"

	 
	$VolumeFilter = @{"name"="volume-id";"values"=$VolumeIds+$BootVolumeId}
	While( (Get-EC2Volume -Filter $VolumeFilter -Region $Region).State.Value -ne "available"){
		Write-Verbose "Waiting for volume to become available"
		Start-Sleep -Seconds 10
	}


	$TempVolumeIds = (Get-EC2Volume -Filter @{"name"="attachment.instance-id";"values"=$EC2Instance.InstanceID} -Region $Region).VolumeId 
	Write-Verbose "Detaching AMI volumes $TempVolumeIds from $($EC2Instance.InstanceID)"

	Dismount-EC2Volume -VolumeId $TempVolumeIds -Region $Region | Out-Null

	Write-Verbose "Waiting for volumes to detach"
	Start-Sleep -Seconds 10
    Remove-EC2Volume -VolumeId $TempVolumeIds -Region $Region -Force | Out-Null

	Write-Verbose "Attaching restored BootVolume $BootVolumeId to Instance $($EC2Instance.InstanceID)"
	Add-EC2Volume -InstanceId $EC2Instance.InstanceID -VolumeId $BootVolumeId -Device "/dev/sda1" -Region $Region | Out-Null

	For($i=0; $i -lt $VolumeId.count; $i++){
		$device = "/dev/xvd{0}" -f $([char](102+$i))
		Write-Verbose "Attaching restored Volume $VolumeId to Instance $($EC2Instance.InstanceID) as $device"    
		Add-EC2Volume -InstanceId $EC2Instance.InstanceID -VolumeId $VolumeId -Device $device -Region $Region | Out-Null
	}

	Write-Verbose "Waiting for restored volumes to attach to instance $InstanceID sleeping 10 seconds "
	Start-Sleep -Seconds 10
    return $EC2Instance
}