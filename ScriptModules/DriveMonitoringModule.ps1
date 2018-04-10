#DriveMonitoring Module
using module '.\ModuleDataStructs\DiskDrivesClassInterfaces.psm1'

Param(
    [switch]$VolumeMonitoring,
    [switch]$HDDMonitoring,
    [int]$SizeDataPrecision = -1,
    [switch]$LoopModule,
    [switch]$OutListFormat,
    [switch]$StressTestModule,
    [switch]$RunModuleForController
)

# InterfaceChange #
## Paramter Changed to RunModuleForController
$NoDisplay = $RunModuleForController
###

$TimesRan = 0
$AverageCPU = 0

# Configuration Variables

$JSONObj = (Get-Content ($PSScriptRoot + "..\..\ScriptConfigurations\DriveMonitoringConfig.json")) -join "`n" | ConvertFrom-Json

[bool]$AlertFreeDiskSpaceLow = $JSONObj.AlertFreeDiskSpaceLow
[int]$WarningDiskPercentageRemaining = $JSONObj.WarningDiskPercentageRemaining
[int]$SizeDataPrecision = $JSONObj.SizeDataPrecision

[bool]$AlertOnDriveStatusFailure = $JSONObj.AlertOnDriveStatusFailure

#Data Types

##Replaced inside of DDClassInterface


#Functions

Function AutoConvert-DataSize($DataSizeBytes)
{
    if($SizePrecision -lt 0) {$SizePrecision = 2}

    if(([math]::Round(($DataSizeBytes / 1TB)) -ge 1))
    {
        $tsize = $DataSizeBytes / 1TB
        $size = ([math]::Round($tsize, $SizePrecision))
        return "$size TB(s)"
    }

    if(([math]::Round(($DataSizeBytes / 1GB)) -ge 1))
    {
        $tsize = $DataSizeBytes / 1GB
        $size = ([math]::Round($tsize, $SizePrecision))
        return "$size GB(s)"
    }

    elseif(([math]::Round(($DataSizeBytes / 1MB)) -ge 1))
    {
        $tsize = $DataSizeBytes / 1MB
        $size = ([math]::Round($tsize, $SizePrecision))
        return "$size MB(s)"
    }

    elseif(([math]::Round(($DataSizeBytes / 1KB)) -ge 1))
    {
        $tsize = $DataSizeBytes / 1KB
        $size = ([math]::Round($tsize, $SizePrecision))
        return "$size KB(s)"
    }

    else
    {
        return "$size bytes"
    }
}

Function Convert-DriveCapabilities($DriveCapabilities)
{
    $ReturnOutput = @()
    foreach($capability in $DriveCapabilities)
    {
        Switch($capability)
        {
            0 {$ReturnOutput += "Unknown"; Break}
            1 {$ReturnOutput += "Other"; Break}
            2 {$ReturnOutput += "Sequential Access"; Break}
            3 {$ReturnOutput += "Random Access"; Break}
            4 {$ReturnOutput += "Supports Writing"; Break}
            5 {$ReturnOutput += "Encryption"; Break}
            6 {$ReturnOutput += "Compression"; Break}
            7 {$ReturnOutput += "Supports Removeable Media"; Break}
            8 {$ReturnOutput += "Manual Cleaning"; Break}
            9 {$ReturnOutput += "Automatic Cleaning"; Break}
            10 {$ReturnOutput += "SMART Notification"; Break}
            11 {$ReturnOutput += "Supports Dual Sided Media"; Break}
            12 {$ReturnOutput += "Predismount Eject Not Required"; Break}
            0 {$ReturnOutput += "Unknown"}
        }

    }

    return [string[]]$ReturnOutput
}

Function Convert-DriveTypeID($DrivetypeId)
{
    Switch($DrivetypeId)
    {
        0 {return "Unknown"; Break}
        1 {return "No Root Directory"; Break}
        2 {return "Removable Disk"; Break}
        3 {return "Local Disk"; Break}
        4 {return "Network Drive"; Break}
        5 {return "Compact Disc"; Break}
        6 {return "RAM Disk"; Break}
        0 {return "N/A"}

    }
}

Function Remove-WhiteSpace([string]$StringIn)
{
    $OutResult = ""

    for($i = 0; $i -lt $StringIn.Length; $i++)
    {
        if($StringIn[$i] -eq '' -or $StringIn[$i] -eq ' ')
        {
            continue
        }
        else
        {
            $OutResult += $StringIn[$i]
        }
    }

    return $OutResult
}

Function Display-DriveInfo()
{
    Param(
        [switch] $LogicalDrive,
        [switch] $HDD,
        [int] $SizePrecision = 2
    )

    if($LogicalDrive)
    {
        $LogicalDrives = Get-WmiObject -Class Win32_LogicalDisk
        $DiskMetaOut = [LogicalDisksMeta]::new()

        if(!$NoDisplay)
        {
            Write-Host "`nLogical Drive Data`n------------------"
        }

        $table = New-Object System.Data.DataTable "DriveTable"

        $CName = New-Object System.Data.DataColumn DriveLetter,([string])
        $VName = New-Object System.Data.DataColumn VolumeName,([string])
        $CSize = New-Object System.Data.DataColumn TotalSize,([string])
        $FSpace = New-Object System.Data.DataColumn FreeSpace,([string])
        $PSpaceUsed = New-Object System.Data.DataColumn SpaceUsed,([string])
        $PSpaceRemaining = New-Object System.Data.DataColumn SpaceRemaining,([string])
        $DSerial = New-Object System.Data.DataColumn DriveSerial,([string])
        $DType = New-Object System.Data.DataColumn Drivetype,([string])
        $DFileSystem = New-Object System.Data.DataColumn DriveFileSystem,([string])
        $DDescription = New-Object System.Data.DataColumn Description,([string])

        $table.Columns.Add($CName)
        $table.Columns.Add($VName)
        $table.Columns.Add($CSize)
        $table.Columns.Add($FSpace)
        $table.Columns.Add($PSpaceUsed)
        $table.Columns.Add($PSpaceRemaining)
        $table.Columns.Add($DSerial)
        $table.Columns.Add($DType)
        $table.Columns.Add($DFileSystem)
        $table.Columns.Add($DDescription)

        foreach ($logicdrive in $LogicalDrives)
        {
            $row = $table.NewRow()
            [DiskDrivesClassInterfaces.LogicalDisk]$ldObj = [DiskDrivesClassInterfaces.LogicalDisk]::new()

            $row.DriveLetter = $logicdrive.Name
            $ldObj.DriveLetter = $logicdrive.Name

            $row.Description = $logicdrive.Description
            $ldObj.Description = $logicdrive.Description


            
            if($logicdrive.Size -le 0)
            {
                $row.SpaceUsed = "N/A"
                $row.VolumeName = "N/A"
                $row.FreeSpace = "N/A"
                $row.TotalSize = "N/A"         
                $row.SpaceRemaining = "N/A"
                $row.DriveSerial = "N/A"
                $row.DriveType = "N/A"
                $row.DriveFileSystem = "N/A"

                $ldObj.TotalSize = 0
                $ldObj.VolumeName = "N/A"
                $ldObj.FreeSpace = 0
                $ldObj.SpaceRemaining = 0
                $ldObj.DriveSerial = "N/A"
                $ldObj.DriveType = "N/A"
                $ldObj.DriveFileSystem = "N/A"

                $table.Rows.Add($row)
                $DiskMetaOut.Add($ldObj)

                continue
            }

            $row.VolumeName = $logicdrive.VolumeName
            $ldObj.VolumeName = $logicdrive.VolumeName

            $row.TotalSize = AutoConvert-DataSize($logicdrive.Size)
            $ldObj.TotalSize = $logicdrive.Size

            $row.FreeSpace = AutoConvert-DataSize($logicdrive.FreeSpace)
            $ldObj.FreeSpace = $logicdrive.FreeSpace

            $SpaceRemaining = [math]::Round(($logicdrive.FreeSpace / $logicdrive.Size) * 100, 2)
            $SpaceUsed = [math]::Round(100 - $SpaceRemaining, 2)
            $row.SpaceUsed = "$SpaceUsed %"
            $ldObj.SpaceUsed = $SpaceUsed

            $row.SpaceRemaining = "$SpaceRemaining %"
            $ldObj.SpaceRemaining = $SpaceRemaining

            $row.DriveSerial = $logicdrive.VolumeSerialNumber
            $ldObj.DriveSerial = $logicdrive.VolumeSerialNumber

            $row.DriveType = Convert-DriveTypeID($logicdrive.DriveType)
            $ldObj.DriveType = Convert-DriveTypeID($logicdrive.DriveType)

            $row.DriveFileSystem = $logicdrive.FileSystem
            $ldObj.DriveFileSystem = $logicdrive.FileSystem

            $table.Rows.Add($row)
            
            #Error Checking Logic
            if($AlertFreeDiskSpaceLow)
            {
                if($ldObj.SpaceRemaining -lt $WarningDiskPercentageRemaining -and $ldObj.DriveType -eq "Local Disk")
                {
                    [DiskDrivesClassInterfaces.Error]$LogicDriveError = [DiskDrivesClassInterfaces.Error]::new()
                    $LogicDriveError.DeviceID = $ldObj.DriveLetter
                    $LogicDriveError.ErrorID = "LOW DISK SPACE"
                    $LogicDriveError.ErrorDescription = ("Drive " + $LogicDriveError.DeviceID + " has less than $WarningDiskPercentageRemaining% space remaining!")

                    $DiskMetaOut.RegisterError($LogicDriveError)
                }
            }


            $DiskMetaOut.Add($ldObj)
        }


        #Table Print Volume Drive Data
        if(!$NoDisplay)
        {
            if($OutListFormat)
            {
                $table | Format-List
            }
            else
            {
                $table | Format-Table -Wrap
            }

        }


          return [DiskDrivesClassInterfaces.LogicalDisksMeta]$DiskMetaOut

    }

    elseif($HDD)
    {
        $DiskDrives = Get-WmiObject -Class Win32_DiskDrive
        $PhysicalDisksMetaOut = [PhysicalDisksMeta]::new()

        if(!$NoDisplay)
        {
            Write-Host "`nDisk Drive Data`n------------------"
        }

        $table = New-Object System.Data.DataTable "DiskTable"

        $DDeviceID = New-Object System.Data.DataColumn DeviceID,([string])
        $DParts = New-Object System.Data.DataColumn Partitions,([string])
        $DBytesPerSect = New-Object System.Data.DataColumn BytesPerSector,([string])
        $DIType = New-Object System.Data.DataColumn InterfaceType,([string])
        $DCapabilities = New-Object System.Data.DataColumn Capabilities,([string])
        $DCapabilitiesDescriptions = New-Object System.Data.DataColumn CapabilityDescriptions,([string])
        $DDescription = New-Object System.Data.DataColumn Description,([string])
        $DMediaType = New-Object System.Data.DataColumn MediaType,([string])
        $DModel = New-Object System.Data.DataColumn Model,([string])
        $DSerial = New-Object System.Data.DataColumn SerialNumber,([string])
        $DSCSIBus = New-Object System.Data.DataColumn SCSIBus,([string])
        $DSCSIPort = New-Object System.Data.DataColumn SCSIPort,([string])
        $DSize = New-Object System.Data.DataColumn TotalSize,([string])
        $DStatus = New-Object System.Data.DataColumn DiskStatus,([string])
        
        $table.Columns.Add($DDeviceID)
        $table.Columns.Add($DParts)
        $table.Columns.Add($DBytesPerSect)
        $table.Columns.Add($DIType)
        $table.Columns.Add($DCapabilities)
        $table.Columns.Add($DCapabilitiesDescriptions)
        $table.Columns.Add($DDescription)
        $table.Columns.Add($DMediaType)
        $table.Columns.Add($DModel)
        $table.Columns.Add($DSerial)
        $table.Columns.Add($DSCSIBus)
        $table.Columns.Add($DSCSIPort)
        $table.Columns.Add($DSize)
        $table.Columns.Add($DStatus)

        foreach($disk in $DiskDrives)
        {
            $row = $table.NewRow()
            $pdisk = [PhysicalDisk]::new()

            $row.Capabilities = $disk.Capabilities | Out-String
            $row.CapabilityDescriptions = $disk.CapabilityDescriptions | Out-String
            
            $row.DeviceID = $disk.DeviceID
            $pdisk.DeviceID = $disk.DeviceID

            $row.Partitions = $disk.Partitions
            $pdisk.Partitions = $disk.Partitons

            $row.BytesPerSector = $disk.BytesPerSector
            $pdisk.BytesPerSector = $disk.BytesPerSector

            $row.Interfacetype = $disk.InterfaceType
            $pdisk.InterfaceType = $disk.InterfaceType

            $row.Description = $disk.Description
            $pdisk.Description = $disk.Description

            $row.MediaType = $disk.MediaType
            $pdisk.MediaType = $disk.MediaType

            $row.Model = $disk.Model
            $pdisk.Model = $disk.Model
            
            $row.SerialNumber = Remove-WhiteSpace($disk.SerialNumber)
            $pdisk.SerialNumber = Remove-WhiteSpace($disk.SerialNumber)

            $row.SCSIBus = $disk.SCSIBus
            $pdisk.SCSIBus = $disk.SCSIBus

            $row.SCSIPort = $disk.SCSIPort
            $pdisk.SCSIPort = $disk.SCSIPort

            $row.TotalSize = AutoConvert-DataSize($disk.Size)
            $pdisk.Size = $disk.Size

            $row.DiskStatus = $disk.Status
            $pdisk.Status = $disk.Status

            $table.Rows.Add($row)
            $PhysicalDisksMetaOut.Add($pdisk)
        }

        if(!$NoDisplay)
        {

            if($OutListFormat)
            {
                $table | Format-List
            }
       
           else
           {
               $table | Format-Table -Wrap
           }

        }

        if($AlertOnDriveStatusFailure)
        {

            foreach($entry in $table)
            {
                if($entry.DiskStatus -ne "OK")
                {
                    if(!$NoDisplay)
                    {
                        Write-Host ("Drive " + $entry.DeviceID + " is failing! Current Status: " + $entry.DiskStatus) -ForegroundColor Yellow -BackgroundColor Red
                    }

                }
            }
        }

        return [DiskDrivesClassInterfaces.PhysicalDisksMeta]$PhysicalDisksMetaOut
    }
   
}

# RUNTIME
if($VolumeMonitoring -and $HDDMonitoring)
{
    Write-Host "ERROR: VolumeMonitoring and HDDMonitoring Flags cannot both be set!" -ForegroundColor Red -BackgroundColor Yellow
    return "Invalid Module Parameters"
}

if($LoopModule)
{
    while($true)
    {
        if($VolumeMonitoring)
        {
            Display-DriveInfo -LogicalDrive -SizePrecision $SizeDataPrecision
        }
        if($HDDMonitoring)
        {
            Display-DriveInfo -HDD -SizePrecision $SizeDataPrecision
        }

        if(!$StressTestModule)
        {
            Start-Sleep -Seconds 1
        }
        else
        {
            $TimesRan += 1
            Write-Progress -Status "StressTesting" -PercentComplete (($TimesRan / 1000) * 100) -Activity ("$TimesRan / 1000" + " " + (($TimesRan / 1000) * 100) + " %")

            if($TimesRan % 100 -eq 0)
            {
                $AverageCPU += (Get-WmiObject win32_processor).LoadPercentage
            }

            if($TimesRan -ge 1000)
            {
                Write-Host "Stress Test Complete..."
                Write-Host ("Average CPU Load was " + ($AverageCPU / 10) + "%")
                return
                exit
            }
        }

        cls

    }
}

else
{
    if($VolumeMonitoring)
    {
        return Display-DriveInfo -LogicalDrive -SizePrecision $SizeDataPrecision
    }

    if($HDDMonitoring)
    {
        return Display-DriveInfo -HDD -SizePrecision $SizeDataPrecision
    }
}