function Update-AWSWindowsHelperInstanceToAMI {
    param(
        [string]$InstanceID,
        [string]$NewAMIName="AMIUpdated-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')",
        [string]$TestStackID='Default',
        [string]$Region
    )
    $OldImageID = New-EC2Image -Instance $InstanceID -Region $Region -Name "AWSTestHelperAMIPriorToUpdate-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
    New-AWSTestEnvironmentStack -Region $Region -ID $TestStackID | Out-Null
    Wait-AWSTestEnvironmentStackCreation -ID $TestStackID -Region $Region 
    $StackOutputs = Get-AWSTestEnvironmentStackOutputs -ID $TestStackID -Region $Region
    
    Wait-AWSWindowsHelperAMIToComplete -AMIID $OldImageID -Region $Region
    $PatchInstance = Start-AWSHelperAMIUpdate -ID $TestStackID -AMIID $OldImageID -Region $Region -SubnetId $StackOutputs.PublicSubnetID -InstanceProfileName $StackOutputs.SSMInstanceProfileID
    Wait-AWSWindowsHelperInstanceReady -InstanceID $PatchInstance.InstanceId -region $Region
    Unregister-EC2Image -ImageId $OldImageID

    Update-AWSWindowsHelperAMI -InstanceID $PatchInstance.InstanceId -Region $Region
    Wait-AWSWindowsHelperInstanceToStop -Region $Region -InstanceID $PatchInstance.InstanceId 
    
    $UpdateImageID = New-EC2Image -InstanceId $PatchInstance.InstanceId -Name $AMIName -Region $Region
    Wait-AWSWindowsHelperAMIToComplete -AMIID $ImageID -Region $Region
    Remove-AWSTestEnvironmentStack -Region $Region -ID $TestStackID -TerminateInstances -Confirm:$false
    Return $UpdateImageID
}