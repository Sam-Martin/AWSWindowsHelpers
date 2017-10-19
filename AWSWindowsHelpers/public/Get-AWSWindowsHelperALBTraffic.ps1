function Get-AWSWindowsHelperALBTraffic{
    param(
        [parameter(Mandatory=$True)]
        [string]$AWSRegion,
        [parameter(Mandatory=$True)]
        [string]$ALBName,
        [parameter(Mandatory=$True)]
        [datetime]$StartTime,
        [parameter(Mandatory=$True)]
        [datetime]$EndTime

    )
    Write-Verbose "Getting traffic for $ALBName"
    $Params = @{
        Namespace = 'AWS/ApplicationELB' 
        MetricName = 'ProcessedBytes' 
        Dimension = @{"Name"="LoadBalancer";Value=$ALBName} 
        Region = $AWSRegion
        StartTime = $StartTime
        EndTime = $EndTime
        Period = $(24 * 60 * 60) 
        Statistic = 'Sum'
    }
    $MetricStatistics = Get-CWMetricStatistic @Params

    return New-Object psobject -Property @{
        StartTime = $StartTime
        EndTime = $Endtime
        ALBName = $ALBName
        MBProcessed = ($MetricStatistics.Datapoints.sum | measure-object  -sum).Sum /1MB
    }
}