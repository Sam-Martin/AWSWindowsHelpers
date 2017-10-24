function Get-AWSWindowsHelperAuroraStorage{
    param(
        [parameter(Mandatory=$True)]
        [string]$AWSRegion,
        [parameter(Mandatory=$True)]
        [string]$RDSClusterName,
        [parameter(Mandatory=$True)]
        [datetime]$StartTime,
        [parameter(Mandatory=$True)]
        [datetime]$EndTime,
        [int]$Period = $(24 * 60 * 60),
        [switch]$MaxInRange
    )
    Write-Verbose "Getting VolumeBytesUsed for $RDSClusterName"
    $Params = @{
        Namespace = 'AWS/RDS' 
        MetricName = 'VolumeBytesUsed' 
        Dimension = @(
            @{"Name"="DbClusterIdentifier";Value=$RDSClusterName} 
            @{"Name"="EngineName";Value="aurora"} 
        )
        Region = $AWSRegion
        StartTime = $StartTime
        EndTime = $EndTime
        Period = $Period
        Statistic = 'Maximum'
    }
    $MetricStatistics = Get-CWMetricStatistic @Params

    if($MaxInRange){
        New-Object psobject -Property @{
            "MegabytesUsed" = ($MetricStatistics.Datapoints.Maximum | Measure-Object -Maximum).Maximum/1MB
            "ClusterName" = $RDSClusterName
        }
    }else{
        New-Object psobject -Property @{
            "BytesUsed" = $MetricStatistics
            "ClusterName" = $RDSClusterName
        }
    }
}