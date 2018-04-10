using module '..\ProgrammingAPI\ModuleCore.psm1'
using module '..\ModuleDataStructs\DiskDrivesClassInterfaces.psm1'
using module '..\DriveMonitoringModule.ps1'

[BasicModule]$Module = [BasicModule]::new()

Function RunFunction
{
    $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\DriveMonitoringModule.ps1"
    $Results = & $ScriptPath -HDDMonitoring -RunModuleForController

    foreach($disk in $Results.DisksMeta)
    {
    }
}
$Module.Parameters = "-HDDMonitoring -RunModuleForController"
$Module.ModuleRunFunction = $Function:RunFunction

return $Module