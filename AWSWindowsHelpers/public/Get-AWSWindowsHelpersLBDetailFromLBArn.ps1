<#
.Synopsis
   Returns the details of the load balancer as separate properties from a supplied ARN
.DESCRIPTION
   Returns the details of the load balancer as separate properties from a supplied ARN
.EXAMPLE
   Get-AWSWindowsHelpersLBDetailFromLBArn -awsLBARN  "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/load-balancer-name/139d65287f94335F"
.INPUTS
   awsCertARN - ARN of the AWS load balancer
.OUTPUTS
   Returns a object with the following properties
   AWSRegion - AWS Region
   AWSAccountID - AWS account number
   LoadBalancerType - Value of "Application" or "Classic" is returned
   LoadBalancerName - Name of the load balancer
   LoadBalancerGUID - Unique ID of the load balancer (Application load balancers only)
.FUNCTIONALITY
   Retrieves from a AWS load balancer ARN the details about the load balancer as defined in the Output section above. Load balancer type is determined by
   presence of the "/app/" string in the ARN. 
#>
Function Get-AWSWindowsHelpersLBDetailFromLBArn
{
    Param(
        [Parameter(Mandatory=$true)]
        $awsLBARN      
    )
    $result = $awsLBARN -Match 'arn:aws:elasticloadbalancing:(?<AWSRegion>\w{0,}\-\w{0,}\-\d{0,}):(?<AWSAccountID>\d{12}):loadbalancer\/(?<LoadBalancerType>app)?\/?(?<LoadBalancerName>[a-zA-Z0-9\-]{1,32})\/?(?<LoadBalancerGUID>\S{1,})?'
    if($result)
    {
        $loadbalancerType = $Matches.LoadBalancerType
        if($loadbalancerType -eq 'app')
        {
            $Matches.LoadBalancerType = 'Application'
        }
        else
        {
            $Matches.LoadBalancerType = 'Classic'
        }
        Return $Matches
    }
    Return $null
}