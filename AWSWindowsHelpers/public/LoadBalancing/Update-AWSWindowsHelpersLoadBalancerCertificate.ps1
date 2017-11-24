<#
.Synopsis
   Replaces the certificate in use on the load balancer
.DESCRIPTION
   Replaces the certificate in use on the load balancer
.EXAMPLE
   Update-AWSWindowsHelpersLoadBalancerCertificate -originalCertARN "arn:aws:iam::123456789012:server-certificate/2017_wild_example_com" -replacementCertARN "arn:aws:acm:us-west-2:123456789012:certificate/0e460187-a4b4-452f-a88b-c1d17dfaf749"
.INPUTS
   originalCertARN - ARN of the original AWS certificate to be replaced
   replacementCertARN - ARN of the replacement AWS certificate to be used on the load balancer
   Region - Required if neither the original or replacement certficate is a ACM certificate
   Credential (optional) - Credential to use for AWS commands if supplied
   ProfileName (optional) - ProfileName to use for AWS commands if supplied
.FUNCTIONALITY
   Cmdlet replaces any of the listeners which are using the original certificate ARN with the replacement certificate ARN. If the original certificate is a ACM certificate
   then the InUseBy property is used to determine which load balancers the certificate needs to be replaced on. For IAM certificates all the load balancers in the account
   are checked
#>
Function Update-AWSWindowsHelpersLoadBalancerCertificate
{
    [CmdletBinding(PositionalBinding=$false)]
    Param(
        [Parameter(Mandatory=$true)]        
        $originalCertARN,
        [Parameter(Mandatory=$true)]
        $replacementCertARN,
        $Region,
        $Credential,
        $ProfileName        
    )
    $albCallLimit = 20
    $certificateValidity = Test-AWSWindowsHelpersCertificateValid -awsCertARN $replacementCertARN
    if(($certificateValidity) -ne "VALID")
    {
        throw "Certificate not valid. State is [$certificateValidity] for [$replacementCertARN]"
    }

    $baseAWSParams =@{Region = $Region}
    if($Region){$baseAWSParams.Region = $Region}
    if($Credential){$baseAWSParams.Add('Credential',$Credential)}
    elseif($ProfileName){$baseAWSParams.Add('ProfileName',$ProfileName)} 

    $loadbalancerParams = @{
        originalCertARN = $originalCertARN
        replacementCertARN = $replacementCertARN
    }

    $originalCertDetail = Get-AWSWindowsHelpersCertDetailFromArn -awsCertARN $originalCertARN
    if($originalCertDetail.AWSRegion -ne $Region)
    {
        Write-Warning "Specified region [$region] does not match region of ACM certificate [$($originalCertDetail.AWSRegion)] using region from certificate"
    }

    #ACM certificates specify which load balancers are using the certificate in the InUseBy property
    if($originalCertDetail.CertificateType -eq 'acm')
    {
        $elbNames = @()
        $albARNs = @()
        if(! (Test-AWSWindowsHelpersCertificateValid -awsCertARN $originalCertArn))
        {
            throw "Original Certificate [$originalCertArn] is not valid"
        }
        $baseAWSParams.Region = $originalCertDetail.AWSRegion
        $certificateDetail = Get-ACMCertificateDetail -CertificateArn $originalCertArn @baseAWSParams

        foreach($loadbalancer in $certificateDetail.InUseBy)
        {
            $loadBalancerDetail = Get-AWSWindowsHelpersLBDetailFromLBArn -awsLBARN $loadbalancer
            if($loadBalancerDetail.LoadBalancerType -eq 'Application')
            {
                $albARNs += $loadbalancer
            }
            elseif($loadBalancerDetail.LoadBalancerType -eq 'Classic')
            {
                $elbNames += $loadBalancerDetail.LoadBalancerName
            }
        }

        if($elbNames)
        {
            Set-AWSWindowsHelpersELBCertificates @loadbalancerParams -loadbalancerName $elbNames @baseAWSParams
        }
        else 
        {
            Write-Verbose "No classic load balancers use certificate [$originalCertArn]"
        }

        if($albARNs)
        {
            $additionalALBARNs = $albARNs
            $albARNCount = $albARNs.Count
            #AWS Get Load balancer cmdlet supports specifying up to 20 load balancers in a single call
            do
            {
                if($albARNCount -gt $albCallLimit)
                {
                    $albARNsToSet = $additionalALBARNs[0..($albCallLimit-1)]
                    $additionalALBARNs = $additionalALBARNs[$albCallLimit..$additionalALBARNs.Count]
                    Set-AWSWindowsHelpersALBCertificates @loadbalancerParams -loadbalancerARN $albARNsToSet @baseAWSParams
                }
                else 
                {
                    Set-AWSWindowsHelpersALBCertificates @loadbalancerParams -loadbalancerARN $additionalALBARNs @baseAWSParams                
                }
                $albARNCount = $albARNCount - $albCallLimit
            }while($albARNCount -ge $albCallLimit)

        }
        else 
        {
            Write-Verbose "No application load balancers use certificate [$originalCertArn]"
        }

    }
    else 
    {
        if(!$baseAWSParams.Region)
        {
            $replacementCertDetail = Get-AWSWindowsHelpersCertDetailFromArn -awsCertARN $replacementCertARN
            $baseAWSParams.Region = $replacementCertDetail.AWSRegion
        }
        Set-AWSWindowsHelpersELBCertificates @loadbalancerParams @baseAWSParams
        Set-AWSWindowsHelpersALBCertificates @loadbalancerParams @baseAWSParams
    }
}