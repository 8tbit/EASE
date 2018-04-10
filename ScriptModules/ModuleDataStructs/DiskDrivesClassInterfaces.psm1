@{
ModuleVersion = "1.0.0.0"
Author = "Austin Berry"
Copyright = "Eniari Studios"
PowerShellVersion = "5.0"
DotNetFrameworkVersion = "4.0"
}

Class Error
{
    [string]$ErrorID
    [string]$DeviceID
    [string]$ErrorDescription
}

Class ErrorsMeta
{
    $DriveErrorsMeta = @()

    Add([Error]$ErrorEntry)
    {
        $this.DriveErrorsMeta += $ErrorEntry
    }
}

Class LogicalDisk
{
    [string]$DriveLetter
    [string]$VolumeName
    [uint64]$TotalSize
    [uint64]$FreeSpace
    [float]$SpaceUsed
    [float]$SpaceRemaining
    [string]$DriveSerial
    [string]$DriveType
    [string]$DriveFileSystem
    [string]$Description
}

Class PhysicalDisk
{
    [string]$DeviceID
    [int]$Partitions
    [uint32]$BytesPerSector
    [string]$InterfaceType
    [string]$Description
    [string]$MediaType
    [string]$Model
    [string]$SerialNumber
    [string]$SCSIBus
    [string]$SCSIPort
    [uint64]$Size
    [string]$Status
}

Class LogicalDisksMeta
{
    $DrivesMeta = @()
    [ErrorsMeta]$Errors = [ErrorsMeta]::new()

    Add($LogicalDiskMeta)
    {
        $this.DrivesMeta += $LogicalDiskMeta
    }

    RegisterError([Error]$Error)
    {
        $this.Errors.Add($Error)
    }
}

Class PhysicalDisksMeta
{
    $DisksMeta = @()
    [ErrorsMeta]$Errors = [ErrorsMeta]::new()

    Add($PhysicalDiskMeta)
    {
        $this.DisksMeta += $PhysicalDiskMeta
    }

    RegisterError([Error]$Error)
    {
        $this.Errors.Add($Error)
    }
}