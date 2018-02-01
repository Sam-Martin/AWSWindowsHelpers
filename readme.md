# AWS Windows Helpers [![Build status](https://ci.appveyor.com/api/projects/status/1fc07ur3jd49k5cr/branch/master?svg=true)](https://ci.appveyor.com/project/Sam-Martin/awswindowshelpers/branch/master) [![PowerShell Gallery](https://img.shields.io/powershellgallery/v/AWSWindowsHelpers.svg)]() [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/AWSWindowsHelpers.svg)]()

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

# Set a "A" Record with an Alias Target

Set-AWSWindowsHelpersR53RecordSet -HostedZoneID Z9MTZXMHP863H -RecordName testsam2017.example.com. -ARecordAlias -AliasHostedZoneID "Z32O12XQLNT63H" -RecordValue "loadbalancer-dns-name-123456789.eu-west-1.elb.amazonaws.com" -Verbose
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

# CloudFormation

## ConvertTo-AWSWindowsHelperCFNParameter

Converts a hashtable to the Parameter data type expected by the parameter "Parameter" of the New-CFNStack cmdlet. The UsePreviousValue property is set to true for values processed by this cmdlet.

```powershell
$CFNStackParameters = @{ 
	"AMILookupStackName" = "aws-amilookup-stack" 
	"InstanceType" = "t2.micro"
	"WindowsVersion" = "Windows Server 2012 R2 English 64-bit"
	}

$Params = @{
    StackName = "cloudformation-stack-name" 
    Parameter = $CFNStackParameters | ConvertTo-AWSWindowsHelperCFNParameter 
    TemplateBody = $TemplateBody
    region = "eu-west-1" 
    EnableTerminationProtection = $true
}

CloudformationStackARN = New-CFNStack @Params
```

# Amazon Resource Names
The cmdlet `Get-AWSWindowsHelpersARNDetail` allows you to retrieve the values from an ARN. The values are returned as a hash table. 

The names of the resource elements are returned as an array under the "resources" key. The resource ARN prior to splitting can retrieved under the "resourcedetail" key. 

```powershell
#AutoScaling Group ARN
Get-AWSWindowsHelpersARNDetail -arn "arn:aws:autoscaling:us-east-1:123456789012:scalingPolicy:c7a27f55-d35e-4153-b044-8ca9155fc467:autoScalingGroupName/my-test-asg1:policyName/my-scaleout-policy"

Name                           Value
----                           -----
scalingPolicy                  c7a27f55-d35e-4153-b044-8ca9155fc467
resources                      {scalingPolicy, autoScalingGroupName, policyName}
region                         us-east-1
resourcedetail                 scalingPolicy:c7a27f55-d35e-4153-b044-8ca9155fc467:autoScalingGroupName/my-test-asg1:policyName/my-scaleout-policy
resourcetype                   scalingPolicy
service                        autoscaling
policyName                     my-scaleout-policy
accountid                      123456789012
autoScalingGroupName           my-test-asg1
partition                      aws

#Certificate Manager ARN
Get-AWSWindowsHelpersARNDetail -arn "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

Name                           Value
----                           -----
resources                      {certificate-id}
region                         us-east-1
resourcedetail                 certificate/12345678-1234-1234-1234-123456789012
resourcetype                   certificate
service                        acm
certificate-id                 12345678-1234-1234-1234-123456789012
accountid                      123456789012
partition                      aws

#Elastic Load Balancing Application Load Balancer
Get-AWSWindowsHelpersARNDetail -arn "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-load-balancer/50dc6c495c0c9188"

Name                           Value
----                           -----
loadbalancer-type              app
resources                      {loadbalancer-type, loadbalancer-name, loadbalancer-id}
loadbalancer-id                50dc6c495c0c9188
loadbalancer-name              my-load-balancer
region                         us-east-1
resourcedetail                 loadbalancer/app/my-load-balancer/50dc6c495c0c9188
resourcetype                   loadbalancer
service                        elasticloadbalancing
accountid                      123456789012
partition                      aws

#Elastic Load Balancing Target Group ARN
Get-AWSWindowsHelpersARNDetail -arn "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"

Name                           Value
----                           -----
targetgroup-name               my-targets
resources                      {targetgroup-name, targetgroup-id}
region                         us-east-1
resourcedetail                 targetgroup/my-targets/73e2d6bc24d8a067
resourcetype                   targetgroup
service                        elasticloadbalancing
targetgroup-id                 73e2d6bc24d8a067
accountid                      123456789012
partition                      aws

#S3 Bucket ARN
Get-AWSWindowsHelpersARNDetail -arn "arn:aws:s3:::my_corporate_bucket/exampleobject.png"

Name                           Value
----                           -----
region
resourcedetail                 my_corporate_bucket/exampleobject.png
service                        s3
resource                       my_corporate_bucket
accountid
partition                      aws
```

# Authors

- Sam Martin (samjackmartin@gmail.com)
- Oliver Li (oliver.1i@outlook.com)
- Bindu Massey (bindu.massey@hotmail.co.uk)
