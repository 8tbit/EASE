@echo off
PowerShell -Command "Set-ExecutionPolicy Unrestricted"
PowerShell -Command "& {.\IPScannerModule.ps1 -AutoDetectNetworkSettings}"
pause