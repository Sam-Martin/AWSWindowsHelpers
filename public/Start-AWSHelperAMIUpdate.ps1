function Start-AWSHelperAMIUpdate{
    Param(
        [Parameter(Mandatory=$true)]
        $ID,
        [Parameter(Mandatory=$true)]
        $AMIID,
        [Parameter(Mandatory=$true)]
        $Region,
        [Parameter(Mandatory=$true)]
        $SubnetId,
        [Parameter(Mandatory=$true)]
        $InstanceProfileName,
        $InstanceType = "m4.large",
        $KeyName
    )
    

    $EC2InstanceParams = @{
        InstanceType = $InstanceType
        ImageId = $AMIID
        SubnetId = $SubnetId
        Region = $Region
        #UserData =  [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("<powershell>`n$UserData`n</powershell>"))
        KeyName = $KeyName
        InstanceProfile_Name = $InstanceProfileName 
    }

    
    $EC2Reservation = New-EC2Instance @EC2InstanceParams
    $ReservationFilter = @{"name"="reservation-id";"values"=$EC2Reservation.ReservationID}
    $EC2Instance = (Get-EC2Instance -Filter $ReservationFilter -Region $Region)
    $EC2Instance = $EC2Instance.Instances[0]
    New-EC2Tag -Resource $EC2Instance.InstanceId -Tag @{Key="Name";Value="PowerShellAWSTestInstance-$ID-$(Get-Date -F "yyyy-MM-dd-HH-mm")"} -Region $Region
    New-EC2Tag -Resource $EC2Instance.InstanceId -Tag @{Key="PowerShellAWSTestHelperID";Value=$ID} -Region $Region
	
    Write-Verbose "Created New Instance $($EC2Instance.InstanceId) from $AMIID, patching will occur (potentially with multiple reboots) and then the instance will stop"
    return $EC2Instance
}