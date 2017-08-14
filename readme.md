# AWS Windows Helpers
A series of cmdlets that sit on top of the AWS PowerShell cmdlets to help with common AWS related tasks.

# Depends
Depends upon the AWSTestHelper module

# How to use

## Update an EC2 instance offline and swap loadbalancers/security groups to new instance

```
Import-Module AWSWindowsHelpers
Import-Module AWSTestHelper

$CurrentInstanceID = 'i-0210e383e3d655d40'
$Region = 'eu-west-1'
$VerbosePreference = "Continue"

# Launch a clone of the instance in a separate VPC, update it, and create an AMI from the updated instance.
$UpdatedAMIID = Update-AWSWindowsHelperInstanceToAMI -InstanceID $CurrentInstanceID -Region $Region -NewAMIName $($CurrentInstanceID+"-"+$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')+'-Updated')

# Launch a new instance from the patched AMI with the same name, tags, subnet, etc. with a black hole Security Group attached
$UpdatedInstance = New-AWSWindowsHelpersReplacementInstance -AMIID $UpdatedAMI -InstanceIDToReplace $CurrentInstanceID -BlackHoleSecurityGroup -Region $region

# Wait for the new (patched) instance to be reachable.
Wait-AWSWindowsHelperInstanceReady -InstanceID $UpdatedInstanceID.InstanceId -Region $Region

# Give the old unpatched instance the black hole security group, and the new patched instance the security groups the unpatched instance had
Switch-AWSHelperInstanceSecurityGroups -CurrentInstanceID $CurrentInstanceID -ReplacementInstanceID $UpdatedInstance.InstanceId -Region $Region

# Remove the old unpatched instance from its loadbalancers (ELB & ELBv2) and add the new patched instance in its stead
Switch-AWSHelperInstanceInLoadBalancers -CurrentInstanceID $CurrentInstanceID -ReplacementInstanceID $UpdatedInstance.InstanceId -Region $Region
```