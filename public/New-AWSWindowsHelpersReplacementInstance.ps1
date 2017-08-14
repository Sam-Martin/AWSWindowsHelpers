function New-AWSWindowsHelpersReplacementInstance {
    param(
        [parameter(Mandatory=$true)]
        [string]$AMIID,
        [parameter(Mandatory=$true)]
        [string]$InstanceIDToReplace,
        [switch]$BlackHoleSecurityGroup,
        [parameter(Mandatory=$true)]
        [string]$Region
    )
    $InstanceToReplace = $(Get-EC2Instance -Region $Region -InstanceId $InstanceIDToReplace).Instances[0];
    $NewInstanceParams = @{
        ImageId = $AMIID
        KeyName = $InstanceToReplace.KeyName
        InstanceType = $InstanceToReplace.InstanceType
        InstanceProfile_Arn = $InstanceToReplace.IamInstanceProfile.Arn
        #SecurityGroups = $InstanceToReplace.SecurityGroups.groupid
        SubnetId = $InstanceToReplace.SubnetId
        EbsOptimized = $InstanceToReplace.EbsOptimized
        TagSpecification = @{ResourceType="Instance";Tags=$InstanceToReplace.Tag}
        Region = $Region
    }

    if($BlackHoleSecurityGroup){
        $GroupName = "$InstanceIDToReplace - Black Hole - $(Get-Date -F "yyyy-MM-dd-HH-mm")"
        $SecurityGroup = New-EC2SecurityGroup -GroupName $GroupName -Description $GroupName -VpcId $InstanceToReplace.VpcId -Region $Region
        Revoke-EC2SecurityGroupEgress -GroupId $SecurityGroup -IpPermission @{IPRanges = @('0.0.0.0/0');FromPort=0;IPProtocol=-1;ToPort=0;} -region $Region
        $NewInstanceParams.Add("SecurityGroupId",$SecurityGroup)
    }else{
        $NewInstanceParams.Add("SecurityGroupId",$InstanceToReplace.SecurityGroups.groupid)
    }

    $NewEC2InstanceReservation = New-EC2Instance @NewInstanceParams
    
    $ReservationFilter = @{"name"="reservation-id";"values"=$NewEC2InstanceReservation.ReservationID}
    $NewEC2Instance = (Get-EC2Instance -Filter $ReservationFilter -Region $Region)
    $NewEC2Instance = $NewEC2Instance.Instances[0]
    return $NewEC2Instance
    #return $InstanceToReplace
}

$region = "eu-west-1"
$InstanceIDToReplace = 'i-0210e383e3d655d40'
$AMIID = 'ami-62798c1b'
$NewInstance = New-AWSWindowsHelpersReplacementInstance -Region eu-west-1 -InstanceIDToReplace $InstanceIDToReplace -AMIID $AMIID -BlackHoleSecurityGroup