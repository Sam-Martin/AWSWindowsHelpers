function Update-AWSWindowsHelperAMI{
    Param(
        [Parameter(Mandatory=$true)]
        $Region,
        [Parameter(Mandatory=$true)]
        $InstanceID
    )
    
    $UserData = {
        $TaskName = "AMI Windows Patching"
        try{
            $STPrin = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
            $STTri1 = New-ScheduledTaskTrigger -AtStartup
            $STTri2 = New-ScheduledTaskTrigger -Once -At $(Get-Date) -RepetitionInterval "00:01:00" -RepetitionDuration $([TimeSpan]::MaxValue)
            $STAct = New-ScheduledTaskAction -Execute "PowerShell.exe" `
                -Argument $('-executionpolicy Bypass -NonInteractive -c "powershell -executionpolicy Bypass -NonInteractive -c '+$($MyInvocation.MyCommand.Definition)+' -verbose >>  C:\PatchingScheduledTask.log 2>&1"')
            Register-ScheduledTask -Principal $STPrin -Trigger @($STTri1,$STTri2) -TaskName $TaskName -Action $STAct
        }catch{
            Write-Error $_.exception.message
        }

        # Install PSWindowsUpdate using Chocolatey
        Set-ExecutionPolicy Unrestricted -Force
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 
        choco source add -n=chocolatey -s="https://chocolatey.org/api/v2/" -y
        choco source add -n=psgallery -s="https://www.powershellgallery.com/api/v2/" -y
        choco install pswindowsupdate -y
        import-module C:\ProgramData\chocolatey\lib\PSWindowsUpdate\PSWindowsUpdate.psd1
        if(Get-WUList){
            Write-Host "Updates required, installing"
            Get-WUInstall -AcceptAll -AutoReboot | Out-File C:\PSWindowsUpdate.log
        }else{
            Get-ScheduledTask -TaskName $TaskName | Unregister-ScheduledTask -Confirm:$false
            Write-Host "No updates needed, stopping computer"
            Stop-Computer -Force
        }
    }

    Send-SSMCommand -DocumentName "AWS-RunPowerShellScript" -Parameter @{commands=[string]$UserData} -InstanceId $InstanceID -Region $Region

    Write-Verbose "Executed SSM command to update Windows instance and shutdown upon completion"
}