Add-Type -TypeDefinition ((Get-Content -Path "$PSScriptRoot\WebServerTypes.cs") | Out-String)

[Webserver.WebpageViewbagDefinitions]$Definitions = [Webserver.WebpageViewbagDefinitions]::new()
[Webserver.WebPage]$webpage = [Webserver.WebPage]::new()

$Definitions.RegisterDefinition("@globaltime", [datetime]::UtcNow)
$Definitions.RegisterDefinition("@global.computer.os", (Get-WmiObject -Class Win32_OperatingSystem | select -ExpandProperty Name))
$Definitions.RegisterDefinition("@global.computer.name", $env:USERNAME)

$defs = $Definitions.GetDefinitions().GetEnumerator()

$HTMLTestcode = @"
The time is currently @globaltime on the os of @osname\n
The user is @user
"@

$webpage.LoadContentFromFile(".\index.html")
Write-Host ([Webserver.ViewbagTranslator]::TranslateHTML([ref]$webpage, [ref]$Definitions))