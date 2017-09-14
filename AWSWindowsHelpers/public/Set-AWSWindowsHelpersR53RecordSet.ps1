<#
.Synopsis
   Idempotently sets a single value in a Route 53 Record
.DESCRIPTION
   Idempotently sets a single value in a Route 53 Record
.EXAMPLE
   Set-AWSWindowsHelpersR53RecordSet -HostedZoneID Z9MTZXMHP863H -RecordName testsam2017.example.com. -RecordValue "google.com" -RecordType CNAME -Verbose 
#>
Function Set-AWSWindowsHelpersR53RecordSet{
    [cmdletbinding()]
    param(
        [string]$HostedZoneID,
        [string]$RecordName,
        [string]$RecordValue,
        [string]$RecordType = 'A',
        [switch]$Replace
    )
    $resourceRecordSet = Get-R53ResourceRecordSet -HostedZoneID $HostedZoneID -StartRecordName $RecordName -StartRecordType $RecordType
    $MatchingResourceRecordSet = $resourceRecordSet.ResourceRecordSets | Where-Object{$_.Name -eq $RecordName} 
    if($MatchingResourceRecordSet -and -not $Replace){
        Write-Error "$RecordName already exists in $HostedZoneID, use -Replace to force overwrite of its value"
        return
    }
    
    $UpdatedResourceRecordSet = @{
        Name = $RecordName
        Type = $RecordType
        TTL = 60
        #Weight = 0
        ResourceRecords = $RecordValue
    }

    $ChangeSet = [Amazon.Route53.Model.Change]@{
        Action = "UPSERT"
        ResourceRecordSet = $UpdatedResourceRecordSet # | ConvertTo-Json -Depth 99 | ConvertFrom-Json
    }

    @{Old=$MatchingResourceRecordSet;New=$UpdatedResourceRecordSet}
    Write-Verbose "Updating $RecordName to $RecordValue as a $RecordType"

    Edit-R53ResourceRecordSet -HostedZoneId $HostedZoneID -ChangeBatch_Comment "Changed by PowerShell" -ChangeBatch_Change $ChangeSet 

}