Add-Type -TypeDefinition ((Get-Content -Path ".\ModuleCoreFunctionality.cs") | Out-String)

[ModuleStreamIO.PipeServer]$PipeClient = [ModuleStreamIO.PipeServer]::new()

for($i = 0; $i -lt 10; $i++)
{
$PipeClient.SendStreamData("Hello World! How are you doing today?")
Start-Sleep -Milliseconds (Get-Random -Minimum 200 -Maximum 1000)
}