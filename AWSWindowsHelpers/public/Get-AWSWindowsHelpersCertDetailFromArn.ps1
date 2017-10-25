<#
.Synopsis
   Returns the details of the certificate as separate properties from a supplied ARN
.DESCRIPTION
   Returns the details of the certificate as separate properties from a supplied ARN
.EXAMPLE
   Get-AWSWindowsHelpersCertDetailFromArn -awsCertARN "arn:aws:iam::123456789012:server-certificate/2017_wild_example_com"
.INPUTS
   awsCertARN - ARN of the AWS certificate
.OUTPUTS
   Returns a object with the following properties
   CertificateType - Value of ACM or IAM is returned
   AWSRegion - Returned only for ACM certificate type, null fo IAM certificates
   AWSAccountID - AWS account number
   CertificateID - For IAM certificates ths is the certificate name. For ACM this is the Certificate ID
.FUNCTIONALITY
   Retrieves from a AWS Certificate ARN the details about the certificate as defined in the Output section above
#>
Function Get-AWSWindowsHelpersCertDetailFromArn
{
    Param(
        [Parameter(Mandatory=$true)]
        $awsCertARN      
    )
    $result = $awsCertARN -Match 'arn:aws:(?<CertificateType>[acm|iam]{3}):(?<AWSRegion>\w{2,}\-\w{4,}\-\d{1,})?:(?<AWSAccountID>\d{12}):\S{0,}\/(?<CertificateID>\S{0,})'
    if($result)
    {
        Return $Matches
    }
    Return $null
}