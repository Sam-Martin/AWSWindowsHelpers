# AWS Windows Helpers
A series of cmdlets that sit on top of the AWS PowerShell cmdlets to help with common AWS related tasks.

# Depends
Depends upon the AWSTestHelper module

# Example

```
Import-Module AWSTestHelper
Import-module AWSWindowsHelpers
New-AWSTestEnvironmentStack -Region eu-west-1 -ID Default
Wait-AWSTestEnvironmentStackCreation -ID Default -Region eu-west-1 
$StackOutputs = Get-AWSTestEnvironmentStackOutputs -ID Default -Region eu-west-1
$PatchInstance = Start-AWSHelperAMIUpdate -ID Default -AMIID ami-1e5d4378 -Region eu-west-1 -SubnetId $StackOutputs.PublicSubnetID -InstanceProfileName $StackOutputs.SSMInstanceProfileID -KeyName smartin-2017
Update-AWSWindowsHelperAMI -InstanceID $PatchInstance.InstanceId -Region eu-west-1
Wait-AWSWindowsHelperInstanceToStop -Region eu-west-1 -InstanceID $PatchInstance.InstanceId 
```