function Update-AWSWindowsHelperAMI{
    Param(
        [Parameter(Mandatory=$true)]
        $Region,
        [Parameter(Mandatory=$true)]
        $InstanceID
    )
    
    $UserData = {
        $TaskName = "AMI Windows Patching"
        Start-Transcript -Path $Env:Temp\WindowsPatching.log -NoClobber
        if(-not $(Get-ScheduledTask -TaskName 'AMI Windows Patching')){
            try{
                Write-Host "Attempting to create Scheduled Task '$TaskName'"
                $STPrin = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
                $STTri1 = New-ScheduledTaskTrigger -AtStartup
                $STTri2 = New-ScheduledTaskTrigger -Once -At $(Get-Date) -RepetitionInterval "00:01:00" -RepetitionDuration $([TimeSpan]::MaxValue)
                $STAct = New-ScheduledTaskAction -Execute "PowerShell.exe" `
                    -Argument $('-executionpolicy Bypass -NonInteractive -c "powershell -executionpolicy Bypass -NonInteractive -c '+$($MyInvocation.MyCommand.Definition)+' -verbose >>  %TEMP%\PatchingScheduledTask.log 2>&1"')
                Register-ScheduledTask -Principal $STPrin -Trigger @($STTri1,$STTri2) -TaskName $TaskName -Action $STAct
                Write-Host "Successfully created Scheduled Task '$TaskName'"
            }catch{
                Write-Error $_.exception.message
            }
        }
        # Install PSWindowsUpdate using Chocolatey
        if(-not $(Get-Command choco)){
            Write-Output "Installing chocolatey"
            iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 
        }
        choco source add -n=chocolatey -s="https://chocolatey.org/api/v2/" -y
        choco source add -n=psgallery -s="https://www.powershellgallery.com/api/v2/" -y
        choco install pswindowsupdate -y
        import-module C:\ProgramData\chocolatey\lib\PSWindowsUpdate\PSWindowsUpdate.psd1
        if(Get-WUList){
            Write-Output "Updates required, installing"
            Get-WUInstall -AcceptAll -AutoReboot | Out-File $Env:Temp\PSWindowsUpdate.log
        }else{
            Get-ScheduledTask -TaskName $TaskName | Unregister-ScheduledTask -Confirm:$false
            Write-Output "No updates needed, stopping computer"
            Stop-Computer -Force
        }
        Stop-Transcript
    }

    try{
        $SSMCommand = Send-SSMCommand -DocumentName "AWS-RunPowerShellScript" -Parameter @{commands=[string]$UserData} -InstanceId $InstanceID -Region $Region
    }catch{
        if($_.FullyQualifiedErrorId -like "*Amazon.SimpleSystemsManagement.Model.InvalidInstanceIdException*"){
            Write-Error "Invalid Instance ID, does the AMI have a version of the EC2 config service installed which is compatible with SSM?"
            return
        }

        Write-Error $_.exception.message
    }
    Write-Verbose "Executed SSM command ($($SSMCommand.CommandId)) to update Windows instance and shutdown upon completion"
}