<#
.Synopsis
   Returns the details of an AWS Resource from the ARN
.DESCRIPTION
   Returns the details of an AWS Resource from the ARN
.EXAMPLE
   Get-AWSWindowsHelpersARNDetail -arn "arn:aws:iam::123456789012:server-certificate/2017_wild_example_com"
.INPUTS
   arn - ARN of the AWS certificate
.OUTPUTS
   Returns a object with the following properties
   Partition - The partition the resource is in
   Service - The AWS Service
   Region - The AWS region
   AccountID - AWS account number
   ResourceDetail - The resource ARN detail
   ResourceType - The type of AWS resource
.FUNCTIONALITY
   Retrieves from a ARN the details of the AWS service
#>
Function Get-AWSWindowsHelpersARNDetail
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^arn:*.:*.:*.:*.:*.')]
        $arn      
    )
    $arnSplit = $arn -split ":"

    $arnDetail = @{
        partition = $arnSplit[1]
        service = $arnSplit[2]
        region = $arnSplit[3]
        accountid = $arnSplit[4]
    }

    $resourceDetail = $arnSplit[5..$arnSplit.Length] -join ":"
    $arnDetail.Add("resourcedetail",$resourceDetail)
    $resourceARN = $resourceDetail -split "/"
    $resourceList= @()

    if($arnSplit.Length -le 6 -and $($resourceARN.length -eq 1) -or $arnDetail.service -eq 's3')
    {   # Deal with ARN in format "arn:partition:service:region:account-id:resource"
        if($($resourceARN.length -gt 1))
        { # Handle S3 resources
            $arnDetail.Add("resource",$resourceARN[0])
        }
        else 
        {
            $arnDetail.Add("resource",$arnSplit[5])    
        }
        Write-verbose "Adding [resource] $($arnDetail.resource)"
    }
    elseif($arnSplit.Length -ge 6 -and $($resourceARN.length -ge 1))
    {   # Deal with ARN in format "arn:partition:service:region:account-id:resourcetype/resource"
        if($resourceARN[0] -match ":")
        {
            $resourceType = $($resourceARN[0] -split ":")[0]
        }
        else 
        {
            $resourceType = $resourceARN[0]
        }
        $arnDetail.Add("resourcetype",$resourceType)
        for($element=5;$element -lt $arnSplit.Length;$element++)
        {   # Loop through elements split by ":"
            $resourceARN = $arnSplit[$element] -split "/"
            if($($resourceARN.length) -eq 1)
            {   
                if($arnSplit[$element+1] -notmatch "\/")
                {   # Check if adjacent element contains resource type split by "/"
                    $resourceType = Get-AWSWindowsHelpersARNResourceType -arnResourceValue $arnSplit[$element+1]
                    $resourceItem = "$($arnSplit[$element])-$resourceType"
                    $resourceList+=$arnSplit[$element]
                    $arnDetail.Add($arnSplit[$element],$arnSplit[$element+1])
                    Write-verbose "Adding resource [$($arnSplit[$element])] with value [$($arnSplit[$element+1])]"
                    $element++  
                }
                continue
            }

            for($i = 0;$i -lt $resourceARN.length;$i++ )
            {   # Loop through subelements split by "/"
                if($resourceARN[$i+1])
                {
                    if($resourceARN[$i] -match "[a-zA-Z]{3,}[nN]ame$")
                    { 
                        $resourceItem = "$($resourceARN[$i])"
                    }
                    else
                    {
                        $resourceType = Get-AWSWindowsHelpersARNResourceType -arnResourceValue $resourceARN[$i+1]
                        $resourceItem = "$($resourceARN[$i])-$resourceType"
                    }
                    $arnDetail.Add($resourceItem,$resourceARN[$i+1]) 
                    $resourceList+=$resourceItem
                    Write-verbose "Adding resource [$resourceItem] with value [$($resourceARN[$i+1])]"      
                }

                # Look ahead to see if any additional elements which contain data
                for($lookAhead = 2;$lookAhead -lt $resourceARN.length;$lookAhead++ )
                {

                    if($resourceARN[$lookAhead]) 
                    {
                        $resourceType = Get-AWSWindowsHelpersARNResourceType -arnResourceValue $resourceARN[$lookAhead]
                        if($resourceType)
                        {
                            $resourceItem = "$($resourceARN[0])-$resourceType"
                        }
                        else 
                        {
                            $resourceItem = "$($resourceARN[0])"
                        }
                        $resourceList+=$resourceItem
                        $arnDetail.Add($resourceItem,$resourceARN[$lookAhead])
                        Write-verbose "Adding resource [$resourceItem] with value [$($resourceARN[$lookAhead])]" 
                        $i = $lookAhead + 1
                    }
                }
            }
        }
        $arnDetail.Add("resources",$resourceList)
    }
    $arnDetail
}

