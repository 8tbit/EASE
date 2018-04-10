@{
ModuleVersion = "1.0.0.0"
Author = "Austin Berry"
Copyright = "Eniari Studios"
PowerShellVersion = "5.0"
FunctionToExport = "RegisterAlert, GetAlert, ImportJSON"
}

Function RegisterAlert([Alerts]$Alerts)
{
    $ResultLocation = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Controller\SystemMemory\Alerts.json"
    $Alerts | ConvertTo-Json | Out-File -FilePath $ResultLocation -Append
}

Function GetAlert($AlertOwningModuleName)
{
    $ResultLocation = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Controller\SystemMemory\Alerts.json"
    $JSONResults = (Get-Content $ResultLocation) -join "`n" | ConvertFrom-Json
    $OutResults = $JSONResults | where{$_.OwningModuleName -eq $AlertOwningModuleName}

    $NewJSON

    foreach($entry in $JSONResults)
    {
        if($entry.OwningModuleName -ne $AlertOwningModuleName)
        {
            $NewJSON += $entry
        }
    }

    $NewJSON | ConvertTo-Json | Out-File -FilePath $ResultLocation -Force

    return $OutResults
}

Function ImportJSON($ConfigFileLocation)
{
    $Data = (Get-Content $ConfigFileLocation) -join "`n" | ConvertFrom-Json

    return $Data
}

Class ModuleResult
{
    [string]$FunctionName
    $ModuleResultValue
}

Class ModuleResults
{
    $ModuleResults = @()

    Add([ModuleResult]$Result)
    {
        $this.ModuleResults += $Result
    }
}

Class Alert
{
    [string]$AlertId
    [string]$AlertDescription
}

Class Alerts
{
    [string]$OwningModuleName
    $RegisteredAlerts = @()

    Add([Alert]$AlertObj)
    {
        $this.RegisteredAlerts += $AlertObj
    }
}

Class BasicModule
{
    [string]$ModuleName
    [string]$ModuleFileLocation
    $ModuleRunFunction
    $ModuleAlertFunction
    [string]$Parameters
    $ReportedAlerts

    [ModuleResults]$Results = [ModuleResults]::new()

}

Add-Type -TypeDefinition ((Get-Content -Path "..\ScriptModules\ProgrammingAPI\ModuleCoreFunctionality.cs") | Out-String)