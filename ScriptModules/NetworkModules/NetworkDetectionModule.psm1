using module '.\NetworkInterface.psm1'

@{
Version = 1.0
Author = "Austin Berry"
Copyright = "Eniari Studios"
PowerShellVersion = "5.0"
DotNetFrameworkVersion = "4.0"
FunctionsToExport = "Get-NetworkSettings"
}

Function Get-NetworkSettings
{

$Adapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE
[NetworkInterface.NetworkAdapters]$NetworkAdaptersOut = [NetworkInterface.NetworkAdapters]::new()

foreach($net in $Adapters)
{
    $Adapter = [NetworkInterface.NetworkSettings]::new()

    $Adapter.IPAddress = $net.IPAddress
    $Adapter.IPAddress = ($Adapter.IPAddress.Split(' ', [System.StringSplitOptions]::None))[0]

    $Adapter.DefaultGateway = $net.DefaultIPGateway
    $Adapter.DNSServer = $net.DNS
    $Adapter.InterfaceDescription = $net.Description

    $Adapter.SubnetMask = $net.IPSubnet
    $Adapter.SubnetMask = ($Adapter.SubnetMask.Split(' ', [System.StringSplitOptions]::None))[0]

    $NetworkAdaptersOut.AddAdapter($Adapter)
}

return [NetworkInterface.NetworkAdapters]$NetworkAdaptersOut

}