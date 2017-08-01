Function Wait-AWSWindowsHelperAMIToComplete{
    param(
        [string]$AMIID,
        [string]$Region
    )

    while((Get-EC2Image -ImageId $AMIID -Region $region).state -eq"pending"){
        Write-Verbose "Waiting for image to complete"
        Start-Sleep -s 10
    }
}