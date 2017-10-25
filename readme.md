# AWS Windows Helpers [![Build status](https://ci.appveyor.com/api/projects/status/1fc07ur3jd49k5cr/branch/master?svg=true)](https://ci.appveyor.com/project/Sam-Martin/awswindowshelpers/branch/master)

A series of cmdlets that sit on top of the AWS PowerShell cmdlets to help with common AWS related tasks.
These cmdlets have been created based primarily on requirements I (Sam Martin) have encountered while working with AWS, and are not intended to cover any specific set of scenarios beyond what I have added.



# Dependencies
Depends upon the [AWSTestHelper](https://github.com/Sam-Martin/AWSTestHelper) module

# Usage
You can install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/AWSWindowsHelpers/) using the following command.

```
Install-Module -Name AWSWindowsHelpers
```

## Update an EC2 instance offline and swap loadbalancers/security groups to new instance
One major use case for this module is the offline Windows Patching of an EC2 instance.
This is intended to allow you to patch a manually configured instance which is a single point of failure in an AWS environment with minimal downtime.
Obviously, if you are able to, it is preferable to launch a newly patched instance in parallel behind a loadbalancer, and drain connections from the old instance before decommissioning it. However, this is not always possible (e.g. in manually configured AD joined environments).

The below example performs the following actions:
1. Creates an AMI of `$CurrentInstanceID` (`Update-AWSWindowsHelperInstanceToAMI`)
2. Deploys a new, isolated, test VPC (`Update-AWSWindowsHelperInstanceToAMI`)
3. Launches an instance from the AMI in the new VPC (`Update-AWSWindowsHelperInstanceToAMI`)
4. Deletes the AMI (`Update-AWSWindowsHelperInstanceToAMI`)
5. Runs an SSM command to run a powershell script which: (`Update-AWSWindowsHelperInstanceToAMI`)
	1. Creates a scheduled task to run itself on boot.
	2. Installs chocolatey
	3. Installs the PSWindowsUpdate module using chocolatey (to allow compatibility with servers which do not have `Install-Module`)
	4. Checks to see if any patches are required.
	5. Installs any patches required.
	6. Reboots the server
	7. Repeats steps iv-vi until no more patches are required
	8. Once no more patches are required shuts down.
 6. Waits until the newly launched instance has shutdown (i.e. it has completed patching) (`Update-AWSWindowsHelperInstanceToAMI`)
 7. Creates an AMI of the newly patched instance. (`Update-AWSWindowsHelperInstanceToAMI`)
 8. Launches an instance with size, subnet, tags, etc. identical to `$CurrentInstanceID` but with a security group that does not allow inbound OR outbound access to prevent it colliding in AD with the old instance (`New-AWSWindowsHelpersReplacementInstance`)
 9. Waits until that instance passes its reachability checks (`Wait-AWSWindowsHelperInstanceReady`)
 10. Swaps security groups between the new and old instances (black holing the old instance) (`Switch-AWSHelperInstanceSecurityGroups`)
 11. Swaps the new instance with the old instance in ELB and ELBv2 loadbalancers (`Switch-AWSHelperInstanceInLoadBalancers`)

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
Wait-AWSWindowsHelperInstanceReady -InstanceID $UpdatedInstance.InstanceId -Region $Region

# Give the old unpatched instance the black hole security group, and the new patched instance the security groups the unpatched instance had
Switch-AWSHelperInstanceSecurityGroups -CurrentInstanceID $CurrentInstanceID -ReplacementInstanceID $UpdatedInstance.InstanceId -Region $Region

# Remove the old unpatched instance from its loadbalancers (ELB & ELBv2) and add the new patched instance in its stead
Switch-AWSHelperInstanceInLoadBalancers -CurrentInstanceID $CurrentInstanceID -ReplacementInstanceID $UpdatedInstance.InstanceId -Region $Region
```

# KMS Encryption and Decryption
The cmdlets `Invoke-AWSWindowsHelperEncryptKMSPlaintext` and `Invoke-AWSWindowsHelperDecryptKMSPlaintext` allow you to encrypt and decrypt strings using KMS easily.

```
$encrypted = Invoke-AWSWindowsHelperEncryptKMSPlaintext -KeyID 347d96af-ea90-456d-9ca7-edecdbb46c42 -PlaintextString "hello!" -Region us-east-1
Invoke-AWSWindowsHelperDecryptKMSPlaintext -Base64Secret $encrypted -Region us-east-1
```

# Route 53

These cmdlets make working with Route53 a bit easier in powershell.

## Set-AWSWindowsHelpersR53RecordSet

```
Set-AWSWindowsHelpersR53RecordSet -HostedZoneID Z9MTZXMHP863H -RecordName testsam2017.example.com. -RecordValue "google.com" -RecordType CNAME -Verbose
```

# Load Balancers

## Get-AWSWindowsHelperALBTraffic

```
Get-AWSWindowsHelperALBTraffic -AWSRegion eu-west-1 -ALBName app/LoadB-3M8KJGY58BE5/059338ed989e015 -StartTime (Get-Date).AddMonths(-1) -EndTime (Get-Date)
```

## Update-AWSWindowsHelpersLoadBalancerCertificate

Replaces a specific SSL certificate on all ALB and ELB load balancers for a specified region. If a ACM certificate is specified in either the original or replacement parameter ARN then the region is inferred from the ARN. If only IAM certificates ARNs are supplied a region must be given. 

```
Update-AWSWindowsHelpersLoadBalancerCertificate -originalCertARN "arn:aws:iam::123456789012:server-certificate/2017_wild_example_com" -replacementCertARN "arn:aws:acm:us-west-2:123456789012:certificate/0e460187-a4b4-452f-a88b-c1d17dfaf749"
```

# Authors

- Sam Martin (samjackmartin@gmail.com)
- Oliver Li (oliverli@hotmail.co.uk)
- Bindu Massey (bindu.massey@hotmail.co.uk)
