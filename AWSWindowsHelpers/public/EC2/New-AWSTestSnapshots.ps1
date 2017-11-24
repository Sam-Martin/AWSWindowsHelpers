Function New-AWSTestSnapshots {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$True)]
        $InstanceID,
        [parameter(Mandatory=$True)]
        $Region,
        [parameter(Mandatory=$True)]
        $ID,
        [switch]$WaitForCompletion
    )

    $EC2Volumes = Get-EC2Volume -Filter @{Name="attachment.instance-id";Value=$InstanceID} -Region $Region
    $Snapshots = @()
    foreach($Volume in $EC2Volumes){
        $Snapshot = New-EC2Snapshot -VolumeId $Volume.VolumeID -Description "AWS Test Helper Snapshot - $ID" -Region $Region
        $Snapshots += $Snapshot
        New-EC2Tag -Resource $Snapshot.SnapshotId -Tag @{Key="PowerShellAWSTestHelperID";Value=$ID} -Region $Region
        New-EC2Tag -Resource $Snapshot.SnapshotId -Tag @{Key="InstanceID";Value=$InstanceID} -Region $Region
    }

    if(!$Wait){
        $Wait
        $Snapshots
    }

    do{
        $SnapshotStatuses = @()
        foreach($Snapshot in $Snapshots){
            $SnapshotStatuses += Get-EC2Snapshot -SnapshotId $Snapshot.SnapshotId -Region $Region
        }
        Write-Verbose "Waiting for snapshots ($($Snapshots.SnapshotID -join ',')) to complete..."
        Start-sleep -s 10
    }while($SnapshotStatuses.State.Value -contains "pending")

    $SnapshotStatuses
}


