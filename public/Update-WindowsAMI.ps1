function Update-WindowsAMI{
    Param(
        [Parameter(Mandatory=$true)]
        $ID,
        [Parameter(Mandatory=$true)]
        $AMIID,
        [Parameter(Mandatory=$true)]
        $Region,
        [Parameter(Mandatory=$true)]
        $SubnetId,
        $InstanceType = "m4.large",
        $KeyName
    )
    
    $UserData = {
        if($PSVersionTable.PSVersion.Major -lt 5){
            Set-ExecutionPolicy Unrestricted -Force
            iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 
            choco install powershell -y
            Restart-Computer -Force
        }
        Install-PackageProvider Nuget -Force
        Install-Module PSWindowsUpdate -Force
        if(!(Get-WUList)){
            Get-WUInstall -AcceptAll -AutoReboot | Out-File C:\PSWindowsUpdate.log
        }else{
            Stop-Computer -Force
        }
    }

    $EC2InstanceParams = @{
        InstanceType = $InstanceType
        ImageId = $AMIID
        SubnetId = $SubnetId
        Region = $Region
        UserData =  [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("<powershell>`n$UserData`n</powershell>"))
        KeyName = $KeyName
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