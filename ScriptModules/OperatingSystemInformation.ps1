Param(
[switch]$TableOut
)

#Functions

$OS = Get-WmiObject -Class Win32_OperatingSystem

$table = New-Object System.Data.DataTable "OSTable"

$OName = New-Object System.Data.DataColumn Name,([string])


$table.Columns.Add($OName)

$row = $table.NewRow()

$row.Name = $OS.Name

$table.Rows.Add($row)



$table | Format-Table
