@{
ModuleVersion = "1.0.0.0"
Author = "Austin Berry"
Copyright = "Eniari Studios"
PowerShellVersion = "5.0"
}

Class NetworkSettings
{
    [string]$IPAddress
    [string]$DefaultGateway
    [string]$SubnetMask
    [string]$DNSServer
    [string]$InterfaceDescription
}

Class NetworkAdapters
{
    $NetworkAdapters = @()

    AddAdapter([NetworkSettings]$Adapter)
    {
        $this.NetworkAdapters += $Adapter
    }
}