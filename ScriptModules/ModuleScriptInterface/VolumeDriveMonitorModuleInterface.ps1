using module '..\ProgrammingAPI\ModuleCore.psm1'
using module '..\ModuleDataStructs\DiskDrivesClassInterfaces.psm1'
using module '..\DriveMonitoringModule.ps1'

[BasicModule]$Module = [BasicModule]::new()

Function RunFunction
{
    $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\DriveMonitoringModule.ps1"
    $ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath ".\Interface Module Configs\VolumeDriveMonitorModuleInterfaceConfig.json"
    $Results = & $ScriptPath -VolumeMonitoring -RunModuleForController
    $ConfigSettings = ImportJSON($ConfigPath)

    [Alerts]$Alerts = [Alerts]::new()
    $Alerts.OwningModuleName = "VolumeDriveMonitorModuleInterface"

    foreach($disk in $Results.DrivesMeta)
    {
        [LogicalDisk]$ldisk = [LogicalDisk]::new()
        $ldisk = $disk

        if($ldisk.SpaceRemaining -lt $ConfigSettings.MinimumFreeSpacePercent -and $ldisk.DriveType -eq "Local Disk")
        {
            [Alert]$Alert = [Alert]::new()
            $Alert.AlertId = $ldisk.DriveLetter

            $Alert.AlertDescription = ("Drive " + $ldisk.DriveLetter + " is low on space! | FreeSpaceRemaining: " + $ldisk.SpaceRemaining + "%")

            $Alerts.Add($Alert)

			[ModuleCore.ProcessController]::AddProcess("VolumeDriveMonitoringModuleInterface", ("LowSpace:" + $ldisk.DriveLetter), ("DriveLetter:" + $ldisk.DriveLetter + "DiskSpaceRemaining:" + $ldisk.SpaceRemaining), [ModuleCore.ProcessStatus]::Unaddressed)
        }

        if($ConfigSettings.UseVerbose)
        {
            if([ModuleCore.ProcessController]::DoesProcessExist("VolumeDriveMonitoringModuleInterface", ("LowSpace:" + $ldisk.DriveLetter)))
            {
                Write-Host ("Drive Letter: " + $ldisk.DriveLetter + "`tSerial: " + $ldisk.DriveSerial + "`tFileSystem: " + $ldisk.DriveFileSystem + " (" + [ModuleCore.ProcessController]::GetProcess("VolumeDriveMonitoringModuleInterface", ("LowSpace:" + $ldisk.DriveLetter)).Status + ")") -ForegroundColor Yellow -BackgroundColor Red
            }
            else
            {
                Write-Host ("Drive Letter: " + $ldisk.DriveLetter + "`tSerial: " + $ldisk.DriveSerial + "`tFileSystem: " + $ldisk.DriveFileSystem) -ForegroundColor Yellow -BackgroundColor Black
            }
        }

    }

    #Register Alerts To Process
    RegisterAlert($Alerts)
}

Function AlertsBehaviorFunction
{
    #Get Registered Alerts of this Module
    $errs = GetAlert("VolumeDriveMonitorModuleInterface")
    
    if($errs.RegisteredAlerts.Count -eq 0)
    {
        return
    }

    Write-Host "`nReported Errors for VolumeDriveMonitoringModuleInterface`n---------------------------------------------------`n"
    foreach($alert in $errs.RegisteredAlerts)
    {
        ## Repair Behavior
        [ModuleCore.Process]$Process = [ModuleCore.ProcessController]::GetProcess("VolumeDriveMonitoringModuleInterface", ("LowSpace:" + $alert.AlertId))
        if($Process.Status -eq [ModuleCore.ProcessStatus]::Unaddressed)
        {
            Write-Host $alert.AlertDescription -BackgroundColor Red -ForegroundColor Yellow
            Write-Host ("Addressing error: " + $alert.AlertDescription + "`n")
            [ModuleCore.ProcessController]::UpdateProcessStatus("VolumeDriveMonitoringModuleInterface", ("LowSpace:" + $alert.AlertId), [ModuleCore.ProcessStatus]::InProgress)

            #..\DiskCleanup.ps1
        }
        else
        {
            write-host (Get-Job | Out-String)
        }
    }
}
$Module.ModuleName = "VolumeDriveMonitorModuleInterface"
$Module.Parameters = "-VolumeMonitoring -RunModuleForController"
$Module.ModuleRunFunction = $Function:RunFunction
$Module.ModuleAlertFunction = $Function:AlertsBehaviorFunction

return $Module