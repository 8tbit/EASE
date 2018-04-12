@{
ModuleVersion = "1.0.0.0"
Author = "Austin Berry"
Copyright = "Eniari Studios"
PowerShellVersion = "5.0"
FunctionToExport = "RegisterAlert, GetAlert, ImportJSON"
}

Add-Type -TypeDefinition ((Get-Content -Path "..\ScriptModules\ProgrammingAPI\ModuleCoreFunctionality.cs") | Out-String)

Function RegisterAlert([ModuleCore.Alerts]$Alerts)
{
    $ResultLocation = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\Controller\SystemMemory\Alerts.json" -Resolve)

    [ModuleCore.AlertsContainer]$AContainer = [ModuleCore.AlertsContainer]::new()
    
    $PrevAlertsContainer = ImportJSON($ResultLocation)

    if($PrevAlertsContainer -ne $null)
    {
        foreach($entry in $PrevAlertsContainer.AlertContainer)
        {
            [ModuleCore.Alerts]$mAlerts = [ModuleCore.Alerts]::new()

            $mAlerts.RegisteredAlerts = $entry.RegisteredAlerts
            $mAlerts.OwningModuleName = $entry.OwningModuleName

            $AContainer.AlertContainer.Add($mAlerts)
        }
    }

    $AContainer.AlertContainer.Add($Alerts)
    $AContainer | ConvertTo-Json -Depth 100 | Out-File -FilePath $ResultLocation
}

Function GetAlerts($AlertOwningModuleName)
{
    $ResultLocation = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Controller\SystemMemory\Alerts.json" -Resolve

    $JSONResults = (Get-Content $ResultLocation) -join "`n" | ConvertFrom-Json
    $OutResults = @()

    [ModuleCore.AlertsContainer]$NewJSON = [ModuleCore.AlertsContainer]::new()

    foreach($entry in $JSONResults.AlertContainer)
    {
        if($entry.OwningModuleName -eq $AlertOwningModuleName)
        {
            foreach($subentry in $entry.RegisteredAlerts)
            {
                $OutResults += $subentry
            }
        }

        else
        {
            [ModuleCore.Alerts]$mAlerts = [ModuleCore.Alerts]::new()

            $mAlerts.RegisteredAlerts = $entry.RegisteredAlerts
            $mAlerts.OwningModuleName = $entry.OwningModuleName

            $NewJSON.AlertContainer.Add($mAlerts)
        }
    }


    $NewJSON | ConvertTo-Json -Depth 100 | Out-File -FilePath $ResultLocation -Force
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

Class BasicModule
{
    [string]$ModuleName
    [string]$ModuleFileLocation
    $ModuleRunFunction
    $ModuleAlertFunction = $null
    $ReportedAlerts

    [ModuleResults]$Results = [ModuleResults]::new()

}