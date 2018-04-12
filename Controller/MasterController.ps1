using module '..\ScriptModules\ProgrammingAPI\ModuleCore.psm1'

Class JSONModuleImport
{
    [string]$Name
    [string]$FileLocation
}

Write-Progress -Activity "Loading Modules" -Status "Reading RunModules Config Data..." -PercentComplete 0
Write-Host "Reading RunModules Config File at .\RunModules.json`n---------------------------------------------------" -BackgroundColor DarkGray -ForegroundColor Yellow
Write-Host "Reading run modules..." -BackgroundColor DarkGray
Write-Host ("Start Time: " + (Get-Date).DateTime) -BackgroundColor Gray -ForegroundColor DarkGreen
$ModulesToRun = (Get-Content .\RunModules.json) -join "`n" | ConvertFrom-Json
Write-Host "Reading modules complete!" -BackgroundColor DarkGray -ForegroundColor Green
Write-Host ("End Time: " + (Get-Date).DateTime) -BackgroundColor Gray -ForegroundColor DarkCyan
Write-Host "--------------------------------------------------" -BackgroundColor DarkGray -ForegroundColor Yellow

Write-Progress -Activity "Loading Modules" -Status "Reading RunModules Config Data..." -PercentComplete 100

$ReadModules = @()

Write-Progress -Activity "Loading Modules" -Status "Importing Modules..." -PercentComplete 0

Write-Host "`n`nImporting Read Modules to Engine Objects`n----------------------------------------" -ForegroundColor Yellow -BackgroundColor DarkGray
Write-Host "Importing Read Modules..." -BackgroundColor DarkGray
Write-Host ("Start Time: " + (Get-Date).DateTime) -BackgroundColor Gray -ForegroundColor DarkGreen
$Count = 0
foreach($entry in $ModulesToRun.RunTimeModules)
{
    $Count += 1
    Write-Progress -Activity "Loading Modules" -Status "Importing Modules..." -CurrentOperation $entry.Name -PercentComplete (($Count / $ModulesToRun.RunTimeModules.Count) * 100)

    $JSONMod = [JSONModuleImport]::new()
    $JSONMod.Name = $entry.Name
    $JSONMod.FileLocation = $entry.FileLocation

    $ReadModules += $JSONMod
}

Write-Progress -Activity "Loading Modules" -Status "Importing Modules..." -Completed
Write-Host "Importing modules complete!" -BackgroundColor DarkGray -ForegroundColor Green
Write-Host ("End Time: " + (Get-Date).DateTime) -ForegroundColor DarkCyan -BackgroundColor Gray
Write-Host "----------------------------------------`n`n" -BackgroundColor DarkGray -ForegroundColor Yellow

Write-Progress -Activity "Loading Modules" -Status "Converting Modules..."
Write-Host "Loading Modules into Engine`n---------------------------" -ForegroundColor Yellow -BackgroundColor DarkGray
Write-Host ("Start Time: " + (Get-Date).DateTime)
$LoadedModules = @()

$Count = 0
$LoadedModulePaths = @()
$DuplicateModuleCount = 0

foreach($MOD in $ReadModules)
{
    $Count += 1
    Write-Progress -Activity "Loading Modules" -Status "Converting Modules..." -CurrentOperation $MOD.Name -PercentComplete (($Count / $ReadModules.Count) * 100)

    if($LoadedModulePaths.Count -eq 0)
    {
         Write-Host ("Module Name: " + $MOD.Name + "`n`tModule Path: " + $MOD.FileLocation + "`n") -BackgroundColor DarkGreen
         $LoadedModulePaths += $MOD.FileLocation
         $LoadedModules += & $MOD.FileLocation
    }

    else
    {

        $MODCHECK = $false

        foreach($lmod in $LoadedModulePaths)
        {
            if($MOD.FileLocation -eq $lmod)
            {
                Write-Host ("Module " + $MOD.Name + " has already been loaded. Skipping...") -BackgroundColor DarkRed
                $DuplicateModuleCount += 1
                $MODCHECK = $true
                break
            }
        }

        if($MODCHECK)
        {
            $MODCHECK = $false
        }
        else
        {
             Write-Host ("Module Name: " + $MOD.Name + "`n`tModule Path: " + $MOD.FileLocation + "`n") -BackgroundColor DarkGreen
             $LoadedModulePaths += $MOD.FileLocation
             $LoadedModules += & $MOD.FileLocation
        }

    }


}
Write-Host "Loading modules complete!" -ForegroundColor Green
Write-Host ("End Time: " + (Get-Date).DateTime)
Write-Host "---------------------------" -BackgroundColor DarkGray -ForegroundColor Yellow
Write-Host "`n`n"
Write-Host ("Modules Successfully Loaded (" + $LoadedModules.Count + " Modules Successfully Loaded, " + $DuplicateModuleCount + " Modules Failed to Load)" + "`n-------------------------------------------------------------------------------------")
$count = 1
foreach($module in $LoadedModulePaths)
{
    Write-Host ("$Count : " + $module)
    $Count += 1
}

Write-Host "-------------------------------------------------------------------------------------`n"

Write-Progress -Activity "Loading Modules" -Status "Converting Modules..." -Completed




foreach($modl in $LoadedModules)
{
    $global:modlr = $modl

    try
    {
        Write-Host ("Running Mod: " + $global:modlr.ModuleName)
        Invoke-Command $modl.ModuleRunFunction -InputObject 0
    }
    catch [Exception]
    {
        try
        {
            Invoke-Command $modl.ModuleRunFunction
            Write-Host "Second Try Success!" -ForegroundColor Green
        }
        catch
        {
            Write-Host ("Second Chance Exception thrown: " + $global:modlr.ModuleName)
            Write-Host ($_.Exception.GetType().FullName, $_.Exception.Message) -BackgroundColor Red -ForegroundColor Black
            Write-Host "`n"
        }

        Write-Host ("Parent Exception thrown: " + $global:modlr.ModuleName)
        Write-Host ($_.Exception.GetType().FullName, $_.Exception.Message) -BackgroundColor Red -ForegroundColor Black
        Write-Host "`n"
    } #Do nothing if ModuleRunFunction is undefined

    if($modl.ModuleAlertFunction -eq $null)
    {
        Write-Host ("`nNo alert function defined for module: " + $global:modlr.ModuleName) -ForegroundColor Yellow -BackgroundColor DarkGray
    } 
    else
    {
        try
        {
		    Write-Host ("Running Behavior Function of Module " + $global:modlr.ModuleName)
            Invoke-Command $modl.ModuleAlertFunction -InputObject 0
        }
        catch [Exception]
        {
            try
            {
                Invoke-Command $modl.ModuleAlertFunction
                Write-Host "Second Try Success!" -ForegroundColor Green
            }
            catch
            {
                Write-Host ("Second Chance Exception thrown: " + $global:modlr.ModuleName)
                Write-Host ($_.Exception.GetType().FullName, $_.Exception.Message) -BackgroundColor Red -ForegroundColor Black
                Write-Host "`n"
            }
        
            Write-Host ("Parent Exception thrown: " + $global:modlr.ModuleName)
            Write-Host ($_.Exception.GetType().FullName, $_.Exception.Message) -BackgroundColor Red -ForegroundColor Black
            Write-Host "`n"

        } #Do nothing if ModuleAlertFunctin is undefined
    }

}