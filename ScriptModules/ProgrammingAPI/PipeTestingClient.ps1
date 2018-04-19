Add-Type -TypeDefinition ((Get-Content -Path ".\ModuleCoreFunctionality.cs") | Out-String)

[ModuleStreamIO.PipeServer]$PipeClient = [ModuleStreamIO.PipeServer]::new()

while($true)
{
    $PipeClient.SendStreamData((Read-Host "Enter message: "))
}