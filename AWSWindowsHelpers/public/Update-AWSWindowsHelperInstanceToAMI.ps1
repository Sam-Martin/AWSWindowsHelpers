function Update-AWSWindowsHelperInstanceToAMI {
    param(
        [parameter(Mandatory=$True)]
        [string]$InstanceID,
        [parameter(Mandatory=$True)]
        [string]$NewAMIName="AMIUpdated-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')",
        [string]$TestStackID='Default',
        # Optional keyname to launch the EC2 Instance with
        [string]$KeyName,
        [string]$Region,
        # Cleans up test vpc etc automatically.
        [switch]$AutoCleanup
    )
    $OldImageID = New-EC2Image -Instance $InstanceID -Region $Region -Name "AWSTestHelperAMIPriorToUpdate-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')" -NoReboot $True
    New-AWSTestEnvironmentStack -Region $Region -ID $TestStackID -ErrorAction SilentlyContinue | Out-Null
    Wait-AWSTestEnvironmentStackCreation -ID $TestStackID -Region $Region 
    $StackOutputs = Get-AWSTestEnvironmentStackOutputs -ID $TestStackID -Region $Region -ErrorAction Stop
    
    Wait-AWSWindowsHelperAMIToComplete -AMIID $OldImageID -Region $Region -ErrorAction Stop

    $Params = @{
        ID = $TestStackID
        AMIID = $OldImageID
        Region = $Region
        SubnetId = $StackOutputs.PublicSubnetID
        InstanceProfileName = $StackOutputs.SSMInstanceProfileID
    }
    if($KeyName){
        $Params.Add('KeyName',$KeyName)
    }
    $PatchInstance = Start-AWSHelperAMIUpdate @params
    Unregister-EC2Image -ImageId $OldImageID -region $Region
    Wait-AWSWindowsHelperInstanceReady -InstanceID $PatchInstance.InstanceId -region $Region
    
    Update-AWSWindowsHelperAMI -InstanceID $PatchInstance.InstanceId -Region $Region -ErrorAction Stop
    Wait-AWSWindowsHelperInstanceToStop -Region $Region -InstanceID $PatchInstance.InstanceId 
    
    $UpdateImageID = New-EC2Image -InstanceId $PatchInstance.InstanceId -Name $NewAMIName -Region $Region -ErrorAction Stop
    Wait-AWSWindowsHelperAMIToComplete -AMIID $UpdateImageID -Region $Region
    if($AutoCleanup){
        Remove-AWSTestEnvironmentStack -Region $Region -ID $TestStackID -TerminateInstances -Confirm:$false
    }
    Return $UpdateImageID
}