Add-Type -TypeDefinition ((Get-Content -Path ".\ModuleCoreFunctionality.cs") | Out-String)

[ModuleStreamIO.PipeServer]$PipeServer = [ModuleStreamIO.PipeServer]::new()

while($true)
{
    $PipeServer.ReadStreamData()
}