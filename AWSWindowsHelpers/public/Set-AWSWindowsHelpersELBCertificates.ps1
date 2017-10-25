<#
.Synopsis
   Sets the Certificate on a Classic Load Balancer
.DESCRIPTION
   Sets the Certificate on a Classic Load Balancer
.EXAMPLE
   Set-AWSWindowsHelpersELBCertificates -originalCertARN "arn:aws:iam::123456789012:server-certificate/2017_wild_example_com" -replacementCertARN "arn:aws:acm:us-west-2:123456789012:certificate/0e450187-a4b4-452f-a88b-c1d17dfaf749"
.INPUTS
   originalCertARN - ARN of the original AWS certificate to be replaced
   replacementCertARN - ARN of the replacement AWS certificate to be used on the load balancer
   loadbalancerName (optional) - Name of the Classic Load balancer. If not supplied all load balancers will be checked if the certificate is present
   Credential (optional) - Credential to use for AWS commands if supplied
   ProfileName (optional) - ProfileName to use for AWS commands if supplied
.FUNCTIONALITY
   Cmdlet replaces all the listeners which are using the original certificate ARN with the replacement certificate ARN. If an array of
   loadbalancerARNs is provided the listeners are checked on the supplied load balancers
#>
Function Set-AWSWindowsHelpersELBCertificates
{
    [CmdletBinding(PositionalBinding=$false)]
    Param(
        $originalCertARN,
        [Parameter(Mandatory=$true)]
        $replacementCertARN,
        $loadbalancerName,
        $Region,
        $Credential,
        $ProfileName
    )

    $baseAWSParams = @{Region = $Region}
    if($Credential){$baseAWSParams.Add('Credential',$Credential)}
    elseif($ProfileName){$baseAWSParams.Add('ProfileName',$ProfileName)}  

    $certificateValidity = Test-AWSWindowsHelpersCertificateValid -awsCertARN $replacementCertARN
    if(($certificateValidity) -ne "VALID")
    {
        throw "Certificate not valid. State is [$certificateValidity] for [$replacementCertARN]"
    }

    $params =@{}
    if($loadbalancerName)
    {
        $params.Add('LoadBalancerName',$loadbalancerName)
    }

    $elb = Get-ELBLoadBalancer @params @baseAWSParams

    foreach($loadbalancer in $elb)
    {
        Write-Verbose "Checking load balancer [$($loadbalancer.LoadBalancerName)]"
        $loadBalancerListeners = $loadbalancer.listenerdescriptions.listener
        foreach($listener in $loadBalancerListeners)
        {
            Write-Verbose "`tChecking listener with load balancer port $($listener.LoadBalancerPort)"        
            $Matches = ""
            if($listener.SSLCertificateId -match $originalCertARN)
            {
                Write-Verbose "`t`tChanging SSL certificate on listener"
                $elbCertParams =@{
                    LoadBalancerName = $loadbalancer.LoadBalancerName
                    LoadBalancerPort = $listener.LoadBalancerPort
                    SSLCertificateId = $replacementCertARN
                }
                Set-ELBLoadBalancerListenerSSLCertificate @elbCertParams @baseAWSParams
            }
            else
            {
                Write-Verbose "`t`tNo SSL certificate matching pattern found on listener"
            }
        }
    }
}