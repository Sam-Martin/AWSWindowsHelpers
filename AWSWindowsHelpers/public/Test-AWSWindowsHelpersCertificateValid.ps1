<#
.Synopsis
   Test whether a ACM or IAM certificate is valid
.DESCRIPTION
   Test whether a ACM or IAM certificate is valid
.EXAMPLE
   Test-AWSWindowsHelpersCertificateValid -awsCertARN "arn:aws:iam::123456789012:server-certificate/2017_wild_example_com"
.INPUTS
   awsCertARN - ARN of the AWS certificate to be tested
   Credential (optional) - Credential to use for AWS commands if supplied
   ProfileName (optional) - ProfileName to use for AWS commands if supplied
.OUTPUTS
   Returns string "valid" if the certificate state is ok otherwise returns the status of the certificate after the test
.FUNCTIONALITY
   Tests whether a AWS certificate is exists and valid. For ACM certificate this is determined by checking 
   the ACM certificate Status property is in "Issued" state
   For IAM certificates this is determined by checking the expiry date of the certificate.
#>
Function Test-AWSWindowsHelpersCertificateValid
{
    [CmdletBinding(PositionalBinding=$false)]
    Param(
        [Parameter(Mandatory=$true)]
        $awsCertARN,
        $Credential,
        $ProfileName        
    )
    $certDetail = Get-AWSWindowsHelpersCertDetailFromArn -awsCertARN $awsCertARN

    $baseAWSParams =@{}
    if($certDetail.AWSRegion){$baseAWSParams.Add('Region',$certDetail.AWSRegion)}
    if($Credential){$baseAWSParams.Add('Credential',$Credential)}
    elseif($ProfileName){$baseAWSParams.Add('ProfileName',$ProfileName)}     

    $certificateStatus = "VALID"
    switch($certDetail.CertificateType)
    {
        'acm' 
        {
            try
            {
                $certificateDetail = Get-ACMCertificateDetail -CertificateArn $awsCertARN @baseAWSParams
                if($certificateDetail.Status -ne "ISSUED")
                {
                    $certificateStatus = $certificateDetail.Status
                }
                $remainingValidity = New-TimeSpan -End $certificateDetail.NotAfter
                if($remainingValidity.Days -le 0)
                {
                    $certificateStatus = "EXPIRED"
                }
                elseif($remainingValidity.Days -le 60)
                {
                    Write-Warning "ACM Certificate has only [$($remainingValidity.Days)] days remaining [$awsCertARN]"
                }
            }
            Catch
            {
                $ErrorMessage = $_.Exception.Message
                Write-Error "Error [$ErrorMessage]"
                $certificateStatus = "FAILED"
            }      
        }
        'iam'
        {
            try
            {
                $certificateDetail = Get-IAMServerCertificate -ServerCertificateName $certDetail.CertificateID @baseAWSParams
                $certificateExpiry = $certificateDetail.ServerCertificateMetadata
                $remainingValidity = New-TimeSpan -End $certificateExpiry.Expiration
                if($remainingValidity.Days -le 0)
                {
                    $certificateStatus = "EXPIRED"
                }
                elseif($remainingValidity.Days -le 60)
                {
                    Write-Warning "IAM Certificate has only [$($remainingValidity.Days)] days remaining"
                }
            }
            Catch
            {
                $ErrorMessage = $_.Exception.Message
                Write-Error "Error [$ErrorMessage] for [$awsCertARN]" -mt warning
                $certificateStatus = "FAILED"              
            }      
  
        }
    }
    return $certificateStatus
}