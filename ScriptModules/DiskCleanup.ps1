param([bool]$Arm = $false, [bool]$CreateArmedFile = $false, [string]$ArmedDesiredFilePath = "C:\")

if($CreateArmedFile -eq $true)
{
    $ProgramFile = Get-Content .\DiskCleanup.ps1
    $ProgramFile += "`n Remove-Item .\DiskCleanupARMD.ps1 -Force"

    $ProgramFile | Out-File .\DiskCleanupARMD.ps1

    attrib.exe +r .\DiskCleanupARMD.ps1
    exit
}

if($Arm -eq $true)
{
    Write-Host "This script is Armed to AUTO-DELETE at the end of the script~!" -ForegroundColor Yellow -BackgroundColor Red
}

# User Defined Variables

$ParentDirectoriesToSearch = @(
"C:\Windows\Logs\",
"C:\Windows\temp\",
"C:\Windows\SoftwareDistribution\*bits&wuauserv",
"C:\Users\%USER_DIR%\AppData\Local\Temp\",
"C:\Users\%USER_DIR%\AppData\LocalLow\Temp\"
)

$ProgramsToShutdown = @(
"Outlook",
"OneDrive",
"Lync"
)



########################
########################
# FUNCTION DEFINITIONS #
#----------------------#

Function ShutdownProgramProcesses([string]$program)
{
    Get-Process "*$program*" | Stop-Process
}

Function GetTranslateUserFolderPath([string]$directory)
{
    $DirectoryPath = $directory.Split('%')
    $bD = $DirectoryPath[0]

    if($DirectoryPath.Count -le 1)
    {
        $values = $directory.Split('*')
        return $values[0]
    }
    
    $dD = Get-ChildItem -Path $bD | Select-Object FullName
    
    $values = ""

    foreach($path in $dD)
    {
        $fullpath = $path.FullName

        for($i=0; $i -le $DirectoryPath.Count; $i++)
        {
            if($i -gt 1)
            {
                $fullpath += $DirectoryPath[$i]
            }
        }

        $values += "`n"
        $values += $fullpath
    }

    $result = $values.Split("`n")

    return $result

}

function ServiceKiller([string]$directory)
{
    try
    {
        $DirectoryData = $directory.Split('*')
        $ServiceCodes = $DirectoryData[1].Split('&')
    }
    
    catch
    {
        return
    }

    foreach($serviceName in $ServiceCodes)
    {
        net stop $serviceName
    }
}

function ServiceRestorer([string]$directory)
{
    try
    {
        $DirectoryData = $directory.Split('*')
        $ServiceCodes = $DirectoryData[1].Split('&')
    }
    
    catch
    {
        return
    }

    foreach($serviceName in $ServiceCodes)
    {
        net start $serviceName
    }
}

function TakeOwnership
{
    
    param(
    [string]$Directory
    )


    takeown /R /A /F $Directory /D N

}

function AdvancedRemove-Item
{

    param(
    [string]$Directory = "null"
    )

    #$item = Get-ChildItem -Path $Directory -Recurse
        
    Write-Host $Directory
}

###############################################
#//////////////PROGRAM START \\\\\\\\\\\\\\\\\#
###############################################

Write-Host "Shutting Down Programs..."

foreach($eentry in $ProgramsToShutdown)
{
    Write-Host "Shutdown " -NoNewline
    Write-Host $eentry
    ShutdownProgramProcesses($eentry)
}

$beginLogicalDrive = Get-WmiObject -Class "Win32_LogicalDisk" | where{$_.DeviceID -like "*C*"}
$freespace = $beginLogicalDrive.FreeSpace


foreach($entry in $ParentDirectoriesToSearch)
{
    ServiceKiller($entry)
}

foreach($entry in $ParentDirectoriesToSearch)
{
    $dynamicfiles = GetTranslateUserFolderPath($entry)

    [int]$count = 0;

    foreach($folder in $dynamicfiles)
    {
        if($folder -eq "" -or $folder -eq "`n")
        {
            continue
        }

        else
        {
            #AdvancedRemove-Item -Directory $folder
            Write-Host $folder -BackgroundColor Blue -NoNewline
            Write-Host $count
            $count += 1
            Write-Host "----------------------`n`n" -ForegroundColor Blue

            TakeOwnership -Directory $folder
            Remove-Item -Recurse -LiteralPath $folder

            Write-Host "Removed $folder" -ForegroundColor Blue
        }
    }
}

foreach($entry in $ParentDirectoriesToSearch)
{
    ServiceRestorer($entry)
}

$endLogicalDrives = $logicalDrives | where{$_.DeviceID -like "*C*"}
$endfreespace = $endLogicalDrives.FreeSpace - $beginLogicalDrive.FreeSpace
$endfreespace = $endfreespace - 44765184
$gibi = $endfreespace / 1GB
$mibi = $endfreespace / 1MB
$kibi = $endfreespace / 1KB
$byt = $endfreespace

Write-Host "Total Free Space: " -NoNewline
$totalspace = Get-WmiObject -Class "Win32_LogicalDisk" | where{$_.DeviceID -like "*C*"}
Write-Host ($totalspace.FreeSpace / 1GB) -NoNewline
Write-Host " GB(s)"

Write-Host "Freed $gibi GB(s) of data..." -ForegroundColor Green
Write-Host "Freed $mibi MB(s) of data..." -ForegroundColor Green
Write-Host "Freed $kibi KB(s) of data..." -ForegroundColor Green
Write-Host "Freed $endfreespace B(s) of data..." -ForegroundColor Green

if($Arm -eq $true)
{
    Remove-Item .\DiskCleanup.ps1 -Force
}